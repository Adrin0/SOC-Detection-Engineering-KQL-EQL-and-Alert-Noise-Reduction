# Screenshot Checklist

Only authentic screenshots captured from the lab are used in this repository. None have been
captured yet. `python scripts/check_docs.py` reads the table below and reports which files
exist, and fails if a row's status disagrees with what is on disk.

## Inventory

Status is `Pending` or `Captured`. Files live in `screenshots/<Folder>/`.

| # | Filename | Folder | Content | Source application | Associated exercise | Status | Capture date | Redaction | README location |
|---|---|---|---|---|---|---|---|---|---|
| 01 | `01-proxmox-inventory.png` | architecture | Proxmox guest inventory | Proxmox VE web UI | Lab architecture | Pending | | Not reviewed | Architecture |
| 02 | `02-elastic-dashboard.png` | elastic-setup | Elastic Security overview | Kibana Security | Lab setup | Pending | | Not reviewed | Lab setup |
| 03 | `03-agent-enrollment.png` | elastic-setup | Endpoint shipping status (Beats in this lab) | Kibana / endpoint console | Telemetry configuration | Pending | | Not reviewed | Lab setup |
| 04 | `04-windows-logs.png` | elastic-setup | Windows telemetry in Discover | Kibana Discover | Telemetry configuration | Pending | | Not reviewed | Lab setup |
| 05 | `05-kql-failed-logins.png` | kql | Failed-login KQL search | Kibana Discover | KQL-01 | Pending | | Not reviewed | KQL exercises |
| 06 | `06-kql-powershell.png` | kql | PowerShell KQL search | Kibana Discover | KQL-03 | Pending | | Not reviewed | KQL exercises |
| 07 | `07-eql-rule.png` | eql | EQL detection rule configuration | Kibana Security rules | DET-002 to DET-006 | Pending | | Not reviewed | EQL exercises |
| 08 | `08-eql-alert.png` | eql | Generated EQL alert | Kibana Security alerts | DET-002 to DET-006 | Pending | | Not reviewed | EQL exercises |
| 09 | `09-baseline-alerts.png` | alert-tuning | Alerts before tuning | Kibana Security alerts | DET-001 E1 | Pending | | Not reviewed | Alert tuning |
| 10 | `10-tuned-alerts.png` | alert-tuning | Alerts after tuning | Kibana Security alerts | DET-001 E5 | Pending | | Not reviewed | Alert tuning |
| 11 | `11-detection-timeline.png` | investigations | Investigation timeline | Kibana Security timeline | SOC-001 | Pending | | Not reviewed | Investigation case studies |
| 12 | `12-detection-metrics.png` | alert-tuning | Measured tuning results | Kibana or metrics output | DET-001 | Pending | | Not reviewed | Alert tuning |

## Capture procedure

No browser or screen capture was authorized for the initialization, so capture is manual.

1. Set the Kibana time picker so the relevant events are visible, and make sure the query bar and time range are in frame. A result without its query is not evidence.
2. Capture the browser window only (Windows: `Win + Shift + S`, window mode), not the whole desktop.
3. Save the original to `screenshots/_unredacted/`, which is git-ignored.
4. Review and redact (below), then save the redacted copy as PNG under the folder and filename in the table.
5. Keep width at or below about 1600 px and file size under about 500 KB.
6. Update the row: status `Captured`, capture date, redaction `Reviewed`.
7. Replace the "Pending" note in the document that references it with an image link, for example `![Windows failed-login investigation](screenshots/kql/05-kql-failed-logins.png)`.
8. Run `python scripts/check_docs.py`.

## Redaction review

Before a screenshot is committed, check it for:

- Passwords, API keys, tokens, enrollment tokens, and session identifiers, including in URLs.
- Public IP addresses, and internal addresses or hostnames that should not be published.
- Personal information: real names, email addresses, usernames tied to a person, browser profile pictures, bookmarks, and other open tabs.

Redact with solid boxes, not blur. Do not alter, crop out, or hide anything that changes the
security finding: counts, timestamps, rule names, and matched field values stay as captured.
If a screenshot cannot be made safe without changing its meaning, retake it with test data.
