# DET-005 — Script Host or Proxy Binary Spawning a Shell

| | |
|---|---|
| **Type** | EQL event rule |
| **Rule file** | [det-005-script-host-spawns-shell.eql](../../detection-rules/eql/det-005-script-host-spawns-shell.eql) |
| **Validation status** | Untested. Syntax not yet checked against Elasticsearch |
| **Last validated** | Never |

## 1. Description

Detects `mshta.exe`, `wscript.exe`, `cscript.exe`, `regsvr32.exe`, or `rundll32.exe`
starting PowerShell or `cmd.exe`.

## 2. Threat hypothesis

Adversaries run code through signed Windows binaries to avoid application control, then
launch a shell from them. The ancestry is unusual even when each binary is legitimate.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Defense Evasion | T1218 System Binary Proxy Execution (T1218.005 Mshta, T1218.010 Regsvr32, T1218.011 Rundll32) | The parent is a signed binary commonly used as an execution proxy |
| Execution | T1059.005 Visual Basic, T1059.007 JavaScript | `wscript.exe` and `cscript.exe` parents indicate a script was run |
| Execution | T1059.001 PowerShell, T1059.003 Windows Command Shell | The child is a command interpreter |

Which sub-technique applies depends on the parent in the specific alert.

## 4. Data sources

Sysmon Event ID 1 (process creation) in `winlogbeat-*`.

## 5. Required ECS fields

`event.category`, `event.type`, `process.name`, `process.parent.name`; for triage
`process.command_line`, `process.parent.command_line`, `user.name`.

## 6. Logic

```
process where event.type == "start" and
  process.parent.name : ("mshta.exe", "wscript.exe", "cscript.exe", "regsvr32.exe", "rundll32.exe") and
  process.name : ("powershell.exe", "pwsh.exe", "cmd.exe")
```

## 7. Expected benign behavior

Logon scripts, software installers, and vendor support tools written in VBScript that call
`cmd.exe`. `rundll32.exe` launching a shell from Control Panel or shell extensions.

## 8. Expected suspicious behavior

A parent command line containing a URL, inline script, or a file in a user-writable path.

## 9. False-positive considerations

Legacy logon scripts are the usual source and are stable, so they can be excluded by exact
script path.

## 10. Tuning strategy

Exclude verified parent command lines. Consider splitting `rundll32.exe` into its own rule
if it dominates the noise.

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
