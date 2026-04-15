(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Logger
;;;
;;; Configurable logging with pluggable formatters.
;;;
;;; Usage:
;;;   (log-info "User ~a logged in" user-id)
;;;   (log-error "Failed: ~a" condition)
;;;
;;; Configuration:
;;;   LOG_LEVEL=info          (debug, info, warn, error)
;;;   LOG_FORMAT=text         (text, json)
;;; --------------------------------------------------------------------------

(defvar *log-level* :info)
(defvar *log-formatter* :text
  "Log format: :text or :json")
(defvar *log-stream* *standard-output*)

(defparameter *log-levels*
  '(:debug 0 :info 1 :warn 2 :error 3))

(defun log-level-value (level)
  (getf *log-levels* level 1))

(defun should-log-p (level)
  (>= (log-level-value level) (log-level-value *log-level*)))

;;; --- Public API ---

(defun log-debug (fmt &rest args)
  (log-message :debug fmt args))

(defun log-info (fmt &rest args)
  (log-message :info fmt args))

(defun log-warn (fmt &rest args)
  (log-message :warn fmt args))

(defun log-error (fmt &rest args)
  (log-message :error fmt args))

;;; --- Core ---

(defun log-message (level fmt args)
  (when (should-log-p level)
    (let ((message (apply #'format nil fmt args)))
      (ecase *log-formatter*
        (:text (format-text-log level message))
        (:json (format-json-log level message)))
      (force-output *log-stream*))))

(defun format-text-log (level message)
  (multiple-value-bind (sec min hour day month year)
      (get-decoded-time)
    (format *log-stream* "~4,'0d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d [~a] ~a~%"
            year month day hour min sec
            (string-upcase (symbol-name level))
            message)))

(defun format-json-log (level message)
  (multiple-value-bind (sec min hour day month year)
      (get-decoded-time)
    (format *log-stream*
            "{\"time\":\"~4,'0d-~2,'0d-~2,'0dT~2,'0d:~2,'0d:~2,'0d\",\"level\":\"~a\",\"message\":~s}~%"
            year month day hour min sec
            (string-downcase (symbol-name level))
            message)))

;;; --- Request logger middleware ---

(defun logger-middleware (conn next)
  "Log request with method, path, status, and duration."
  (let ((start (get-internal-real-time)))
    (let ((result (funcall next conn)))
      (let* ((duration-ms (/ (* 1000.0
                                (- (get-internal-real-time) start))
                             internal-time-units-per-second))
             (status (conn-status result)))
        (log-info "~a ~a ~a ~,1fms"
                  (conn-method conn)
                  (conn-path conn)
                  status
                  duration-ms))
      result)))

;;; --- Init ---

(defun setup-logger ()
  "Configure logger from environment variables."
  (let ((level (env "LOG_LEVEL" "info"))
        (fmt (env "LOG_FORMAT" "text")))
    (setf *log-level* (intern (string-upcase level) :keyword)
          *log-formatter* (intern (string-upcase fmt) :keyword))))
