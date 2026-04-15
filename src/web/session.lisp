(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Session
;;;
;;; Thin wrapper around lack-middleware-session. Provides simple accessors
;;; on the conn object.
;;;
;;; Setup: session-middleware is added to a pipeline. It reads/writes the
;;; Lack session from the Clack env and exposes it via conn.
;;;
;;; Usage in handlers:
;;;   (session-get conn :user-id)          ; read
;;;   (session-set conn :user-id 42)       ; write
;;;   (session-clear conn)                 ; destroy (logout)
;;; --------------------------------------------------------------------------

;;; --- Middleware ---

(defun session-middleware (conn next)
  "Load the Lack session into conn, call next, then sync back."
  (let ((env (conn-env conn)))
    ;; Lack stores session in :lack.session
    (setf (conn-session conn) (getf env :lack.session))
    (let ((result (funcall next conn)))
      result)))

;;; --- Accessors ---

(defun session-get (conn key &optional default)
  "Get a value from the session."
  (let ((session (conn-session conn)))
    (if session
        (gethash key session default)
        default)))

(defun session-set (conn key value)
  "Set a value in the session."
  (let ((session (conn-session conn)))
    (when session
      (setf (gethash key session) value)))
  value)

(defun session-delete (conn key)
  "Remove a key from the session."
  (let ((session (conn-session conn)))
    (when session
      (remhash key session))))

(defun session-clear (conn)
  "Clear all session data (logout)."
  (let ((session (conn-session conn)))
    (when session
      (clrhash session))))
