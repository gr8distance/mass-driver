(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Handler (Controller equivalent)
;;;
;;; defhandler is a thin wrapper around defun. It exists to mark intent
;;; and could be extended later (e.g., automatic error handling, logging).
;;; --------------------------------------------------------------------------

(defmacro defhandler (name (conn-var) &body body)
  "Define a request handler (controller action).

Usage:
  (defhandler page/index (conn)
    (render conn 'pages/home
            :title \"mass-driver\"
            :message \"Welcome\"))"
  `(defun ,name (,conn-var)
     ,@body))
