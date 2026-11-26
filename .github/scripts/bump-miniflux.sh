#!/usr/bin/env bash
# Moves aaro-miniflux to the newest Miniflux release once it is MIN_AGE_DAYS old.
# Re-pins postgres:17 at the same time (same major, so no data upgrade is needed).
set -euo pipefail
APP=aaro-miniflux
MIN_AGE_DAYS=${MIN_AGE_DAYS:-2}

release=$(curl -fsSL https://api.github.com/repos/miniflux/v2/releases/latest)
ver=$(jq -r .tag_name <<<"$release")
published=$(jq -r .published_at <<<"$release")
[[ $ver =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "unexpected tag $ver"; exit 1; }

current=$(sed -n 's/^version: "\(.*\)"/\1/p' $APP/umbrel-app.yml)
if [[ $ver == "$current" ]]; then echo "up to date ($current)"; exit 0; fi

age_days=$(( ( $(date +%s) - $(date -d "$published" +%s) ) / 86400 ))
if (( age_days < MIN_AGE_DAYS )); then echo "$ver is $age_days days old, waiting"; exit 0; fi

digest() {
  local tok
  tok=$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$1:pull" | jq -r .token)
  curl -fsSI -H "Authorization: Bearer $tok" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://registry-1.docker.io/v2/$1/manifests/$2" | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}'
}
mf=$(digest miniflux/miniflux "$ver")
pg=$(digest library/postgres 17)
[[ $mf == sha256:* && $pg == sha256:* ]] || { echo "no digest yet for $ver"; exit 0; }

sed -i -E "s#image: miniflux/miniflux:[^ ]+#image: miniflux/miniflux:$ver@$mf#; s#image: postgres:17@[^ ]+#image: postgres:17@$pg#" $APP/docker-compose.yml
sed -i -E "s#^version: \".*\"#version: \"$ver\"#; s#Miniflux [0-9.]+\. Full notes: .*#Miniflux $ver. Full notes: https://github.com/miniflux/v2/releases/tag/$ver#" $APP/umbrel-app.yml
echo "bumped $current -> $ver"
echo "bumped=$ver" >> "${GITHUB_OUTPUT:-/dev/null}"
