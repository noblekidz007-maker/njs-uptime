# njs-uptime

External uptime monitoring for North JS Tech (runs on GitHub's servers, so it
keeps working even if the app server is down). Checks all production domains
every 5 hours (00/05/10/15/20 UTC — keeps GitHub Actions usage well under the
2000 free minutes/month) and sends a push alert via ntfy.sh on failure.

- Alert channel: ntfy topic in the `NTFY_TOPIC` Actions secret.
- The monthly keepalive commit prevents GitHub from disabling the schedule
  after 60 days of repo inactivity.
- Managed from the app server's `/opt/infra` (see INFRASTRUCTURE.md §7).
