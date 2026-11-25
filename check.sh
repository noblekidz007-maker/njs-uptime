#!/usr/bin/env bash
# Probes every URL in urls.txt in parallel and pushes ntfy alerts:
#   new failure -> max, still failing -> high every REALERT_SEC, recovered -> default.
# State between runs lives in state/failed.txt ("url first_fail last_alert"), kept by actions/cache.
set -u
cd "$(dirname "$0")"
STATE=state/failed.txt
REALERT_SEC=${REALERT_SEC:-3600}
mkdir -p state
touch "$STATE"

probe() {
  local u=$1 code attempt
  for attempt in 1 2; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 -A 'njs-uptime' "$u" 2>/dev/null)
    case "$code" in 2*|3*) echo "OK $u $code"; return;; esac
    [ "$attempt" = 1 ] && sleep 5
  done
  echo "FAIL $u ${code:-000}"
}
export -f probe

grep -vE '^[[:space:]]*(#|$)' urls.txt | xargs -P 16 -I{} bash -c 'probe "$1"' _ {} > results.txt

notify() { # notify <priority> <title> <tags> <message>
  if [ -z "${NTFY_TOPIC:-}" ]; then echo "NTFY_TOPIC not set, skipping: $2"; return; fi
  curl -fsS -m 10 -H "Title: $2" -H "Priority: $1" -H "Tags: $3" -d "$4" \
    "https://ntfy.sh/$NTFY_TOPIC" >/dev/null || echo "ntfy send failed: $2"
}

now=$(date +%s)
NEW="" STILL="" RECOVERED="" NEXT=""
while read -r status u code; do
  [ "$status" = FAIL ] || continue
  host=${u#https://}
  prev=$(awk -v u="$u" '$1==u' "$STATE")
  if [ -z "$prev" ]; then
    NEW="$NEW $host($code)"
    NEXT="$NEXT$u $now $now"$'\n'
  else
    read -r _ first last <<<"$prev"
    if [ $((now - last)) -ge "$REALERT_SEC" ]; then
      STILL="$STILL $host($code, $(( (now - first) / 60 ))m)"
      last=$now
    fi
    NEXT="$NEXT$u $first $last"$'\n'
  fi
done < results.txt

while read -r u first _; do
  [ -n "$u" ] || continue
  grep -q "^FAIL $u " results.txt || RECOVERED="$RECOVERED ${u#https://}($(( (now - first) / 60 ))m)"
done < "$STATE"

printf '%s' "$NEXT" > "$STATE"

[ -n "$NEW" ] && notify max "SITE DOWN (external check)" rotating_light "Unreachable from GitHub:$NEW"
[ -n "$STILL" ] && notify high "STILL DOWN (external check)" warning "Still unreachable:$STILL"
[ -n "$RECOVERED" ] && notify default "RECOVERED (external check)" white_check_mark "Back up after downtime:$RECOVERED"

total=$(wc -l < results.txt)
failed=$(grep -c '^FAIL' results.txt)
grep '^FAIL' results.txt
echo "checked $total URLs, $failed failing"
[ "$failed" -eq 0 ]
