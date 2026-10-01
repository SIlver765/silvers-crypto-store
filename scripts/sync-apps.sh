#!/usr/bin/env bash
# Pulls each app's umbrel-app.yml / docker-compose.yml / icon.svg from its
# own source repo and re-stamps them for this combined store (id, icon URL,
# app_proxy APP_HOST) - the same edits that were done by hand when this
# store was first put together. Run by .github/workflows/sync-apps.yml
# every hour, or manually: ./scripts/sync-apps.sh
#
# One app's failure (private repo, network blip, missing file, etc.) does
# NOT abort the others - each app is synced independently, real errors are
# printed (not swallowed), and the script exits non-zero at the end if any
# app failed, so the workflow still notices even though the apps that did
# succeed get committed.
set -uo pipefail

STORE_ID="silvers-crypto-store"
STORE_REPO="SIlver765/silvers-crypto-store"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# source_repo | path in source repo | dest folder in this repo | old id/app-host prefix | README heading text
APPS=(
  "SIlver765/Triple-X|TripleX-triple-x|${STORE_ID}-triple-x|TripleX-triple-x|Triple X"
  "SIlver765/silvers-hw-monitor|silvers-hw-monitor|${STORE_ID}-hw-monitor|silvers-hw-monitor|Silver's HW Monitor"
  "SIlver765/Hive-OS-PXE|HiveOSPXE-hive-os-pxe|${STORE_ID}-hive-os-pxe|HiveOSPXE-hive-os-pxe|Hive OS PXE"
)

sync_one() (
  set -euo pipefail
  src_repo="$1" src_path="$2" dest_dir="$3" old_prefix="$4"

  clone_dir="$WORKDIR/$(basename "$src_repo")"
  git clone --depth 1 "https://github.com/${src_repo}.git" "$clone_dir"

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
)

failed=()
for entry in "${APPS[@]}"; do
  IFS='|' read -r src_repo src_path dest_dir old_prefix readme_heading <<< "$entry"
  echo "== Syncing $src_repo ($src_path) -> $dest_dir =="
  # Plain statement, not `if sync_one ...` directly - bash only honors the
  # subshell's own `set -e` (stopping at the first failing command inside
  # it) when it isn't itself the thing being tested by if/&&/||.
  sync_one "$src_repo" "$src_path" "$dest_dir" "$old_prefix"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "!! FAILED syncing $src_repo - see error above. Leaving its existing store copy untouched." >&2
    failed+=("$src_repo")
    continue
  fi

  # Keep the README's "## Apps" version badges in sync with what was just
  # pulled - only touches the "— v..." tail of that app's heading line, not
  # its link or description.
  version=$(grep '^version:' "$dest_dir/umbrel-app.yml" | head -1 | sed -E 's/^version: *"?([^"]*)"?.*/\1/')
  if [ -n "$version" ] && [ -f README.md ]; then
    sed -i -E "s|^(### \[${readme_heading}\]\([^)]*\)) — .*|\1 — ${version}|" README.md
  fi
done

if [ "${#failed[@]}" -gt 0 ]; then
  echo "Sync finished with failures: ${failed[*]}" >&2
  exit 1
fi

echo "Sync complete."
