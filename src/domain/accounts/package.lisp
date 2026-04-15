(defpackage #:mass-driver.domain.accounts
  (:use #:cl)
  (:export
   ;; Entity
   #:user
   #:make-user
   #:user-id
   #:user-email
   #:user-name
   ;; Validation
   #:validate-user
   ;; Conditions
   #:invalid-user
   #:invalid-user-reasons))
