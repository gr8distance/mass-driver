(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; i18n — Internationalization
;;;
;;; Simple key-based translation system.
;;;
;;; Usage:
;;;   ;; Define translations
;;;   (deftranslation :en
;;;     (:greeting "Hello")
;;;     (:farewell "Goodbye")
;;;     (:user.name "Name")
;;;     (:user.email "Email"))
;;;
;;;   (deftranslation :ja
;;;     (:greeting "こんにちは")
;;;     (:farewell "さようなら")
;;;     (:user.name "名前")
;;;     (:user.email "メールアドレス"))
;;;
;;;   ;; Translate
;;;   (t! :greeting)                    → "Hello" (default locale)
;;;   (t! :greeting :locale :ja)        → "こんにちは"
;;;   (t! :greeting :name "World")      → "Hello" (interpolation TBD)
;;;
;;;   ;; In handler — detect from Accept-Language
;;;   (with-locale (conn)
;;;     (t! :greeting))
;;; --------------------------------------------------------------------------

(defvar *translations* (make-hash-table :test 'eq)
  "Hash of locale → hash of key → string.")

(defvar *default-locale* :en)
(defvar *current-locale* :en)

;;; --- Define translations ---

(defmacro deftranslation (locale &body pairs)
  "Register translations for a locale."
  `(let ((table (or (gethash ,locale *translations*)
                    (setf (gethash ,locale *translations*)
                          (make-hash-table :test 'eq)))))
     ,@(loop for (key value) in pairs
             collect `(setf (gethash ,key table) ,value))
     ,locale))

;;; --- Lookup ---

(defun t! (key &key (locale *current-locale*) default)
  "Translate KEY in the given LOCALE. Falls back to default locale, then key name."
  (or (get-translation key locale)
      (unless (eq locale *default-locale*)
        (get-translation key *default-locale*))
      default
      (string-downcase (symbol-name key))))

(defun get-translation (key locale)
  (let ((table (gethash locale *translations*)))
    (when table (gethash key table))))

;;; --- Locale detection ---

(defun detect-locale (conn)
  "Detect locale from Accept-Language header.
Returns a keyword like :EN, :JA, :FR."
  (let ((header (getf (conn-env conn) :http-accept-language)))
    (if (and header (> (length header) 1))
        (let* ((primary (subseq header 0 (min 2 (length header))))
               (locale (intern (string-upcase primary) :keyword)))
          (if (gethash locale *translations*)
              locale
              *default-locale*))
        *default-locale*)))

(defmacro with-locale ((conn) &body body)
  "Execute BODY with *current-locale* set from the request."
  `(let ((*current-locale* (detect-locale ,conn)))
     ,@body))

;;; --- Middleware ---

(defun i18n-middleware (conn next)
  "Set locale from Accept-Language header."
  (let ((*current-locale* (detect-locale conn)))
    (funcall next conn)))
