(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Migration system
;;;
;;; Two modes:
;;;   1. Auto-migrate: (auto-migrate) runs mito:migrate-table on all
;;;      registered models. Good for development.
;;;   2. Explicit migrations: defmigration for versioned, reversible changes.
;;;      Good for production.
;;;
;;; Usage:
;;;   ;; Development - just sync models to DB
;;;   (auto-migrate)
;;;
;;;   ;; Production - explicit migrations
;;;   (defmigration "20260414_create_users"
;;;     :up   (lambda () (auto-migrate))
;;;     :down (lambda () (execute-sql "DROP TABLE IF EXISTS \"user\"")))
;;;
;;;   (migrate)     ; run all pending
;;;   (rollback)    ; revert last
;;; --------------------------------------------------------------------------

(defstruct migration
  version    ; string timestamp "20260414120000_create_users"
  up         ; function ()
  down)      ; function ()

(defvar *migrations* '()
  "List of registered migrations, sorted by version.")

;;; --- Schema migrations table ---

(defun ensure-migration-table ()
  "Create the schema_migrations table if it doesn't exist."
  (mito:execute-sql
   "CREATE TABLE IF NOT EXISTS schema_migrations (
      version VARCHAR(255) PRIMARY KEY,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )"))

(defun applied-versions ()
  "Return list of already-applied migration versions."
  (mapcar (lambda (row) (getf row :|version|))
          (mito:retrieve-by-sql
           "SELECT version FROM schema_migrations ORDER BY version")))

(defun mark-applied (version)
  (mito:execute-sql
   "INSERT INTO schema_migrations (version) VALUES (?)" (list version)))

(defun unmark-applied (version)
  (mito:execute-sql
   "DELETE FROM schema_migrations WHERE version = ?" (list version)))

;;; --- Auto-migrate (development) ---

(defun auto-migrate ()
  "Sync all registered model definitions to the database.
Uses mito:migrate-table which auto-detects schema changes."
  (dolist (model *registered-models*)
    (mito:ensure-table-exists model)
    (mito:migrate-table model)
    (format t "Migrated: ~a~%" model)))

;;; --- Explicit migrations ---

(defmacro defmigration (version &key up down)
  "Register a named migration with up/down functions.

VERSION should be a timestamp-prefixed string like \"20260414_create_users\"."
  `(let ((m (make-migration :version ,version :up ,up :down ,down)))
     ;; Insert sorted by version
     (setf *migrations*
           (sort (cons m (remove ,version *migrations*
                                 :key #'migration-version :test #'string=))
                 #'string< :key #'migration-version))
     m))

(defun pending-migrations ()
  "Return migrations that haven't been applied yet."
  (let ((applied (applied-versions)))
    (remove-if (lambda (m) (member (migration-version m) applied :test #'string=))
               *migrations*)))

(defun migrate ()
  "Run all pending migrations."
  (ensure-migration-table)
  (let ((pending (pending-migrations)))
    (if (null pending)
        (format t "No pending migrations.~%")
        (dolist (m pending)
          (format t "Running: ~a~%" (migration-version m))
          (funcall (migration-up m))
          (mark-applied (migration-version m))
          (format t "Applied: ~a~%" (migration-version m))))))

(defun rollback (&key (step 1))
  "Rollback the last STEP migration(s)."
  (ensure-migration-table)
  (let* ((applied (reverse (applied-versions)))
         (to-rollback (subseq applied 0 (min step (length applied)))))
    (if (null to-rollback)
        (format t "Nothing to rollback.~%")
        (dolist (version to-rollback)
          (let ((m (find version *migrations*
                        :key #'migration-version :test #'string=)))
            (if (and m (migration-down m))
                (progn
                  (format t "Rolling back: ~a~%" version)
                  (funcall (migration-down m))
                  (unmark-applied version)
                  (format t "Reverted: ~a~%" version))
                (format t "No down migration for: ~a~%" version)))))))
