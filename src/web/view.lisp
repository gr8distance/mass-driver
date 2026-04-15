(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; View macros: defcomponent, deflayout, defview
;;;
;;; All three build on Spinneret. defcomponent and deflayout are thin wrappers
;;; around deftag with different names for intent. defview defines a function
;;; that returns an HTML string from keyword arguments (the "assigns" from a
;;; handler).
;;;
;;; Inside defcomponent/deflayout bodies, use quasiquote syntax:
;;;   ,arg     - to interpolate an argument
;;;   ,@children - to splice child elements
;;; --------------------------------------------------------------------------

(defmacro defcomponent (name args &body body)
  "Define a reusable UI component.

Usage:
  (defcomponent card (title &key (class \"\"))
    `(:div :class ,(format nil \"card ~a\" class)
       (:h2 ,title)
       (:div :class \"card-body\" ,@children)))

  ;; In templates:
  (card :title \"Hello\"
    (:p \"child content\"))"
  `(spinneret:deftag ,name (mass-driver:children attrs &key ,@(remove '&key args))
     (declare (ignore attrs))
     ,@body))

(defmacro deflayout (name args &body body)
  "Define a page layout. Identical to defcomponent in mechanism,
separated for clarity of intent.

Usage:
  (deflayout app-layout (&key (title \"mass-driver\"))
    `(:doctype)
     (:html
       (:head (:title ,title))
       (:body ,@children))))"
  `(spinneret:deftag ,name (mass-driver:children attrs &key ,@(remove '&key args))
     (declare (ignore attrs))
     ,@body))

(defmacro defview (name args &body body)
  "Define a view function that receives assigns from a handler and returns
an HTML string.

Usage:
  (defview pages/home (title message)
    (app-layout :title title
      (:h1 message)))

  ;; In handler:
  (render conn 'pages/home :title \"Hi\" :message \"Welcome\")"
  `(defun ,name (&key ,@args)
     (declare (ignorable ,@(mapcar (lambda (a) (if (listp a) (car a) a)) args)))
     (spinneret:with-html-string
       ,@body)))
