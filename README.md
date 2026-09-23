# ESC — Europe Study Centre Landing Page

Landing page for Europe Study Centre's free European internship programme.

**Live:** https://euinternship.com
**Review link:** https://euinternship-preview.187.127.149.216.nip.io (noindex)

## What this is

A static page — no build step, no framework, no server-side code. Bootstrap 5.3
and Bootstrap Icons load from jsDelivr; Plus Jakarta Sans loads from Google
Fonts. Everything else ships in this repo.

```
dist/                 what gets served
  index.html          the whole page (single file, section-commented)
  main.css            all styling, no CSS variables by design
  assets/images/      photography, SVG illustrations, flags
deploy/               nginx vhost + deploy script for the host
```

## Editing

`dist/index.html` is organised into commented sections that match the class
prefixes in `main.css` (`esc-hero-banner-section`, `esc-four-countries-section`,
and so on). Each section's styles live under the same heading in `main.css`,
with its responsive rules immediately after.

Internship cards are hand-written blocks in the `esc-four-countries-section`;
add or remove a card by copying one `col-xl-3` block and editing the title,
location and image.

## Deploying

See `deploy/` for the nginx configuration and the upload script. Content
changes need no nginx reload — the deploy script swaps the docroot atomically
and keeps the previous release for rollback.

## Known issues

- Page `<title>` still reads "10-Day Immersion Tour"; the programme is now two weeks.
- Mobile menu's WhatsApp button links to `https://wa.me/` with no number (desktop and footer are correct).
- ~90 lines of typewriter script at the end of `index.html` target element IDs that no longer exist, so it exits immediately.
- Footer legal links (Privacy Policy, Terms, Disclaimer, Sitemap) all point at `#`.
