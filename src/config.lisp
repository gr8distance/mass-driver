(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Configuration
;;;
;;; 12-factor style: everything comes from environment variables with
;;; sensible defaults for development. No dev.lisp / prod.lisp split.
;;;
;;; Usage:
;;;   (env "PORT" "3000")            ; get with default
;;;   (env-int "PORT" 3000)          ; get as integer
;;;   (env-bool "DEBUG" t)           ; get as boolean
;;;   *config*                       ; access all config
;;; --------------------------------------------------------------------------

(defun env (name &optional default)
  "Get an environment variable, falling back to DEFAULT."
  (or (uiop:getenv name) default))

(defun env-int (name &optional (default 0))
  "Get an environment variable as an integer."
  (let ((val (uiop:getenv name)))
    (if val (parse-integer val) default)))

(defun env-bool (name &optional default)
  "Get an environment variable as a boolean.
\"1\", \"true\", \"yes\" → T. \"0\", \"false\", \"no\" → NIL."
  (let ((val (uiop:getenv name)))
    (if val
        (member val '("1" "true" "yes") :test #'string-equal)
        default)))

(defun load-config ()
  "Build config from environment variables."
  (list :port         (env-int "PORT" 3000)
        :server       (intern (string-upcase (env "SERVER" "woo")) :keyword)
        :database-url (env "DATABASE_URL" "sqlite3:///tmp/mass-driver-dev.db")
        :secret-key   (env "SECRET_KEY_BASE" "dev-secret-change-me-in-prod")
        :static-path  (env "STATIC_PATH" "/static/")
        :log-level    (intern (string-upcase (env "LOG_LEVEL" "info")) :keyword)))

(defvar *config* (load-config)
  "Application configuration. Call (reload-config) after changing env vars.")

(defun reload-config ()
  "Reload configuration from environment variables."
  (setf *config* (load-config)))

(defun config (key)
  "Get a config value by keyword. E.g. (config :port)"
  (getf *config* key))
