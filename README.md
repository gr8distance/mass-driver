# mass-driver

A micro web framework for Common Lisp, inspired by Phoenix.

Composable, minimal, and production-ready. Built on Clack/Woo with a Phoenix-style DSL, DDD architecture, and Sly-friendly hot reload.

## Quick Start

```bash
# Install mass-driver-cli
git clone https://github.com/gr8distance/mass-driver-cli
cd mass-driver-cli && area51 install && area51 build
sudo cp bin/mass-driver-cli /usr/local/bin/mass-driver

# Create a new project
mass-driver new my-app
cd my-app
area51 install
area51 run
# => http://localhost:3000
```

## Project Structure

```
my-app/
├── area51.lisp              # Dependencies
├── my-app.asd               # System definition
├── src/
│   ├── package.lisp
│   ├── config.lisp          # 12-factor config (env vars)
│   ├── main.lisp            # Entry point + router
│   ├── domain/              # Pure domain logic (no DB/web deps)
│   │   └── accounts/
│   │       ├── package.lisp
│   │       └── user.lisp    # Entities, validation, conditions
│   ├── app/                 # Use cases
│   │   └── accounts.lisp    # create-user, find-or-create-user
│   ├── infra/               # Infrastructure
│   │   └── repo/
│   │       └── user-repo.lisp  # Mito repository implementation
│   ├── db/                  # DB connection + migration
│   └── web/
│       ├── conn.lisp        # Request/response object
│       ├── router.lisp      # Phoenix-style routing DSL
│       ├── handler.lisp     # defhandler
│       ├── session.lisp     # Session management
│       ├── view.lisp        # defcomponent / deflayout / defview
│       ├── components/      # Reusable UI components
│       ├── layouts/         # Page layouts
│       └── pages/           # Page views
├── static/                  # CSS, JS, images
├── migrations/              # Timestamped DB migrations
├── tests/
├── Dockerfile
└── docker-compose.yml
```

## Routing

Phoenix-inspired DSL with scoped routes and middleware pipelines:

```lisp
(defrouter *router*
  (pipeline :browser
    'logger-middleware
    'body-parser-middleware
    'session-middleware)

  (pipeline :api
    'logger-middleware
    'body-parser-middleware)

  (scope "/" (:browser)
    (:get  "/"      'page/index)
    (:get  "/about" 'page/about))

  (scope "/api" (:api)
    (scope "/v1" ()
      (:get    "/users"     'api/list-users)
      (:post   "/users"     'api/create-user)
      (:get    "/users/:id" 'api/show-user))))
```

## Handlers

```lisp
(defhandler page/index (conn)
  (render conn 'pages/home
          :title "My App"
          :message "Welcome"))

(defhandler api/list-users (conn)
  (respond-json conn
    (mapcar #'user-to-plist (app.accounts:list-users))))
```

## Views

Three layers — components, layouts, and pages:

```lisp
;; Component
(defcomponent card (title &key (class ""))
  `(:div :class ,(format nil "card ~a" class)
     (:h2 ,title)
     (:div :class "card-body" ,@children)))

