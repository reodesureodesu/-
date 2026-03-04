#!/usr/bin/env bash
set -euo pipefail

URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Usage: $0 <mcp_server_url>"
  exit 1
fi

PARSED="$(python - <<'PY' "$URL"
import sys
from urllib.parse import urlparse
u = urlparse(sys.argv[1])
print((u.scheme or ""), (u.hostname or ""))
PY
)"
SCHEME="$(awk '{print $1}' <<<"$PARSED")"
HOST="$(awk '{print $2}' <<<"$PARSED")"

if [[ -z "$HOST" ]]; then
  echo "❌ Invalid URL: cannot parse host"
  exit 1
fi

echo "MCP URL: $URL"
echo "Host: $HOST"

echo ""
echo "[1/3] DNS resolution"
if getent hosts "$HOST" >/dev/null; then
  getent hosts "$HOST" | head -n 1
  echo "✅ DNS resolved"
else
  echo "❌ DNS resolution failed"
  exit 1
fi

echo ""
echo "[2/3] TLS handshake"
if [[ "$SCHEME" == "https" ]]; then
  if echo | openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -subject >/dev/null 2>&1; then
    echo "✅ TLS certificate detected"
  else
    echo "⚠️ TLS check failed (network/cert issue)"
  fi
else
  echo "⚠️ TLS check skipped (scheme: $SCHEME)"
fi

echo ""
echo "[3/3] HTTP reachability"
STATUS="$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)"
if [[ "$STATUS" =~ ^[1-5][0-9][0-9]$ ]] && [[ "$STATUS" != "000" ]]; then
  echo "✅ HTTP response status: $STATUS"
else
  echo "❌ No HTTP response"
  exit 1
fi

echo ""
echo "Done. Domain verification completed."
