(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; CSRF protection
;;;
;;; Wraps lack-middleware-csrf. Provides a helper to embed the token in forms.
;;;
;;; Setup: add (:csrf) to lack:builder in make-app.
;;; Pipeline: add 'csrf-token-middleware to inject token into conn.
;;;
;;; Usage in views:
;;;   (:form :method "post" :action "/users"
;;;     (csrf-hidden-field conn)
;;;     ...)
;;; --------------------------------------------------------------------------

(defun csrf-token-middleware (conn next)
  "Extract CSRF token from Lack env and store in conn params."
  (let ((env (conn-env conn)))
    (setf (gethash "_csrf_token" (conn-params conn))
          (getf env :lack.middleware.csrf/token)))
  (funcall next conn))

(defun csrf-token (conn)
  "Get the current CSRF token."
  (conn-param conn "_csrf_token"))

(defun csrf-hidden-field (conn)
  "Render a hidden input with the CSRF token. Use inside forms."
  (spinneret:with-html
    (:input :type "hidden"
            :name "_csrf_token"
            :value (csrf-token conn))))
