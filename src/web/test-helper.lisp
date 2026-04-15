(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Test helpers
;;;
;;; Provides ConnTest-like helpers for testing handlers without HTTP.
;;;
;;; Usage with Rove:
;;;   (deftest test-home-page
;;;     (let ((conn (request :get "/")))
;;;       (ok (= 200 (conn-status conn)))
;;;       (ok (search "Welcome" (conn-response-body conn)))))
;;; --------------------------------------------------------------------------

(defun request (method path &key params headers body)
  "Simulate an HTTP request and return the conn after dispatch.
METHOD is a keyword (:get, :post, etc.).
PARAMS is an alist of query/body params."
  (let ((env (list :request-method method
                   :path-info path
                   :query-string (when (and params (eq method :get))
                                   (build-query-string params))
                   :headers (or headers '())
                   :content-type (when body "application/x-www-form-urlencoded")
                   :raw-body (when body
                               (make-string-input-stream
                                (if (stringp body) body
                                    (build-query-string body)))))))
    ;; Run through dispatch
    (let* ((response (dispatch *router* env))
           (conn (make-conn :env env)))
      (setf (conn-status conn) (first response)
            (conn-response-headers conn) (second response)
            (conn-response-body conn) (first (third response)))
      conn)))

(defun build-query-string (params)
  "Build a query string from an alist. ((\"key\" . \"val\")) → \"key=val\"."
  (format nil "~{~a~^&~}"
          (mapcar (lambda (pair)
                    (format nil "~a=~a" (car pair) (cdr pair)))
                  params)))

(defun assert-status (conn expected)
  "Check response status code."
  (= (conn-status conn) expected))

(defun assert-body-contains (conn text)
  "Check if response body contains TEXT."
  (search text (conn-response-body conn)))

(defun assert-redirect (conn location)
  "Check if response is a redirect to LOCATION."
  (and (member (conn-status conn) '(301 302 303 307 308))
       (string= location
                (getf (conn-response-headers conn) :location))))
