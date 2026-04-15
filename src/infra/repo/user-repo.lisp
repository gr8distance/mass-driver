(in-package #:mass-driver.infra.user-repo)

;;; --------------------------------------------------------------------------
;;; User repository — Mito implementation
;;;
;;; Converts between domain entities and DB records.
;;; --------------------------------------------------------------------------

;;; --- DB record (Mito table) ---

(mass-driver:defmodel user-record ()
  ((name  :col-type (:varchar 64))
   (email :col-type (:varchar 128))))

;;; --- Conversion ---

(defun to-entity (record)
  "Convert a Mito record to a domain entity."
  (mass-driver.domain.accounts:make-user
   :id (mito:object-id record)
   :email (user-record-email record)
   :name (user-record-name record)))

(defun from-entity (entity)
  "Convert a domain entity to a Mito record."
  (let ((record (make-instance 'user-record)))
    (setf (user-record-name record) (mass-driver.domain.accounts:user-name entity)
          (user-record-email record) (mass-driver.domain.accounts:user-email entity))
    (when (mass-driver.domain.accounts:user-id entity)
      (setf (mito:object-id record) (mass-driver.domain.accounts:user-id entity)))
    record))

;;; --- Repository operations ---

(defun find-by-id (id)
  "Find a user by ID. Returns domain entity or NIL."
  (let ((record (mito:find-dao 'user-record :id id)))
    (when record (to-entity record))))

(defun find-by-email (email)
  "Find a user by email. Returns domain entity or NIL."
  (let ((records (mito:select-dao 'user-record
                   (sxql:where (:= :email email)))))
    (when records (to-entity (first records)))))

(defun list-all ()
  "Return all users as domain entities."
  (mapcar #'to-entity (mito:select-dao 'user-record)))

(defun save-user (entity)
  "Persist a domain entity. Returns the entity with ID set."
  (let ((record (from-entity entity)))
    (if (mass-driver.domain.accounts:user-id entity)
        (mito:save-dao record)
        (mito:insert-dao record))
    (to-entity record)))

(defun delete-user (id)
  "Delete a user by ID."
  (let ((record (mito:find-dao 'user-record :id id)))
    (when record (mito:delete-dao record))))
