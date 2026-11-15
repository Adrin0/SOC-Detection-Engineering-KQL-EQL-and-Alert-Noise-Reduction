# DET-003 — Authentication Failures Followed by Success

| | |
|---|---|
| **Type** | EQL sequence rule |
| **Rule file** | [det-003-auth-failures-then-success.eql](../../detection-rules/eql/det-003-auth-failures-then-success.eql) |
| **Validation status** | Untested. Syntax not yet checked against Elasticsearch |
| **Last validated** | Never |

## 1. Description

Detects three failed logons followed by a successful logon for the same account on the same
host within five minutes.

## 2. Threat hypothesis

Password guessing that eventually succeeds is far more significant than guessing that fails.
The success after failures is the event worth an analyst's attention.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Credential Access | T1110.001 Password Guessing | Repeated failures for one account |
| Initial Access / Persistence | T1078 Valid Accounts | The sequence ends with a successful logon using that account |

A user who mistypes a password three times produces the same sequence.

## 4. Data sources

Windows Security Event IDs 4625 and 4624 in `winlogbeat-*`.

## 5. Required ECS fields

`event.category` (must contain `authentication`), `event.code`, `host.name`, `user.name`.
All depend on the Winlogbeat security module processor.

## 6. Logic

```
sequence by host.name, user.name with maxspan=5m
  [authentication where event.code == "4625"]
  [authentication where event.code == "4625"]
  [authentication where event.code == "4625"]
  [authentication where event.code == "4624"]
```

## 7. Expected benign behavior

A user mistyping a password several times, then succeeding. Caps Lock and keyboard-layout
errors.

## 8. Expected suspicious behavior

Failures from a network source followed by a network or remote-interactive success; a
success at an unusual hour; an account that does not normally log on to this host.

## 9. False-positive considerations

Human error is the main source. Logon type and source address separate most benign cases
from remote guessing.

## 10. Tuning strategy

Add `source.ip` as a join key for network logons; restrict the final event by logon type;
raise the number of failures. Each change narrows coverage, so retest after each.

## 11. Test procedure

See [06-purple-team-validation.md](../06-purple-team-validation.md).

## 12. Validation status

Untested. Events with no `user.name` are ignored by the join, so confirm the field is
populated on both event IDs before trusting a quiet result.

## 13. Screenshots

Pending: `07-eql-rule.png`, `08-eql-alert.png`, `11-detection-timeline.png`.

## 14. Results

None.

## 15. Change history

| Date | Change |
|---|---|
| 2026-11-15 | Draft created |
