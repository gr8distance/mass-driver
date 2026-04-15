(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Styles (Lass)
;;;
;;; Lass generates CSS from S-expressions. These are base styles that
;;; complement Tailwind's utility classes.
;;;
;;; Call (compile-styles) to regenerate static/css/app.css.
;;; --------------------------------------------------------------------------

(defparameter *base-styles*
  '(;; Reset
    ("*, *::before, *::after"
     :box-sizing border-box
     :margin 0
     :padding 0)

    ;; Base typography
    (body
     :font-family "system-ui, -apple-system, sans-serif"
     :line-height 1.6
     :color "#1a1a2e"
     :background "#fafafa")

    ;; Links
    (a
     :color "#4361ee"
     :text-decoration none
     :transition "color 0.2s ease")
    ("a:hover"
     :color "#3a0ca3")

    ;; Card component
    (.card
     :background "#ffffff"
     :border "1px solid #e2e8f0"
     :border-radius "0.5rem"
     :padding "1.5rem"
     :box-shadow "0 1px 3px rgba(0,0,0,0.08)"
     :transition "box-shadow 0.2s ease")
    (".card:hover"
     :box-shadow "0 4px 12px rgba(0,0,0,0.1)")
    (".card h2"
     :font-size "1.25rem"
     :font-weight 600
     :margin-bottom "0.75rem"
     :color "#1a1a2e")
    (.card-body
     :color "#4a5568")

    ;; Navbar
    (.navbar
     :display flex
     :align-items center
     :padding "1rem 2rem"
     :background "#ffffff"
     :border-bottom "1px solid #e2e8f0")
    (.navbar-brand
     :font-size "1.25rem"
     :font-weight 700
     :color "#1a1a2e"
     :margin-right "2rem")
    (".navbar-brand:hover"
     :color "#1a1a2e")
    (.navbar-links
     :display flex
     :gap "1.5rem")

    ;; Code
    (code
     :font-family "ui-monospace, monospace"
     :background "#f1f5f9"
     :padding "0.125rem 0.375rem"
     :border-radius "0.25rem"
     :font-size "0.875em")))

(defun compile-styles ()
  "Compile Lass styles and write to static/css/app.css."
  (let ((css (format nil "~{~a~%~}"
                     (mapcar #'lass:compile-and-write *base-styles*)))
        (path (asdf:system-relative-pathname "mass-driver" "static/css/app.css")))
    (with-open-file (out path :direction :output :if-exists :supersede)
      (write-string css out))
    (format t "Compiled styles to ~a~%" path)
    path))
