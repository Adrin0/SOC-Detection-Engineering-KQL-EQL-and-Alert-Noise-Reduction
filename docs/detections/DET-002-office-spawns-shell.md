# DET-002 — Office Application Spawning a Shell or Script Host

| | |
|---|---|
| **Type** | EQL event rule |
| **Rule file** | [det-002-office-spawns-shell.eql](../../detection-rules/eql/det-002-office-spawns-shell.eql) |
| **Validation status** | Untested. Syntax not yet checked against Elasticsearch |
| **Last validated** | Never |

## 1. Description

Detects Word, Excel, PowerPoint, Outlook, or Access starting PowerShell, `cmd.exe`, or a
Windows script host.

## 2. Threat hypothesis

A malicious document delivered by email runs a macro or exploit that launches a shell to
download or execute the next stage. Office applications have little legitimate reason to
start a shell.

## 3. MITRE ATT&CK mapping

| Tactic | Technique | Justification |
|---|---|---|
| Initial Access | T1566.001 Spearphishing Attachment | The parent is a document-handling application |
| Execution | T1204.002 User Execution: Malicious File | Execution follows a user opening a file |
| Execution | T1059.001 PowerShell, T1059.003 Windows Command Shell | The child process is a command interpreter |

The rule observes a parent-child relationship. How the document arrived is an inference the
analyst has to confirm.

## 4. Data sources

Sysmon Event ID 1 (process creation) in `winlogbeat-*`.

## 5. Required ECS fields

`event.category`, `event.type`, `process.name`, `process.parent.name`; for triage
`process.command_line`, `process.parent.command_line`, `user.name`, `host.name`.

## 6. Logic

```
process where event.type == "start" and
  process.parent.name : ("winword.exe", "excel.exe", "powerpnt.exe", "outlook.exe", "msaccess.exe") and
  process.name : ("powershell.exe", "pwsh.exe", "cmd.exe", "wscript.exe", "cscript.exe", "mshta.exe")
```

## 7. Expected benign behavior

Office add-ins and some document-management or accounting plugins that shell out. Internal
macros written by the organization.

## 8. Expected suspicious behavior

A child command line that downloads content, is encoded, or runs from a temporary directory.

## 9. False-positive considerations

Known add-ins. Identify them by the child's full command line, not just the parent name.

## 10. Tuning strategy

Exclude specific verified command lines. Do not exclude a whole parent application.

## 11. Test procedure

See [06-purple-team-validation.md](../06-purple-team-validation.md). Requires Office on the
Windows endpoint; if it is not installed this detection cannot be validated in this lab.

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
