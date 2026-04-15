(in-package #:mass-driver)

;;; --------------------------------------------------------------------------
;;; Application entry point
;;; --------------------------------------------------------------------------

;;; --- Handlers ---

(defhandler page/index (conn)
  (render conn 'pages/home
          :title "mass-driver"
          :message "Welcome to mass-driver"))

(defhandler page/about (conn)
  (render conn 'pages/home
          :title "About"
          :message "A micro web framework for Common Lisp"))

;;; --- Router ---

(defrouter *router*
  (pipeline :browser
    'logger-middleware
    'body-parser-middleware
    'session-middleware)

  (scope "/" (:browser)
    (:get "/"      'page/index)
    (:get "/about" 'page/about)))

;;; --- App ---

(defun make-app ()
  "Build the Clack application with session and static file serving."
  (lack:builder
    (:session)
    (:static :path (config :static-path)
             :root (asdf:system-relative-pathname "mass-driver" "static/"))
    (lambda (env)
      (dispatch *router* env))))

(defun start (&key (port (config :port)) (server (config :server)))
  "Start the server."
  (setup-logger)
  (compile-styles)
  (log-info "Starting mass-driver on port ~a (~a)" port server)
  (clack:clackup (make-app) :port port :server server))

(defun main ()
  "Entry point for binary builds."
  (reload-config)
  (start)
  (loop (sleep 3600)))
