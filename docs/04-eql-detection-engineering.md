# 04 — EQL Detection Engineering

Five behavioral detections written in EQL. **All rules are untested**: syntax follows the
Elasticsearch 7.17 EQL reference but none has been run, because the lab stack was unreachable
when they were written (2026-11-15).

## How EQL differs from KQL

KQL answers "which documents match this filter". EQL answers "did these events happen, in
this order, to the same entity, within this time". An EQL query has the form:

```
<event category> where <condition>
```

The event category is matched against the `event.category` field, so `process where ...`
only considers documents whose `event.category` contains `process`. If that field is absent
(see [02](02-telemetry-configuration.md), gap 1) the query returns nothing and looks like a
working rule with nothing to detect.

## How sequence matching works

```
sequence by host.name, user.name with maxspan=5m
  [authentication where event.code == "4625"]
  [authentication where event.code == "4624"]
```

- Each bracketed item is an event query. A match needs one event per item, **in timestamp order**.
- `by` fields are join keys. All events in one match must share the same values, which is what ties a sequence to one host, user, or process. A join key can differ per item (`by process.entity_id` on one, `by process.parent.entity_id` on the next) to follow parent to child.
- `maxspan` bounds the time from the first event to the last.
- Events do not need to be adjacent. Unrelated events in between do not break a match.
- `until [ ... ]` ends a pending sequence when a terminating event arrives.
- Events that lack a join-key field are ignored, so a missing field silently removes coverage.

Operators used here: `==` is case-sensitive equality, `:` is case-insensitive and accepts
wildcards and lists, `cidrMatch()` tests an IP field against CIDR ranges.

## Validating a rule without the detection engine

EQL can be checked from Kibana Dev Tools before a detection rule exists:

```http
GET winlogbeat-*/_eql/search
{
  "query": "process where event.type == \"start\" and process.name : \"powershell.exe\""
}
```

A syntax or field error comes back as a `verification_exception` naming the problem.

## Exercises

| ID | Exercise | Rule file | Record | Status |
|---|---|---|---|---|
| DET-002 | Office application spawning PowerShell | [det-002](../detection-rules/eql/det-002-office-spawns-shell.eql) | [DET-002](detections/DET-002-office-spawns-shell.md) | Untested |
| DET-003 | Authentication failures followed by success | [det-003](../detection-rules/eql/det-003-auth-failures-then-success.eql) | [DET-003](detections/DET-003-auth-failures-then-success.md) | Untested |
| DET-004 | PowerShell execution followed by network activity | [det-004](../detection-rules/eql/det-004-powershell-then-network.eql) | [DET-004](detections/DET-004-powershell-then-network.md) | Untested |
| DET-005 | Suspicious process ancestry | [det-005](../detection-rules/eql/det-005-script-host-spawns-shell.eql) | [DET-005](detections/DET-005-script-host-spawns-shell.md) | Untested |
| DET-006 | Correlated activity on a single host | [det-006](../detection-rules/eql/det-006-discovery-burst.eql) | [DET-006](detections/DET-006-discovery-burst.md) | Untested |

### DET-002 — Office application spawning PowerShell

```
process where event.type == "start" and
  process.parent.name : ("winword.exe", "excel.exe", "powerpnt.exe", "outlook.exe", "msaccess.exe") and
  process.name : ("powershell.exe", "pwsh.exe", "cmd.exe", "wscript.exe", "cscript.exe", "mshta.exe")
```

A single-event rule: parent and child are both on the process-creation event.

### DET-003 — Authentication failures followed by success

```
sequence by host.name, user.name with maxspan=5m
  [authentication where event.code == "4625"]
  [authentication where event.code == "4625"]
  [authentication where event.code == "4625"]
  [authentication where event.code == "4624"]
```

Three failures then a success for the same account on the same host inside five minutes.

### DET-004 — PowerShell execution followed by network activity

```
sequence by host.name, process.entity_id with maxspan=2m
  [process where event.type == "start" and process.name : ("powershell.exe", "pwsh.exe")]
  [network where process.name : ("powershell.exe", "pwsh.exe") and
    not cidrMatch(destination.ip, "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8", "169.254.0.0/16", "::1/128", "fe80::/10")]
```

Joining on `process.entity_id` ties the connection to the same PowerShell instance.

### DET-005 — Suspicious process ancestry

```
process where event.type == "start" and
  process.parent.name : ("mshta.exe", "wscript.exe", "cscript.exe", "regsvr32.exe", "rundll32.exe") and
  process.name : ("powershell.exe", "pwsh.exe", "cmd.exe")
```

A script host or signed proxy binary launching a shell.

### DET-006 — Correlated activity on a single host

```
sequence by host.name, user.name with maxspan=2m
  [process where event.type == "start" and process.name : "whoami.exe"]
  [process where event.type == "start" and process.name : ("net.exe", "net1.exe")]
  [process where event.type == "start" and process.name : ("ipconfig.exe", "systeminfo.exe", "nltest.exe")]
```

Three different discovery commands by one user on one host within two minutes. Any one of
them alone is routine; the ordered cluster is the signal.

## Screenshots

Pending: `screenshots/eql/07-eql-rule.png` and `screenshots/eql/08-eql-alert.png`. See the
[screenshot checklist](screenshot-checklist.md).
