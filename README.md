# njs-uptime

External uptime monitoring for North JS Tech (runs on GitHub's servers, so it
keeps working even if the app server is down). Checks all production domains
every hour (~744 runs ≈ 750 billed minutes/month, still under the 2000 free
minutes/month) and sends a push alert via ntfy.sh on failure.

- Alert channel: ntfy topic in the `NTFY_TOPIC` Actions secret.
- The monthly keepalive commit (own cron, 00:30 UTC on the 1st) prevents GitHub
  from disabling the schedule after 60 days of repo inactivity.
- Managed from the app server's `/opt/infra` (see INFRASTRUCTURE.md §7).
