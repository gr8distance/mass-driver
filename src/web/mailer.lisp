(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Mailer
;;;
;;; Simple email sending via SMTP. Uses cl-smtp.
;;;
;;; Configuration (env vars):
;;;   SMTP_HOST=smtp.gmail.com
;;;   SMTP_PORT=587
;;;   SMTP_USER=you@gmail.com
;;;   SMTP_PASSWORD=app-password
;;;   MAIL_FROM=noreply@example.com
;;;
;;; Usage:
;;;   (defmail welcome-mail (user)
;;;     :to (user-email user)
;;;     :subject "Welcome!"
;;;     :body (format nil "Hi ~a, welcome." (user-name user)))
;;;
;;;   (send-mail (welcome-mail some-user))
;;; --------------------------------------------------------------------------

(defstruct mail
  to
  from
  subject
  body
  (html-p nil))

;;; --- Configuration ---

(defun smtp-config ()
  (list :host     (env "SMTP_HOST" "localhost")
        :port     (env-int "SMTP_PORT" 587)
        :user     (env "SMTP_USER")
        :password (env "SMTP_PASSWORD")
        :from     (env "MAIL_FROM" "noreply@example.com")))

;;; --- Define mail templates ---

(defmacro defmail (name args &body options)
  "Define a mail builder function.

Usage:
  (defmail welcome-mail (user)
    :to (user-email user)
    :subject \"Welcome!\"
    :body (format nil \"Hi ~a\" (user-name user)))

  (send-mail (welcome-mail user-obj))"
  (let ((opts (loop for (k v) on options by #'cddr
                    collect (cons k v))))
    `(defun ,name ,args
       (make-mail
        :to ,(cdr (assoc :to opts))
        :from (or ,(cdr (assoc :from opts))
                  (getf (smtp-config) :from))
        :subject ,(cdr (assoc :subject opts))
        :body ,(cdr (assoc :body opts))
        :html-p ,(cdr (assoc :html opts))))))

;;; --- Send ---

(defun send-mail (mail)
  "Send a mail struct via SMTP."
  (let ((cfg (smtp-config)))
    (handler-case
        (progn
          (cl-smtp:send-email
           (getf cfg :host)
           (mail-from mail)
           (mail-to mail)
           (mail-body mail)
           :subject (mail-subject mail)
           :port (getf cfg :port)
           :authentication (when (getf cfg :user)
                             (list :login
                                   (getf cfg :user)
                                   (getf cfg :password)))
           :ssl :starttls)
          (log-info "Mail sent to ~a: ~a" (mail-to mail) (mail-subject mail))
          t)
      (error (e)
        (log-error "Mail failed to ~a: ~a" (mail-to mail) e)
        nil))))
