# 06 — Purple Team Validation

How each detection is exercised with controlled, benign simulations. **No simulation has been
run yet.**

## Rules of engagement

- Simulations run only on the lab's own Windows and Linux endpoints.
- The Windows endpoint is a physical host with no snapshot to revert to, so every simulation uses harmless commands: no real payloads, no persistence, no credential dumping, no security tooling disabled.
- Record each run in the ground-truth CSV (time, host, account, what was done) before checking for alerts.
- A simulation shows that a rule matches a pattern. It does not show the rule would catch a real adversary using a different technique.

## Validation loop

1. State the expected result: which rule should fire, on which fields.
2. Run the simulation and record it.
3. Confirm the raw events arrived (Discover) before looking at alerts.
4. Check for the alert. If none, find out whether the event was missing, the field was missing, or the logic was wrong.
5. Run the benign counterpart and confirm it does **not** alert.
6. Update the detection record and the project status.

## Planned simulations

| Detection | Simulation (benign) | Benign counterpart | Status |
|---|---|---|---|
| DET-001 | `scripts/Invoke-Det001AuthSimulation.ps1` against a `det001-` account | One mistyped password then success | Not run |
| DET-002 | From an Office macro or the Office "Shell" object in a test document, start `powershell.exe -Command whoami`. Requires Office on the endpoint | Open a document with no macro | Not run |
| DET-003 | `runas /user:det001-sim cmd` with three wrong passwords, then the correct one | A single successful logon | Not run |
| DET-004 | `powershell -Command "Invoke-WebRequest https://example.com -UseBasicParsing"` | `powershell -Command Get-Date` | Not run |
| DET-005 | `mshta vbscript:Execute("CreateObject(""WScript.Shell"").Run ""cmd /c whoami"", 0:close")` | Run `cmd /c whoami` directly | Not run |
| DET-006 | In one console: `whoami`, `net user`, `ipconfig /all` within two minutes | `ipconfig` alone | Not run |
| KQL-07 | Three SSH logins with a wrong password to the lab Linux endpoint from the lab workstation | One successful SSH login | Not run |

The DET-005 one-liner is a commonly used test string for this technique and may be blocked or
flagged by Microsoft Defender. That is an acceptable outcome; record it.

## Coverage summary

| Detection | Simulated | Alert observed | Benign counterpart quiet | Last validated |
|---|---|---|---|---|
| DET-001 | Pending | Pending | Pending | Never |
| DET-002 | Pending | Pending | Pending | Never |
| DET-003 | Pending | Pending | Pending | Never |
| DET-004 | Pending | Pending | Pending | Never |
| DET-005 | Pending | Pending | Pending | Never |
| DET-006 | Pending | Pending | Pending | Never |
