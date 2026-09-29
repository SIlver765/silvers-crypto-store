# Project rules: Silver's apps on 5tratumOS (store: Silver765/silvers-crypto-store)

## Platform facts (observed on the real machine, 192.168.0.240, host "5tratumos", user "forge")
- Evidence so far: an `app_proxy` service declared in Hive OS PXE's compose never started (no app_proxy
  container appeared), and the other apps on the machine publish their ports directly (e.g.
  0.0.0.0:21212->3000). Treat "no app proxy" as the working assumption, NOT a proven rule. Before
  rewriting any app's compose, install it and load its manifest port from another machine on the LAN.
  Only change apps that are actually broken.
- The manifest `port:` is where the Open button goes. The app itself MUST be listening on exactly that
  port on the host. Bridge apps: publish it in `ports:`. Host-network apps (network_mode: host): bind
  that port in the app.
- docker on that machine needs sudo. Container names look like `5tratumos-<store-id>-<app>-server-1`.
- Do not install the same app from two stores. Duplicate copies fight over the same ports.

## Definition of done (never say "fixed" or "working" without doing these)
1. Container is Up/healthy (`sudo docker ps -a`), and the logs show a clean start.
2. From another machine on the LAN, connect to the manifest port and load the page
   (Test-NetConnection <ip> -Port <port>, then fetch the page). Local-only checks are not enough.
3. State plainly what was verified and what was NOT (e.g. PXE boot on real hardware).

## Release flow (one direction only: app repo -> store)
1. Change code only in the app's own repo. The store copy is overwritten hourly by
   `scripts/sync-apps.sh`, so never hand-edit files inside the store repo.
2. Bump `version` in umbrel-app.yml (Dev -> Dev2 -> Dev3). Beware string compares: Dev9 vs Dev10
   sorts wrong, so prefer zero-padded or a clearly higher string.
3. Push a git tag v<version>. CI builds and pushes ghcr.io/silver765/<image>:<tag>. Wait for the run
   to succeed. Check the package is public.
4. Read the image digest from the registry and pin `image: ...@sha256:<digest>` in docker-compose.yml.
   Commit and push.
5. Run the store sync now (`gh workflow run sync-apps.yml --repo Silver765/silvers-crypto-store`) and
   confirm the store copy shows the new version and digest.
6. Tell the user to update the app in the store UI, then verify per "Definition of done".

## Naming
- App id and folder = <store id>-<app>. The sync renames ids for the combined store, so keep the
  source repo's id pattern intact.

## Style / privacy
- No mention of the word "Umbrel" in anything user-visible (UI text, guide, docs prose). The required
  filenames umbrel-app.yml and umbrel-app-store.yml stay as they are.
- Spell the account "Silver765". Commit as the GitHub no-reply address
  (116761694+SIlver765@users.noreply.github.com); never put the user's personal email in commits.
- Confirm before publishing or pushing anything new, and report failures honestly.
