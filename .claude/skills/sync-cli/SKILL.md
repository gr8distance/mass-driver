---
name: sync-cli
description: Ensures mass-driver-cli templates are updated when mass-driver framework code changes. Auto-invokes when modifying macros, middleware, config functions, exports, or .asd dependencies.
---

# Sync CLI Templates

When you modify mass-driver (the framework), you MUST also update mass-driver-cli (the generator) to keep templates in sync.

## When to trigger

This skill applies when ANY of the following are changed:

- **Macros**: defrouter, defhandler, defcomponent, deflayout, defview, defmodel, defmigration, deferror, defmail, deftranslation
- **Middleware**: logger-middleware, body-parser-middleware, session-middleware, csrf-token-middleware, i18n-middleware
- **Functions**: config, env, compile-styles, connect-db, setup-logger, render, respond, redirect, respond-json, flash-put, flash-get, session-get, session-set, migrate, rollback
- **Package exports**: src/package.lisp
- **System dependencies**: mass-driver.asd :depends-on

## What to update

The CLI templates live at `~/lisp/mass-driver-cli/src/commands/`:

1. **`new.lisp`** — Project scaffold generator. Contains:
   - `gen-main-file`: router, pipelines, make-app, start, main
   - `gen-web-handlers`: default handler code
   - `gen-web-views`: layout, components, pages
   - `gen-src-base`: package.lisp, config.lisp
   - `gen-area51-lisp`: dependency list
   - `gen-asd-file`: system definition

2. **`gen-handler.lisp`** — Handler scaffold (uses defhandler, render, respond-json, flash-put, redirect)

3. **`gen-model.lisp`** — Model scaffold (uses defmodel, defmigration, auto-migrate)

4. **`gen-component.lisp`** — Component scaffold (uses defcomponent)

## Process

1. Make the framework change in ~/lisp/mass-driver/
2. Identify which templates are affected
3. Update the templates in ~/lisp/mass-driver-cli/src/commands/
4. Rebuild CLI: `cd ~/lisp/mass-driver-cli && area51 build`
5. Test: generate a new project and verify it works
