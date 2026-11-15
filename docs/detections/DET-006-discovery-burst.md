# DET-006 — Discovery Command Burst on a Single Host

| | |
|---|---|
| **Type** | EQL sequence rule |
| **Rule file** | [det-006-discovery-burst.eql](../../detection-rules/eql/det-006-discovery-burst.eql) |
| **Validation status** | Untested. Syntax not yet checked against Elasticsearch |
| **Last validated** | Never |

## 1. Description

Detects `whoami`, then `net`, then a system or network information command run by the same
user on the same host within two minutes.

## 2. Threat hypothesis

After gaining a foothold, an operator orients: who am I, what accounts exist, where am I on
the network. Each command is routine; the ordered cluster in a short window is not.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Discovery | T1033 System Owner/User Discovery | `whoami.exe` |
| Discovery | T1087 Account Discovery, T1069 Permission Groups Discovery | `net.exe` / `net1.exe` (the specific technique depends on the arguments) |
| Discovery | T1016 System Network Configuration Discovery, T1082 System Information Discovery | `ipconfig.exe`, `systeminfo.exe`, `nltest.exe` |

## 4. Data sources

Sysmon Event ID 1 (process creation) in `winlogbeat-*`.

## 5. Required ECS fields

`event.category`, `event.type`, `process.name`, `host.name`, `user.name`; for triage
`process.command_line`, `process.parent.name`.

## 6. Logic

```
sequence by host.name, user.name with maxspan=2m
  [process where event.type == "start" and process.name : "whoami.exe"]
  [process where event.type == "start" and process.name : ("net.exe", "net1.exe")]
  [process where event.type == "start" and process.name : ("ipconfig.exe", "systeminfo.exe", "nltest.exe")]
```

## 7. Expected benign behavior

Administrators troubleshooting, help-desk scripts, inventory and login scripts.

## 8. Expected suspicious behavior

The burst run by a non-administrative user, from an unusual parent (an Office application, a
web server, a script host), or shortly after another alert on the same host.

## 9. False-positive considerations

The sequence is order-dependent, so an operator who runs the commands in a different order
is missed. That is a false-negative risk accepted in exchange for lower noise; record it.

## 10. Tuning strategy

Exclude known inventory scripts by parent command line. To widen coverage, replace the fixed
order with a threshold on distinct discovery process names.

## 11. Test procedure

See [06-purple-team-validation.md](../06-purple-team-validation.md).

## 12. Validation status

Untested.

## 13. Screenshots

Pending: `07-eql-rule.png`, `08-eql-alert.png`.

## 14. Results

None.

## 15. Change history

| Date | Change |
|---|---|
| 2026-11-15 | Draft created |
