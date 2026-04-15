(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Connection object
;;;
;;; Wraps the Clack env and carries request params + response state through
;;; the middleware chain, similar to Phoenix's Plug.Conn.
;;; --------------------------------------------------------------------------

(defstruct conn
  (env nil)
  (params (make-hash-table :test 'equal))
  (session nil)
  (status 200)
  (response-headers '(:content-type "text/html; charset=utf-8"))
  (response-body nil))

;;; --- Request accessors ---

(defun conn-method (conn)
  (getf (conn-env conn) :request-method))

(defun conn-path (conn)
  (getf (conn-env conn) :path-info))

(defun conn-query-string (conn)
  (getf (conn-env conn) :query-string))

(defun conn-header (conn name)
  (getf (getf (conn-env conn) :headers) name))

(defun conn-param (conn key)
  "Get a param by string key. Path params, query params, and body params
are all merged into the same map."
  (gethash key (conn-params conn)))

;;; --- Response helpers ---

(defun render (conn view-fn &rest args)
  "Render a view (defview function) with the given keyword args."
  (setf (conn-response-body conn) (apply view-fn args))
  conn)

(defun respond (conn status body &optional headers)
  "Set status and body directly. For JSON, redirects, etc."
  (setf (conn-status conn) status
        (conn-response-body conn) body)
  (when headers
    (setf (conn-response-headers conn) headers))
  conn)

(defun redirect (conn location &key (status 302))
  (setf (conn-status conn) status
        (conn-response-headers conn) (list :location location)
        (conn-response-body conn) "")
  conn)

(defun conn->response (conn)
  "Convert conn to a Clack response (status headers body-list)."
  (list (conn-status conn)
        (conn-response-headers conn)
        (list (or (conn-response-body conn) ""))))
