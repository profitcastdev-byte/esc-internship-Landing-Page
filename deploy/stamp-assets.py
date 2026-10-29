# -*- coding: utf-8 -*-
"""Stamp each stylesheet link in dist/*.html with a hash of that stylesheet.

Stylesheets and images alike. A plain `main.css` is free to sit in a cache for as long as the
server's headers allow, which is how a deployed change can keep not showing
up on the one device that matters. A hand-written `?v=2` only fixes that
once: the next edit reuses the same URL and the stale copy is valid again.

Hashing the file's own bytes makes the URL change exactly when the content
does - no sooner, so repeat visitors keep their cache, and no later, so a
change is never invisible. Run from the deploy script, before upload.
"""
import hashlib
import io
import os
import re
import sys

DIST = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'dist')
LINK = re.compile(r'href="([A-Za-z0-9_.-]+\.css)(\?v=[^"]*)?"')
IMG = re.compile(r'src="((?:\./)?assets/images/[A-Za-z0-9_./-]+\.(?:jpg|png|svg))(\?v=[^"]*)?"')


def digest(path):
    with open(path, 'rb') as fh:
        return hashlib.md5(fh.read()).hexdigest()[:8]


def main():
    hashes = {}
    changed = []

    for name in sorted(os.listdir(DIST)):
        if not name.endswith('.html'):
            continue
        path = os.path.join(DIST, name)
        raw = io.open(path, encoding='utf-8', newline='').read()
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')

        def stamp(m):
            css = m.group(1)
            css_path = os.path.join(DIST, css)
            if not os.path.exists(css_path):
                return m.group(0)
            if css not in hashes:
                hashes[css] = digest(css_path)
            return 'href="%s?v=%s"' % (css, hashes[css])

        def stamp_img(m):
            rel = m.group(1)
            img_path = os.path.join(DIST, rel.lstrip('./'))
            if not os.path.exists(img_path):
                return m.group(0)
            if rel not in hashes:
                hashes[rel] = digest(img_path)
            return 'src="%s?v=%s"' % (rel, hashes[rel])

        out = IMG.sub(stamp_img, LINK.sub(stamp, text))
        if out != text:
            io.open(path, 'w', encoding='utf-8', newline='').write(
                out.replace('\n', '\r\n') if crlf else out)
            changed.append(name)

    css = {k: v for k, v in hashes.items() if k.endswith('.css')}
    for name, h in sorted(css.items()):
        print('  %-24s v=%s' % (name, h))
    print('  %d images stamped' % (len(hashes) - len(css)))
    if changed:
        print('  restamped: %s' % ', '.join(changed))
    else:
        print('  stylesheet links already current')
    return 0


if __name__ == '__main__':
    sys.exit(main())
