(in-package #:mass-driver.app.accounts)

;;; --------------------------------------------------------------------------
;;; Accounts use cases
;;;
;;; Orchestrates domain logic and repository. Depends on domain and infra,
;;; but the web layer depends on this — never the reverse.
;;; --------------------------------------------------------------------------

(defun create-user (&key email name)
  "Create a new user. Validates, then persists.
Signals INVALID-USER if validation fails."
  (let ((user (mass-driver.domain.accounts:make-user
               :email email :name name)))
    (mass-driver.domain.accounts:validate-user user)
    (mass-driver.infra.user-repo:save-user user)))

(defun get-user (id)
  "Find a user by ID."
  (mass-driver.infra.user-repo:find-by-id id))

(defun get-user-by-email (email)
  "Find a user by email."
  (mass-driver.infra.user-repo:find-by-email email))

(defun list-users ()
  "List all users."
  (mass-driver.infra.user-repo:list-all))

(defun find-or-create-user (&key email name)
  "Find existing user by email, or create a new one.
Useful for OAuth callbacks."
  (or (mass-driver.infra.user-repo:find-by-email email)
      (create-user :email email :name name)))
