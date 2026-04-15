(in-package #:mass-driver/tests)

(deftest test-user-validation-success
  (let ((user (mass-driver.domain.accounts:make-user
               :email "test@example.com"
               :name "Test User")))
    (ok (mass-driver.domain.accounts:validate-user user))))

(deftest test-user-validation-missing-email
  (ok (handler-case
          (progn
            (mass-driver.domain.accounts:validate-user
             (mass-driver.domain.accounts:make-user :email "" :name "Test"))
            nil)
        (mass-driver.domain.accounts:invalid-user () t))))

(deftest test-user-validation-invalid-email
  (ok (handler-case
          (progn
            (mass-driver.domain.accounts:validate-user
             (mass-driver.domain.accounts:make-user :email "bad" :name "Test"))
            nil)
        (mass-driver.domain.accounts:invalid-user () t))))

(deftest test-user-validation-missing-name
  (ok (handler-case
          (progn
            (mass-driver.domain.accounts:validate-user
             (mass-driver.domain.accounts:make-user :email "t@e.com" :name ""))
            nil)
        (mass-driver.domain.accounts:invalid-user () t))))
