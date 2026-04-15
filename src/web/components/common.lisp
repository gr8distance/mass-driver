(in-package #:mass-driver)

(defcomponent card (title &key (class ""))
  `(:div :class ,(format nil "card ~a" class)
     (:h2 ,title)
     (:div :class "card-body"
       ,@children)))

(defcomponent navbar (&key (brand "mass-driver"))
  `(:nav :class "navbar"
     (:div :class "max-w-5xl mx-auto w-full flex items-center"
       (:a :href "/" :class "navbar-brand" ,brand)
       (:div :class "navbar-links"
         ,@children))))
