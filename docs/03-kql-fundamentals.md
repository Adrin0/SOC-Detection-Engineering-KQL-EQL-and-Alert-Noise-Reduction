# 03 — KQL Fundamentals

Eight hunting exercises in Kibana Discover. **All queries are untested**: the lab stack was
unreachable when they were written (2026-11-15). Run each one, correct it against the real
field mapping, then record results and change its status.

## KQL in one page

| Pattern | Meaning |
|---|---|
| `field: value` | Field contains the value (exact match on keyword fields) |
| `field: "two words"` | Phrase match. Wildcards inside quotes are literal |
| `field: (a or b)` | Any of several values |
| `field: *` | Field exists |
| `field: *text*` | Wildcard, case-sensitive on keyword fields in 7.17 |
| `not`, `and`, `or` | Boolean logic; use parentheses, `and` binds tighter than `or` |
| `field >= 10` | Range on numeric and date fields |
| `ip_field: 10.0.0.0/8` | CIDR match, only on fields mapped as `ip` |

KQL filters documents. It does not aggregate, count, or correlate; thresholds need a threshold
rule or a visualization, and ordered sequences need EQL ([04](04-eql-detection-engineering.md)).

Each exercise gives an ECS query and a raw fallback. The ECS form needs the Winlogbeat module
processors described in [02](02-telemetry-configuration.md); the fallback works on the raw
`winlog.event_data.*` fields. Index pattern is `winlogbeat-*` unless stated.

Saved copies of the ECS queries are in [detection-rules/kql/](../detection-rules/kql/).

---

## KQL-01 — Failed Windows logins

- **Objective:** Find failed logon attempts and see which accounts, sources, and logon types produce them.
- **Query:**
  ```
  event.provider: "Microsoft-Windows-Security-Auditing" and event.code: "4625"
  ```
- **Required ECS fields:** `event.code`, `event.provider`, `event.outcome`, `user.name`, `source.ip`, `host.name`; plus `winlog.event_data.LogonType`, `winlog.event_data.Status`, `winlog.event_data.SubStatus`.
- **Raw fallback:** the query above works without module processors; read the account from `winlog.event_data.TargetUserName` and the source from `winlog.event_data.IpAddress`.
- **Expected results:** One document per failed logon. None at all usually means failure auditing is off (see 02, gap 5).
- **Screenshot:** Pending, `screenshots/kql/05-kql-failed-logins.png`.
- **Investigation questions:** Which accounts fail most? Do failures come from one source or many? What do the `SubStatus` codes say (bad password versus unknown user)? Are failures clustered in time?
- **Limitations:** Only sees logons audited on this host. Shows events, not rates; a burst and a slow trickle look the same without a time histogram.
- **Status:** Not started, untested.

## KQL-02 — Successful Windows logins

- **Objective:** Baseline normal interactive and network logons so unusual ones stand out.
- **Query:**
  ```
  event.code: "4624" and winlog.event_data.LogonType: ("2" or "3" or "7" or "10" or "11") and not winlog.event_data.TargetUserName: (SYSTEM or *$)
  ```
- **Required ECS fields:** `event.code`, `event.outcome`, `user.name`, `source.ip`, `host.name`; plus `winlog.event_data.LogonType`, `winlog.event_data.TargetUserName`.
- **Raw fallback:** the query uses raw fields already.
- **Expected results:** Logons by real users; type 2 at the console, 7 on unlock, 3 for network access, 10 for RDP.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** Which logon types occur on this host and when? Any type 10 or type 3 logons from unexpected addresses? Does a success follow a run of failures for the same account?
- **Limitations:** 4624 is high volume and mostly benign. Excluding service and machine accounts by name is a convenience, not a security boundary.
- **Status:** Not started, untested.

## KQL-03 — PowerShell execution

- **Objective:** List PowerShell process starts with their command lines and parents.
- **Query:**
  ```
  event.provider: "Microsoft-Windows-Sysmon" and event.code: "1" and process.name: ("powershell.exe" or "pwsh.exe")
  ```
- **Required ECS fields:** `event.code`, `process.name`, `process.command_line`, `process.parent.name`, `process.parent.command_line`, `user.name`, `host.name`.
- **Raw fallback:**
  ```
  event.code: "1" and winlog.event_data.Image: (*\\powershell.exe or *\\pwsh.exe)
  ```
- **Expected results:** One document per PowerShell start, including those launched by scheduled tasks and management tooling.
- **Screenshot:** Pending, `screenshots/kql/06-kql-powershell.png`.
- **Investigation questions:** Which parents launch PowerShell on this host? Which starts are interactive and which automated? Which command lines repeat on a schedule?
- **Limitations:** Process creation only. PowerShell hosted inside another process, and script content, are invisible without script block logging (02, gap 2).
- **Status:** Not started, untested.

## KQL-04 — Suspicious command-line arguments

- **Objective:** Find command lines containing download, encoding, or policy-bypass patterns.
- **Query:**
  ```
  event.code: "1" and process.command_line: (*EncodedCommand* or *FromBase64String* or *DownloadString* or *Invoke-Expression* or *-nop* or *bypass* or *urlcache*)
  ```