;; Layout
(deflayout app-layout (&key (title "my-app"))
  `(progn
     (:doctype)
     (:html
       (:head (:title ,title))
       (:body ,@children))))

;; Page (receives data from handler)
(defview pages/home (title message)
  (app-layout :title title
    (:h1 message)
    (card :title "Hello" (:p "World"))))
```

## Database

```lisp
;; Model (in infra layer)
(defmodel user-record ()
  ((name  :col-type (:varchar 64))
   (email :col-type (:varchar 128))))

;; Connect and migrate
(connect-db)       ; reads DATABASE_URL
(auto-migrate)     ; sync models to DB

;; Explicit migrations
(defmigration "20260415_create_users"
  :up   (lambda () (auto-migrate))
  :down (lambda () (mito:execute-sql "DROP TABLE IF EXISTS user_record")))

(migrate)          ; run pending
(rollback)         ; revert last
```

## Session & Flash

```lisp
(session-set conn :user-id 42)
(session-get conn :user-id)
(session-clear conn)              ; logout

(flash-put conn :info "Saved!")
(flash-get conn :info)            ; reads and clears
```

## i18n

```lisp
(deftranslation :en
  (:greeting "Hello")
  (:user.name "Name"))

(deftranslation :ja
  (:greeting "こんにちは")
  (:user.name "名前"))

(t! :greeting)                    ; => "Hello"
(t! :greeting :locale :ja)        ; => "こんにちは"

;; Auto-detect from Accept-Language
(with-locale (conn)
  (t! :greeting))
```

## Configuration

12-factor style — everything from environment variables:

```lisp
(env "PORT" "3000")              ; string with default
(env-int "PORT" 3000)            ; integer
(env-bool "DEBUG" nil)           ; boolean

(config :port)                   ; from pre-loaded config
```

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3000 | Server port |
| `SERVER` | woo | Clack server (:woo or :hunchentoot) |
| `DATABASE_URL` | sqlite3:///tmp/...-dev.db | DB connection |
| `SECRET_KEY_BASE` | dev-secret-... | Session signing |
| `LOG_LEVEL` | info | debug/info/warn/error |
| `LOG_FORMAT` | text | text/json |
| `SMTP_HOST` | localhost | Mail server |

## CLI

```bash
mass-driver new my-app                            # Full stack + SQLite
mass-driver new my-api --api                      # API only (no HTML views)
mass-driver new my-app --database postgres        # With PostgreSQL
mass-driver new my-site --database nil            # No database

mass-driver gen.handler users                     # Generate handler scaffold
mass-driver gen.model post title:string body:text # Generate domain + repo + migration
mass-driver gen.component modal                   # Generate component
```

## Testing

```lisp
;; tests/handler-test.lisp
(deftest test-home-page
  (let ((conn (request :get "/")))
    (ok (assert-status conn 200))
    (ok (assert-body-contains conn "Welcome"))))

;; Domain tests — no DB needed
(deftest test-user-validation
  (ok (handler-case
          (progn (validate-user (make-user :email "" :name "Test")) nil)
        (invalid-user () t))))
```

```bash
area51 test
```

## Architecture

```
web  →  app  →  domain
                  ↑
          infra ──┘
```

- **domain**: Pure entities, validation, conditions. No dependencies.
- **app**: Use cases orchestrating domain + infra.
- **infra**: Repository implementations (Mito).
- **web**: HTTP interface (handlers, views, middleware).

Dependencies point inward. Domain knows nothing about the database or web.

## Hot Reload (Sly)

All handlers, views, and middleware use symbol references (not function objects), so recompiling with `C-c C-c` in Sly takes effect on the next request.

## Docker

```bash
docker compose up           # development
docker build -t my-app .    # production binary
```

## Stack

| Role | Library |
|------|---------|
| HTTP abstraction | Clack |
| Production server | Woo (libev) |
| Dev server | Hunchentoot |
| Routing | Built-in (Phoenix-style DSL) |
| HTML | Spinneret |
| CSS generation | Lass |
| CSS utilities | Tailwind |
| ORM | Mito |
| SQL | SxQL |
| JSON | Yason |
| Mail | cl-smtp |
| Testing | Rove |
| Build | [area51](https://github.com/gr8distance/area51) |

## Roadmap

- [ ] WebSocket support (likely via external tool integration, not pure SBCL)
- [ ] File upload (multipart parser)
- [ ] Signed tokens (Phoenix.Token equivalent for email verification, etc.)
- [ ] Rate limiting middleware
- [ ] OAuth guide (clath integration documentation)
- [ ] `assets/` build pipeline (bun + Tailwind CLI, replacing CDN)
- [ ] CLI installer (GitHub Releases / Homebrew tap)
- [ ] Background job integration (infrastructure-side approach)

## License

MIT
