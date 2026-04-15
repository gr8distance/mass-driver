(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Model definition
;;;
;;; defmodel wraps mito:deftable and registers the model for migration.
;;;
;;; Usage:
;;;   (defmodel user ()
;;;     ((name  :col-type (:varchar 64))
;;;      (email :col-type (:varchar 128))))
;;;
;;; Mito auto-adds: id, created_at, updated_at
;;; --------------------------------------------------------------------------

(defvar *registered-models* '()
  "List of all model classes registered via defmodel.")

(defmacro defmodel (name superclasses slots &rest options)
  "Define a Mito table class and register it for migration.

SUPERCLASSES defaults to empty (inherits mito:dao-table-class via metaclass).
SLOTS follow mito:deftable syntax (:col-type, :col-name, etc.)."
  `(progn
     (mito:deftable ,name ,superclasses
       ,slots
       ,@(unless (assoc :table-name options)
           `((:table-name ,(string-downcase (symbol-name name)))))
       ,@options)
     (pushnew ',name *registered-models*)
     (find-class ',name)))
