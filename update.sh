#!/usr/bin/env bash
# Rewrite release.json from Google's release feed.
set -euo pipefail
cd "$(dirname "$0")"

base=https://storage.googleapis.com/antigravity-public/antigravity-cli
version=$(curl -fsS "$base/latest")
manifest=$(curl -fsS "$base/$version/manifest.json")

if [[ -f release.json && $(jq -r .version release.json) == "$version" ]]; then
  echo "up to date: $version"
  exit 0
fi

# Keep only the platforms package.nix uses; turn Google's hex sha512 into an SRI hash.
jq --arg v "$version" '
  {version: $v,
   platforms: (.platforms | with_entries(select(.key | IN("linux-x64", "linux-arm")))
     | map_values({url, hash: .sha512}))}' <<<"$manifest" > release.json.tmp

jq -r '.platforms[].hash' release.json.tmp | while read -r hex; do
  nix hash convert --hash-algo sha512 --to sri "$hex"
done > hashes.tmp

jq --rawfile h hashes.tmp '
  ($h | split("\n") | map(select(. != ""))) as $hs
  | .platforms |= (to_entries | to_entries
      | map(.value.value.hash = $hs[.key] | .value) | from_entries)' release.json.tmp > release.json
rm -f release.json.tmp hashes.tmp
echo "updated to $version"
