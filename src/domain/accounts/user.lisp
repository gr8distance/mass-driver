(in-package #:mass-driver.domain.accounts)

;;; --------------------------------------------------------------------------
;;; User entity & value objects
;;;
;;; Pure domain logic. No DB, no web, no side effects.
;;; --------------------------------------------------------------------------

(defstruct user
  id
  email
  name)

;;; --- Domain errors ---

(define-condition invalid-user (error)
  ((reasons :initarg :reasons :reader invalid-user-reasons))
  (:report (lambda (c stream)
             (format stream "Invalid user: ~{~a~^, ~}"
                     (mapcar #'reason-message (invalid-user-reasons c))))))

(defun reason-message (reason)
  (ecase reason
    (:email-required "email is required")
    (:email-format "email format is invalid")
    (:name-required "name is required")))

;;; --- Validation ---

(defun validate-user (user)
  "Validate a user entity. Signals INVALID-USER on failure."
  (let ((errors '()))
    (when (or (null (user-email user))
              (zerop (length (user-email user))))
      (push :email-required errors))
    (when (and (user-email user)
              (not (position #\@ (user-email user))))
      (push :email-format errors))
    (when (or (null (user-name user))
              (zerop (length (user-name user))))
      (push :name-required errors))
    (when errors
      (error 'invalid-user :reasons (nreverse errors)))
    user))
