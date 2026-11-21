# Shortcut app template

A home screen icon for a stack that runs in Dockge. The app holds no data: its only page sends
the browser to the same host on the stack's port. Not an app itself (no `umbrel-app.yml` here),
so Umbrel does not list it.

To make one, for a stack named `miniflux` on port 8999:

1. Copy this folder to `aaro-miniflux/` at the root of the store.
2. Rename `umbrel-app.yml.template` to `umbrel-app.yml` and `docker-compose.yml.template` to
   `docker-compose.yml`.
3. Replace the placeholders in both files:
   - `__NAME__`: the id after `aaro-`, lower case with dashes (`miniflux`)
   - `__TITLE__`, `__TAGLINE__`, `__CATEGORY__`: what the store shows
   - `__PORT__`: a free port for the icon itself, not the stack's port
   - `__TARGET_PORT__`: the stack's port (`8999`)
4. Add `assets/aaro-miniflux.svg`.

Updates for the stack itself come from the Updates app's Dockge card, not from this shortcut.
