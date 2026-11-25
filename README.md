# njs-uptime

External uptime monitoring for North JS Tech. It runs on GitHub's servers, so it
keeps working even if an app server is down.

- **What:** every URL in [`urls.txt`](urls.txt) (njs-prod-1 and njt-prod-01). The
  website is probed at `/`, the apps at `/healthz`. Add or remove a line to change it.
- **When:** every 10 minutes (`3-59/10 * * * *`). The repo is public, so Actions
  minutes are free. If it ever goes private again, switch to `*/30` to stay under
  the 2000 free minutes/month.
- **How:** all URLs in parallel, 2 attempts each, 15 s timeout. A full outage
  finishes in under a minute.
- **Alerts** (ntfy topic in the `NTFY_TOPIC` Actions secret):
  - `SITE DOWN`: a URL just started failing (priority max).
  - `STILL DOWN`: repeated every 60 min while it stays down (priority high).
  - `RECOVERED`: it came back (priority default).

  Alert state is kept between runs with `actions/cache` (`state/failed.txt`).
- **Keepalive:** a monthly commit (00:30 UTC on the 1st) stops GitHub from
  disabling the schedule after 60 days of inactivity.

This is the slow, external layer. Fast alerts come from the servers themselves
(`njs-doctor` app health on njs-prod-1, `njt-health` on njt-prod-01, every
2 min). Whole-server outages are caught by healthchecks.io heartbeats. See
`/opt/infra` INFRASTRUCTURE.md §7.
