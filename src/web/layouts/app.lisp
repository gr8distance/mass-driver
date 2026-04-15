(in-package #:mass-driver)

(deflayout app-layout (&key (title "mass-driver"))
  `(progn
     (:doctype)
     (:html :lang "en"
       (:head
         (:meta :charset "utf-8")
         (:meta :name "viewport"
                :content "width=device-width, initial-scale=1")
         (:title ,title)
         ;; Tailwind CSS (CDN)
         (:script :src "https://cdn.tailwindcss.com")
         ;; App styles (Lass-generated)
         (:link :rel "stylesheet" :href "/static/css/app.css"))
       (:body :class "min-h-screen bg-gray-50"
         ,@children
         (:script :src "/static/js/app.js")))))
