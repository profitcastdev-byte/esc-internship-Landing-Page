#!/usr/bin/env bash
# Deploy the ESC landing page to Profitcast's KVM.
#
#   ./deploy/deploy-kvm.sh
#
# Uploads dist/ to /var/www/euinternship.com on 187.127.149.216 over SSH.
# Static files only - no build step, and nginx needs no reload for content.
# The vhost source of truth is deploy/euinternship.com; that file is only
# installed by hand, because certbot rewrites the server's copy in place.
set -euo pipefail

HOST="root@187.127.149.216"
DOCROOT="/var/www/euinternship.com"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dist" && pwd)"

[ -f "$SRC/index.html" ] || { echo "no index.html in $SRC" >&2; exit 1; }

echo "Uploading $(find "$SRC" -type f | wc -l) files to $HOST:$DOCROOT"

# --delete semantics without rsync (not installed on the Windows side):
# upload into a fresh dir, then swap. Keeps one generation for rollback and
# means a half-finished upload never serves.
STAMP="$(date +%Y%m%d-%H%M%S)"
tar czf - -C "$SRC" . | ssh -o BatchMode=yes "$HOST" "
  set -e
  rm -rf '$DOCROOT.new'
  mkdir -p '$DOCROOT.new'
  tar xzf - -C '$DOCROOT.new'
  chown -R www-data:www-data '$DOCROOT.new'
  find '$DOCROOT.new' -type d -exec chmod 755 {} +
  find '$DOCROOT.new' -type f -exec chmod 644 {} +
  if [ -d '$DOCROOT' ]; then
    rm -rf '$DOCROOT.prev'
    mv '$DOCROOT' '$DOCROOT.prev'
  fi
  mv '$DOCROOT.new' '$DOCROOT'
  echo \"deployed $STAMP - previous kept at $DOCROOT.prev\"
"

echo "Verifying..."
curl -s -o /dev/null -w "  preview: %{http_code}\n" \
  https://euinternship-preview.187.127.149.216.nip.io/
echo "Done."
