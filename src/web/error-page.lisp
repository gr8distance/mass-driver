(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Error pages
;;; --------------------------------------------------------------------------

(defvar *error-handlers* (make-hash-table)
  "Map of status code → handler function (conn) → conn.")

(defmacro deferror (status-code &body body)
  "Register a custom error page for a status code.

Usage:
  (deferror 404
    (render conn 'pages/errors/not-found))"
  `(setf (gethash ,status-code *error-handlers*)
         (lambda (conn) ,@body)))

(defun error-response (status &optional message)
  "Generate an error response. Uses custom handler if registered."
  (let ((handler (gethash status *error-handlers*)))
    (if handler
        (let ((conn (make-conn)))
          (setf (conn-status conn) status)
          (conn->response (funcall handler conn)))
        (list status
              '(:content-type "text/html; charset=utf-8")
              (list (default-error-page status message))))))

(defun default-error-page (status message)
  "Fallback error page when no custom handler is registered."
  (let ((title (or message (status-text status))))
    (spinneret:with-html-string
      (:doctype)
      (:html :lang "en"
        (:head
          (:meta :charset "utf-8")
          (:meta :name "viewport" :content "width=device-width, initial-scale=1")
          (:title (format nil "~a — ~a" status title))
          (:style "body{font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#fafafa;color:#1a1a2e}
.error{text-align:center}
.code{font-size:4rem;font-weight:700;color:#e2e8f0;margin:0}
.message{font-size:1.25rem;color:#4a5568;margin:0.5rem 0}"))
        (:body
          (:div :class "error"
            (:p :class "code" (format nil "~a" status))
            (:p :class "message" title)))))))

(defun status-text (status)
  (case status
    (400 "Bad Request")
    (401 "Unauthorized")
    (403 "Forbidden")
    (404 "Not Found")
    (405 "Method Not Allowed")
    (422 "Unprocessable Entity")
    (500 "Internal Server Error")
    (502 "Bad Gateway")
    (503 "Service Unavailable")
    (t   "Error")))
