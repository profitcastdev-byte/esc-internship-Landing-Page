# Europe Study Centre - free EU internship landing page
# euinternship.com
#
# Static page: deploy/deploy-kvm.sh uploads index.html + main.css + assets/
# to the docroot. No build step, no server-side code.
#
# Three names are served here:
#   euinternship.com      - the live home. NOTE: as of deploy, the apex still
#                           carries two leftover GoDaddy parking A records
#                           (76.223.105.230, 13.248.243.5) alongside this box.
#                           Until those are deleted, ~2 of 3 visitors resolve
#                           to an address that answers nothing, and ACME
#                           HTTP-01 validation for this name is a coin flip.
#   www.euinternship.com  - listed so it works the moment a www A record exists.
#                           It has none today, so listing it changes nothing.
#   euinternship-preview.187.127.149.216.nip.io
#                         - the review link; nip.io resolves to this box with
#                           no DNS change, so it is unaffected by the above.
#
# Indexing: only the review link sends X-Robots-Tag noindex.
#
# Deliberately NOT default_server: rentla-preview holds it on this box, and
# claiming it here would change where every unmatched hostname lands.
#
# gzip is inherited from nginx.conf.
#
# Caching is set with `expires`, never with add_header inside a location. A
# location that declares any add_header silently drops every add_header it
# would inherit from the server block. `expires` is not add_header, so the
# three headers below reach every response from this one place.
#
# HTTP-only as written; certbot --nginx rewrites the server copy to add the
# :443 block and the 80->443 redirect. This file is the pre-certbot source.

# Empty for the live names, so add_header sends nothing there (nginx skips a
# header whose value evaluates to ""). Prefixed to stay unique across the
# http-level namespace every vhost on this box shares.
map $host $euinternship_robots {
    default                                        "";
    euinternship-preview.187.127.149.216.nip.io    "noindex, nofollow";
}

server {
    listen 80;
    listen [::]:80;

    server_name euinternship.com www.euinternship.com euinternship-preview.187.127.149.216.nip.io;

    root /var/www/euinternship.com;
    index index.html;

    access_log /var/log/nginx/euinternship.com.access.log;
    error_log  /var/log/nginx/euinternship.com.error.log;

    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Robots-Tag $euinternship_robots always;

    # Must win over the dotfile rule below, or issuance and every silent 60-day
    # renewal would fail. ^~ beats a regex location, hence this form.
    location ^~ /.well-known/acme-challenge/ {
        allow all;
    }

    # Photos and SVGs keep their filenames across deploys, so they get a day,
    # not a year. Replace an image under a NEW filename (or bump its ?v= in
    # index.html), or returning visitors keep the old one for up to 24h.
    location ^~ /assets/ {
        expires 1d;
        access_log off;
    }

    # Bootstrap and the icon font are pinned to a version in the CDN URL, so
    # only the page's own stylesheet is served from here. Revalidate it with
    # index.html rather than letting a redeploy ship stale CSS.
    location = /main.css {
        expires -1;
    }

    # "/" reaches this block too, via the index directive's internal redirect.
    # Revalidated on every visit, so a redeploy shows on the next page load.
    location = /index.html {
        expires -1;
    }

    location ~ /\. {
        deny all;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
