# Silver's Crypto Store

A 5tratumOS **community app store** — add this repo's URL once and all of [Silver765](https://github.com/Silver765)'s apps show up in your App Store, ready to install.

## Install this store

On 5tratumOS:

1. Open the **App Store**
2. Go to **Settings -> Community App Stores -> Add a Store**
3. Paste: `https://github.com/Silver765/Silvers-crypto-store`
4. The apps below will appear under "Silver's Crypto Store"

Each app is still developed in its own repository (linked below) — this repo just packages them into one installable store.

## Apps

### [Triple X](https://github.com/Silver765/Triple-X) — v1.2-RC2
Self-hosted Monero full node + [P2Pool](https://github.com/SChernykh/p2pool) node, built from source, with optional Tari (XTM) merge-mining, Monero/Tari wallet management, Discord webhook alerts, and a web dashboard for status, pool stats, and blocks found. Payouts go straight to your own wallet — no third-party pool, no custody, 0% fee.
**Status:** Alpha · **Stack:** JavaScript

### [Silver's HW Monitor](https://github.com/Silver765/silvers-hw-monitor) — 1.4.1
Hardware monitor (CPU/RAM/storage temperature + usage) and fan control dashboard for 5tratumOS.
**Stack:** JavaScript

### [Hive OS PXE](https://github.com/Silver765/Hive-OS-PXE) — v1.0-Dev6
Network-install server for Hive OS mining rigs — proxy-DHCP + TFTP + web UI for PXE-booting rigs onto Hive OS.
**Stack:** Python

Versions above reflect the last successful sync; check each app's own repo for its full changelog.

## Updating apps

As of 5tratumOS v0.8.28, the **Update** button doesn't work for apps from any custom store. It fails with `error: invalid channel: custom-<store name>` and the installed app stays on its old version. This is a 5tratumOS issue, not a problem with this store (see the related upstream issue, [WillItMod/5tratum#99](https://github.com/WillItMod/5tratum/issues/99)).

To update an app:

1. Uninstall it and choose **Retain Data**.
2. Install it again from this store.

Your app data is kept. The reinstall picks up the version listed above.

## Contributing

Found a bug or want to suggest an app? Open an issue or PR on the relevant app's own repository.
