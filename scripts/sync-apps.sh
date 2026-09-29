#!/usr/bin/env bash
# Pulls each app's umbrel-app.yml / docker-compose.yml / icon.svg from its
# own source repo and re-stamps them for this combined store (id, icon URL,
# app_proxy APP_HOST) - the same edits that were done by hand when this
# store was first put together. Run by .github/workflows/sync-apps.yml
# every hour, or manually: ./scripts/sync-apps.sh
set -euo pipefail

STORE_ID="silvers-crypto-store"
STORE_REPO="SIlver765/silvers-crypto-store"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# source_repo | path in source repo | dest folder in this repo | old id/app-host prefix
APPS=(
  "SIlver765/Triple-X|TripleX-triple-x|${STORE_ID}-triple-x|TripleX-triple-x"
  "SIlver765/silvers-hw-monitor|silvers-hw-monitor|${STORE_ID}-hw-monitor|silvers-hw-monitor"
  "SIlver765/Hive-OS-PXE|HiveOSPXE-hive-os-pxe|${STORE_ID}-hive-os-pxe|HiveOSPXE-hive-os-pxe"
)

for entry in "${APPS[@]}"; do
  IFS='|' read -r src_repo src_path dest_dir old_prefix <<< "$entry"
  echo "== Syncing $src_repo ($src_path) -> $dest_dir =="

  clone_dir="$WORKDIR/$(basename "$src_repo")"
  git clone --depth 1 "https://github.com/${src_repo}.git" "$clone_dir" >/dev/null 2>&1

  mkdir -p "$dest_dir"
  cp "$clone_dir/$src_path/umbrel-app.yml" "$dest_dir/umbrel-app.yml"
  cp "$clone_dir/$src_path/docker-compose.yml" "$dest_dir/docker-compose.yml"
  cp "$clone_dir/$src_path/icon.svg" "$dest_dir/icon.svg"

  # Re-point id to this store's namespaced id.
  sed -i "s|^id: ${old_prefix}\$|id: ${dest_dir}|" "$dest_dir/umbrel-app.yml"

  # Re-point the icon URL at this repo instead of the source repo.
  sed -i "s|icon:.*|icon: https://raw.githubusercontent.com/${STORE_REPO}/main/${dest_dir}/icon.svg|" "$dest_dir/umbrel-app.yml"

  # Point "submission" (if present) at this store repo, not the source repo.
  if grep -q '^submission:' "$dest_dir/umbrel-app.yml"; then
    sed -i "s|^submission:.*|submission: https://github.com/${STORE_REPO}|" "$dest_dir/umbrel-app.yml"
  fi

  # app_proxy's APP_HOST must match this app's namespaced id (only apps that
  # use the default bridge networking set this - Hive OS PXE uses host
  # networking and won't match, which is fine).
  sed -i "s|APP_HOST: ${old_prefix}_web_1|APP_HOST: ${dest_dir}_web_1|" "$dest_dir/docker-compose.yml"
done

echo "Sync complete."
