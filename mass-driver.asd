(defsystem "mass-driver"
  :version "0.1.0"
  :description "A micro web framework for Common Lisp"
  :license "MIT"
  :depends-on ("clack" "lack" "woo" "hunchentoot" "spinneret" "lass"
               "mito" "sxql" "yason" "cl-smtp")
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "config" :depends-on ("package"))
                 (:file "i18n" :depends-on ("package"))
                 ;; Domain layer
                 (:module "domain"
                  :components
                  ((:module "accounts"
                    :components
                    ((:file "package")
                     (:file "user" :depends-on ("package"))))))
                 ;; DB core
                 (:module "db"
                  :depends-on ("package")
                  :components
                  ((:file "connection")
                   (:file "model" :depends-on ("connection"))
                   (:file "migration" :depends-on ("model"))))
                 ;; Infra layer
                 (:module "infra"
                  :depends-on ("domain" "db")
                  :components
                  ((:module "repo"
                    :components
                    ((:file "package")
                     (:file "user-repo" :depends-on ("package"))))))
                 ;; App layer
                 (:module "app"
                  :depends-on ("domain" "infra")
                  :components
                  ((:file "package")
                   (:file "accounts" :depends-on ("package"))))
                 ;; Web layer
                 (:module "web"
                  :depends-on ("package" "config")
                  :components
                  ((:file "conn")
                   (:file "logger" :depends-on ("conn"))
                   (:file "error-page" :depends-on ("conn"))
                   (:file "router" :depends-on ("conn" "error-page"))
                   (:file "handler" :depends-on ("conn"))
                   (:file "body-parser" :depends-on ("conn"))
                   (:file "session" :depends-on ("conn"))
                   (:file "json" :depends-on ("conn"))
                   (:file "flash" :depends-on ("conn" "session"))
                   (:file "csrf" :depends-on ("conn"))
                   (:file "mailer" :depends-on ("conn"))
                   (:file "test-helper" :depends-on ("conn" "router"))
                   (:file "view")
                   (:file "styles")
                   (:module "components"
                    :depends-on ("view")
                    :components ((:file "common")))
                   (:module "layouts"
                    :depends-on ("view")
                    :components ((:file "app")))
                   (:module "pages"
                    :depends-on ("view" "components" "layouts")
                    :components ((:file "home"))))))))
  :in-order-to ((test-op (test-op "mass-driver/tests"))))

(defsystem "mass-driver/tests"
  :depends-on ("mass-driver" "rove")
  :components ((:module "tests"
                :components
                ((:file "package")
                 (:file "domain-test" :depends-on ("package"))
                 (:file "handler-test" :depends-on ("package")))))
  :perform (test-op (o c) (symbol-call :rove :run c)))
