(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Database connection
;;;
;;; Reads DATABASE_URL from environment. Supports SQLite3, PostgreSQL, MySQL.
;;;
;;; Format:
;;;   sqlite3:///path/to/db.sqlite3
;;;   postgres://user:pass@host:5432/dbname
;;;   mysql://user:pass@host:3306/dbname
;;; --------------------------------------------------------------------------

(defun parse-database-url (url)
  "Parse a DATABASE_URL into (driver-keyword &rest connect-args).
Returns values suitable for mito:connect-toplevel."
  (let ((scheme-end (position #\: url)))
    (when scheme-end
      (let ((scheme (subseq url 0 scheme-end)))
        (cond
          ((string= scheme "sqlite3")
           (let ((path (subseq url (+ scheme-end 3)))) ; skip ://
             (list :sqlite3 :database-name path)))

          ((or (string= scheme "postgres")
               (string= scheme "postgresql"))
           (parse-tcp-database-url :postgres url scheme-end))

          ((string= scheme "mysql")
           (parse-tcp-database-url :mysql url scheme-end))

          (t (error "Unsupported database scheme: ~a" scheme)))))))

(defun parse-tcp-database-url (driver url scheme-end)
  "Parse postgres:// or mysql:// URL into connect args."
  (let* ((rest (subseq url (+ scheme-end 3))) ; skip ://
         (at-pos (position #\@ rest))
         (user-pass (when at-pos (subseq rest 0 at-pos)))
         (host-rest (if at-pos (subseq rest (1+ at-pos)) rest))
         (slash-pos (position #\/ host-rest))
         (host-port (subseq host-rest 0 slash-pos))
         (dbname (when slash-pos (subseq host-rest (1+ slash-pos))))
         (colon-pos-hp (position #\: host-port))
         (host (if colon-pos-hp (subseq host-port 0 colon-pos-hp) host-port))
         (port (when colon-pos-hp
                 (parse-integer (subseq host-port (1+ colon-pos-hp)))))
         (colon-pos-up (when user-pass (position #\: user-pass)))
         (user (when user-pass
                 (if colon-pos-up (subseq user-pass 0 colon-pos-up) user-pass)))
         (pass (when colon-pos-up
                 (subseq user-pass (1+ colon-pos-up)))))
    (append (list driver :database-name dbname :host host)
            (when port (list :port port))
            (when user (list :username user))
            (when pass (list :password pass)))))

(defun connect-db (&optional url)
  "Connect to the database. Uses DATABASE_URL env var if URL is not provided."
  (let* ((db-url (or url
                     (uiop:getenv "DATABASE_URL")
                     "sqlite3:///tmp/mass-driver-dev.db"))
         (args (parse-database-url db-url)))
    (apply #'mito:connect-toplevel args)
    (format t "Connected to ~a~%" db-url)))

(defun disconnect-db ()
  "Disconnect from the database."
  (mito:disconnect-toplevel))
