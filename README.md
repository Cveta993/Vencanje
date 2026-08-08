# Wedding invitation

A Rails 8 invitation and RSVP application. Every recipient gets a long, personal URL; that URL identifies the invitation and lets the guest create or edit one response. The admin area creates links, shows every named attendee, and exports seating data as CSV.

## Local setup

Requirements: Ruby 3.3.3 and SQLite 3.

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

The development seed creates:

- Admin: `admin@example.com`
- Password: `promeni-me-odmah`
- One demo invitation (the seed prints its URL)

Open `/admin/login` to create real invitation links. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` before seeding production; production seeds refuse to use the development password.

## Wedding content and photos

Edit names, date, RSVP deadline, and the three event entries in [`config/wedding.yml`](config/wedding.yml).

The three supplied photos are stored under `app/assets/images/wedding/` and selected in `config/wedding.yml`.

Recommended mapping:

- Engagement/kiss photo → hero
- Bled photo → schedule
- Childhood photo → RSVP

The desktop layout presents them as three compact stacked scenes, so two neighboring photos remain visible while scrolling. Mobile uses taller crops to preserve the subjects and keep the RSVP form readable.

## RSVP data

`Invitation` owns one `Rsvp`, which owns the individual `RsvpGuest` rows. Adult and child totals are calculated from those rows instead of being stored separately. This keeps the displayed totals, admin dashboard, and seating CSV consistent.

Guests can revisit the same link and update their response. A declined response removes any previously entered attendee rows.

## Checks

```sh
PARALLEL_WORKERS=1 bin/rails test
bin/rails test:system
bundle exec rubocop
bundle exec brakeman --no-pager
```

The browser tests require Google Chrome or Chromium.

Gallery uploads and cloud storage are intentionally deferred to the later hosting/R2 phase.
