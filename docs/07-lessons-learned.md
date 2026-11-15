# 07 — Lessons Learned

Dated entries, newest first. Entries are added as work is completed and are not rewritten
afterwards; corrections go in a new entry that references the old one.

## 2026-11-15 — Repository initialization

Observations from inspecting the lab before any exercise was run. These are findings about
configuration, not experimental results.

- **A running sensor is not a delivering sensor.** The Sysmon and Winlogbeat services were both running, while the Winlogbeat log showed it had been unable to connect to Logstash. Service state says nothing about delivery; the check that matters is a document count in the index.
- **ECS fields are produced by configuration, not by default.** The Winlogbeat config loads no module processors, so fields such as `process.name` and `event.category` are probably absent. A query on a field that does not exist returns zero hits and is indistinguishable from a quiet environment.
- **Index naming decides field types.** If the index name does not match the Beat's template pattern, IP fields are mapped as text and CIDR logic stops working.
- **Detection needs audit policy first.** Failed-logon events are not written on Windows client editions unless failure auditing is enabled.

Each of these is listed as an open item in [PROJECT_STATUS.md](../PROJECT_STATUS.md) until
confirmed or ruled out on the running stack.
