# DET-001 — Repeated Windows Authentication Failures

| | |
|---|---|
| **Type** | Threshold rule (KQL) |
| **Rule file** | [det-001-auth-failure-threshold.draft.json](../../detection-rules/threshold/det-001-auth-failure-threshold.draft.json) |
| **Validation status** | Untested draft. Not created in Kibana, never fired |
| **Last validated** | Never |

## 1. Description

Alerts when one account on one host accumulates several failed logons in a short window.

## 2. Threat hypothesis

An adversary guessing a password for a known account produces a burst of failed logons
(Event ID 4625) that a legitimate user rarely does.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Credential Access (TA0006) | T1110 Brute Force, T1110.001 Password Guessing | Repeated failed authentication for the same account is the observable side effect of guessing |

The rule observes failed logons. It does not establish intent; a stale saved credential
produces the same pattern.

## 4. Data sources

Windows Security event log, Event ID 4625, shipped by Winlogbeat to `winlogbeat-*`.
Requires failure auditing on the Logon subcategory.

## 5. Required ECS fields

`event.code`, `event.provider`, `host.name`, `user.name` (needs the Winlogbeat security
module processor; raw equivalent `winlog.event_data.TargetUserName`).

## 6. Logic

```
event.provider: "Microsoft-Windows-Security-Auditing" and event.code: "4625"
```

Threshold: count of matching events grouped by `host.name` and `user.name` at or above the
configured value within the rule's look-back window. Starting values for the experiment are
in [05-alert-tuning.md](../05-alert-tuning.md).

## 7. Expected benign behavior

One or two failures before a success (mistyped password). Repeating failures at a fixed
interval from a service, scheduled task, or mapped drive holding an old password.

## 8. Expected suspicious behavior

Many failures for one account in a short period, particularly with `SubStatus` indicating a
bad password for a valid account, or failures across many account names from one source.

## 9. False-positive considerations

Password changes that leave stale credentials on other devices; users returning from leave;
misconfigured services. These are persistent and predictable, which makes them suitable for
narrow exceptions.

## 10. Tuning strategy

Covered by experiment DET-001: adjust count and grouping, add a narrow exception for a
verified-benign source, evaluate alert suppression, then regression-test.

## 11. Test procedure

1. Confirm 4625 events are produced and indexed (KQL-01).
2. Create a local test account named `det001-sim`.
3. Run `scripts/Invoke-Det001AuthSimulation.ps1` for each planned activity; it appends to the ground-truth CSV.
4. Export and label the alerts, then run `scripts/calc_metrics.py`.

## 12. Validation status

Untested. Blocked on stack reachability and detection engine prerequisites
([known issues](../../PROJECT_STATUS.md#known-issues)).

## 13. Screenshots

Pending: `09-baseline-alerts.png`, `10-tuned-alerts.png`, `12-detection-metrics.png`.

## 14. Results

None. See [results/metrics/DET-001-results.md](../../results/metrics/DET-001-results.md).

## 15. Change history

| Date | Change |
|---|---|
| 2026-11-15 | Draft created |
