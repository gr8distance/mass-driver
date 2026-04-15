(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Router
;;;
;;; Phoenix-inspired routing DSL built on Clack.
;;;
;;; Usage:
;;;   (defrouter app-router
;;;     (pipeline :browser
;;;       #'session-middleware)
;;;
;;;     (scope "/" (:browser)
;;;       (:get  "/"      #'page/index)
;;;       (:get  "/about" #'page/about))
;;;
;;;     (scope "/api" (:api)
;;;       (scope "/v1" ()
;;;         (:get    "/users"     #'api/list-users)
;;;         (:post   "/users"     #'api/create-user)
;;;         (:get    "/users/:id" #'api/show-user))))
;;; --------------------------------------------------------------------------

;;; --- Route structure ---

(defstruct route
  method           ; keyword :get :post :put :delete :patch
  path             ; original path string (for debugging)
  pattern          ; parsed segments ("users" :id "posts")
  handler          ; function (conn) -> conn
  middleware-fns)  ; list of middleware functions

;;; --- Path parsing & matching ---

(defun parse-path (path)
  "Parse \"/users/:id/posts\" into (\"users\" :ID \"posts\")."
  (mapcar (lambda (seg)
            (if (and (> (length seg) 0) (char= (char seg 0) #\:))
                (intern (string-upcase (subseq seg 1)) :keyword)
                seg))
          (remove "" (uiop:split-string path :separator "/")
                  :test #'string=)))

(defun match-path (pattern path-segments)
  "Match pattern against path segments.
Returns params alist on match, T for match without params, NIL on mismatch."
  (when (= (length pattern) (length path-segments))
    (loop for pat in pattern
          for seg in path-segments
          if (keywordp pat)
            collect (cons pat seg) into params
          else if (string= pat seg)
            do (progn)
          else
            return nil
          finally (return (or params t)))))

;;; --- Middleware chain ---

(defun run-middleware (middleware handler conn)
  "Execute middleware chain, calling handler at the end."
  (if (null middleware)
      (funcall handler conn)
      (funcall (car middleware)
               conn
               (lambda (conn)
                 (run-middleware (cdr middleware) handler conn)))))

;;; --- Route builder (runtime state during defrouter expansion) ---

(defvar *building-routes* nil)
(defvar *building-pipelines* nil)
(defvar *current-prefix* "")
(defvar *current-middleware* nil)

(defun %register-route (method path handler)
  (let ((full-path (concatenate 'string *current-prefix* path)))
    (push (make-route :method method
                      :path full-path
                      :pattern (parse-path full-path)
                      :handler handler
                      :middleware-fns (copy-list *current-middleware*))
          *building-routes*)))

(defun %resolve-pipelines (names)
  (loop for name in names
        append (cdr (assoc name *building-pipelines*))))

;;; --- DSL macros ---

(defmacro pipeline (name &body middleware)
  "Define a named middleware pipeline."
  `(push (cons ,name (list ,@middleware)) *building-pipelines*))

(defmacro scope (prefix pipe-through &body body)
  "Group routes under a path prefix with optional middleware pipelines.
PIPE-THROUGH is a list of pipeline names, e.g. (:browser) or ()."
  `(let ((*current-prefix* (concatenate 'string *current-prefix* ,prefix))
         (*current-middleware* (append *current-middleware*
                                      (%resolve-pipelines ',pipe-through))))
     ,@(loop for form in body
             if (and (listp form) (keywordp (car form))
                     (member (car form) '(:get :post :put :delete :patch)))
               collect `(%register-route ,(car form) ,(second form) ,(third form))
             else
               collect form)))

(defmacro defrouter (name &body body)
  "Define a router with pipelines and scoped routes."
  `(progn
     (let ((*building-routes* nil)
           (*building-pipelines* nil)
           (*current-prefix* "")
           (*current-middleware* nil))
       ,@body
       (defparameter ,name (nreverse *building-routes*)))))

;;; --- Dispatch ---

(defun find-route (routes method path-segments)
  "Find the first matching route. Returns (route . params) or NIL."
  (loop for route in routes
        when (eq method (route-method route))
          do (let ((match (match-path (route-pattern route) path-segments)))
               (when match
                 (return (cons route (if (eq match t) nil match)))))))

(defun dispatch (routes env)
  "Dispatch a Clack env to matching route. Returns a Clack response."
  (let* ((method (getf env :request-method))
         (path (getf env :path-info))
         (path-segments (parse-path path))
         (match (find-route routes method path-segments)))
    (if match
        (destructuring-bind (route . params) match
          (let ((conn (make-conn :env env)))
            ;; Set path params
            (when (listp params)
              (loop for (k . v) in params
                    do (setf (gethash (string-downcase (symbol-name k))
                                      (conn-params conn))
                             v)))
            ;; Run middleware → handler
            (conn->response
             (run-middleware (route-middleware-fns route)
                            (route-handler route)
                            conn))))
        (error-response 404))))
