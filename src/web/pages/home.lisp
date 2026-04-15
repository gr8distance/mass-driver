(in-package #:mass-driver)

(defview pages/home (title message)
  (app-layout :title title
    (navbar
      (:a :href "/" "Home")
      (:a :href "/about" "About"))
    (:main :class "max-w-5xl mx-auto px-8 py-12"
      (:h1 :class "text-3xl font-bold mb-8 text-gray-900"
        message)
      (:div :class "grid gap-6 md:grid-cols-2"
        (card :title "Getting Started"
          (:p "Edit " (:code "src/web/pages/home.lisp") " to get started."))
        (card :title "Components"
          (:p "Build reusable UI with " (:code "defcomponent") "."))
        (card :title "Routing"
          (:p "Define routes with " (:code "defrouter") " and " (:code "scope") "."))
        (card :title "Database"
          (:p "Models via " (:code "defmodel") ", migrations via " (:code "migrate") "."))))))
