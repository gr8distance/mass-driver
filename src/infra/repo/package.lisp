(defpackage #:mass-driver.infra.user-repo
  (:use #:cl)
  (:export
   #:find-by-id
   #:find-by-email
   #:list-all
   #:save-user
   #:delete-user))
