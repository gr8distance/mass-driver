(in-package #:mass-driver/tests)

;;; Test the framework's routing and dispatch with a minimal router

(mass-driver:defhandler test/index (conn)
  (mass-driver:render conn #'test/index-view))

(defun test/index-view (&key)
  "OK")

(mass-driver:defrouter *test-routes*
  (mass-driver:scope "/" ()
    (:get "/" 'test/index)))

(setf mass-driver:*test-router* *test-routes*)

(deftest test-dispatch-200
  (let ((conn (mass-driver:request :get "/")))
    (ok (mass-driver:assert-status conn 200))
    (ok (mass-driver:assert-body-contains conn "OK"))))

(deftest test-dispatch-404
  (let ((conn (mass-driver:request :get "/nonexistent")))
    (ok (mass-driver:assert-status conn 404))))