- **Required ECS fields:** `process.command_line`, `process.name`, `process.parent.name`, `user.name`.
- **Raw fallback:** replace `process.command_line` with `winlog.event_data.CommandLine`.
- **Expected results:** A small set of matches; expect legitimate software installers and management scripts among them.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** What launched each match? Is the encoded payload decodable and what does it do? Does the same command line recur daily (likely tooling)?
- **Limitations:** Wildcards on keyword fields are case-sensitive, and PowerShell accepts any case and abbreviations (`-enc`, `-eNcO`), so this string list is easy to evade. Leading wildcards are slow on large indices.
- **Status:** Not started, untested.

## KQL-05 — Unusual process activity

- **Objective:** Find executables running from user-writable locations.
- **Query:**
  ```
  event.code: "1" and process.executable: (*\\AppData\\Local\\Temp\\* or *\\Users\\Public\\* or *\\Downloads\\* or *\\Windows\\Temp\\*)
  ```
- **Required ECS fields:** `process.executable`, `process.name`, `process.hash.sha256`, `process.parent.name`, `user.name`.
- **Raw fallback:** replace `process.executable` with `winlog.event_data.Image`.
- **Expected results:** Installers, updaters, and browser downloads. Build a table of `process.name` by count and look at the rare end.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** Which of these binaries are signed and by whom? Which appeared for the first time this week? What did each one spawn?
- **Limitations:** Path-based hunting misses anything dropped into a trusted directory and is noisy during software updates.
- **Status:** Not started, untested.

## KQL-06 — Network connections

- **Objective:** Review outbound connections recorded by Sysmon and the processes that made them.
- **Query:**
  ```
  event.provider: "Microsoft-Windows-Sysmon" and event.code: "3" and not destination.ip: (10.0.0.0/8 or 172.16.0.0/12 or 192.168.0.0/16 or 127.0.0.0/8)
  ```
- **Required ECS fields:** `destination.ip`, `destination.port`, `source.ip`, `process.name`, `process.executable`, `user.name`.
- **Raw fallback:**
  ```
  event.code: "3" and winlog.event_data.DestinationIp: * and not winlog.event_data.DestinationIp: (10.* or 192.168.* or 127.*)
  ```
- **Expected results:** Connections from the processes the Sysmon config chooses to log.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** Which processes talk to the internet? Any scripting engines or LOLBins among them? Any unusual destination ports?
- **Limitations:** The SwiftOnSecurity config logs network connections for a selected set of processes only, so absence of an event is not absence of a connection. CIDR syntax needs `destination.ip` mapped as `ip` (02, gap 3).
- **Status:** Not started, untested.

## KQL-07 — Linux authentication failures

- **Objective:** Find failed SSH and local authentication on the Linux endpoint.
- **Index pattern:** `filebeat-*`
- **Query:**
  ```
  event.dataset: "system.auth" and event.category: "authentication" and event.outcome: "failure"
  ```
- **Required ECS fields:** `event.dataset`, `event.category`, `event.outcome`, `user.name`, `source.ip`, `host.name`.
- **Raw fallback:**
  ```
  log.file.path: "/var/log/auth.log" and message: ("Failed password" or "authentication failure" or "Invalid user")
  ```
- **Expected results:** One document per failed attempt, with the source address for SSH.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** Are attempts aimed at real accounts or guessed names? One source or many? Is there a success from the same source afterwards?
- **Limitations:** Depends on the Filebeat system module and its ingest pipeline being applied through Logstash (02, gap 6).
- **Status:** Not started, untested.

## KQL-08 — Administrative account activity

- **Objective:** Track privileged logons and changes to accounts and groups.
- **Query:**
  ```
  event.provider: "Microsoft-Windows-Security-Auditing" and event.code: ("4672" or "4720" or "4722" or "4724" or "4728" or "4732" or "4756") and not winlog.event_data.SubjectUserName: (SYSTEM or *$)
  ```
- **Required ECS fields:** `event.code`, `event.action`, `user.name`, `host.name`; plus `winlog.event_data.SubjectUserName`, `winlog.event_data.TargetUserName`, `winlog.event_data.PrivilegeList`.
- **Raw fallback:** the query uses raw fields already.
- **Expected results:** 4672 for each privileged logon; 4720, 4722, 4724 for account creation, enablement, and password reset; 4728, 4732, 4756 for group membership additions.
- **Screenshot:** Pending (no dedicated file in the required inventory).
- **Investigation questions:** Who created or changed accounts, and was it expected? Which accounts receive special privileges at logon? Was anything added to Administrators?
- **Limitations:** 4672 fires for service accounts constantly. Account-management events need the Account Management audit category enabled.
- **Status:** Not started, untested.

---

## Event ID reference

| Event ID | Channel | Meaning |
|---|---|---|
| 1 | Sysmon | Process creation |
| 3 | Sysmon | Network connection |
| 4624 | Security | Successful logon |
| 4625 | Security | Failed logon |
| 4672 | Security | Special privileges assigned to new logon |
| 4720 / 4722 / 4724 | Security | Account created / enabled / password reset |
| 4728 / 4732 / 4756 | Security | Member added to a security group |
