(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Flash messages
;;;
;;; Flash messages are stored in the session and cleared after being read.
;;; Works exactly like Phoenix's put_flash / get_flash.
;;;
;;; Usage:
;;;   ;; In handler:
;;;   (flash-put conn :info "User created successfully")
;;;   (redirect conn "/users")
;;;
;;;   ;; In next request's view:
;;;   (flash-get conn :info)   → "User created successfully" (then cleared)
;;; --------------------------------------------------------------------------

(defun flash-put (conn key message)
  "Store a flash message. KEY is typically :info, :error, or :warning."
  (let ((flash (or (session-get conn :_flash)
                   (make-hash-table :test 'eq))))
    (setf (gethash key flash) message)
    (session-set conn :_flash flash))
  conn)

(defun flash-get (conn key)
  "Get and clear a flash message."
  (let ((flash (session-get conn :_flash)))
    (when flash
      (let ((message (gethash key flash)))
        (remhash key flash)
        (when (zerop (hash-table-count flash))
          (session-delete conn :_flash))
        message))))

(defun flash-messages (conn)
  "Get all flash messages as an alist and clear them."
  (let ((flash (session-get conn :_flash)))
    (when flash
      (let ((messages '()))
        (maphash (lambda (k v) (push (cons k v) messages)) flash)
        (session-delete conn :_flash)
        (nreverse messages)))))
