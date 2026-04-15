(in-package #:mass-driver/tests)

(deftest test-home-page
  (let ((conn (request :get "/")))
    (ok (assert-status conn 200))
    (ok (assert-body-contains conn "Welcome to mass-driver"))
    (ok (assert-body-contains conn "<!DOCTYPE html>"))))

(deftest test-about-page
  (let ((conn (request :get "/about")))
    (ok (assert-status conn 200))
    (ok (assert-body-contains conn "About"))))

(deftest test-not-found
  (let ((conn (request :get "/nonexistent")))
    (ok (assert-status conn 404))))
