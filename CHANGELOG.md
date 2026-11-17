# Changelog

Notable changes to this repository. Dates are ISO 8601.

## 2026-11-15 (infrastructure)

### Added

- `infrastructure/`: the Elastic 9.5.6 Compose stack on VM 102 (copied from the existing
  deployment), a Logstash service and Beats pipeline, setup scripts for the Logstash writer
  user and Filebeat templates, Filebeat config for the new Linux endpoint VM 103, and the
  Winlogbeat 9.5.6 config and manual steps for the Windows endpoint.

### Changed

- Architecture, telemetry, and setup docs now describe the deployed lab (VMs 102 and 103,
  Elastic 9.5.6 with security on) instead of the LXC / 7.17 design.

## 2026-11-15

### Added

- Repository structure, README, project status, and `.gitignore`.
- Documentation: lab architecture, telemetry configuration, KQL fundamentals, EQL detection engineering, alert tuning, purple team validation, lessons learned, screenshot checklist.
- Eight draft KQL hunting queries (KQL-01 to KQL-08). Untested.
- Six draft detections (DET-001 threshold, DET-002 to DET-006 EQL) with detection records. Untested.
- Tuning experiment plan DET-001 with an empty results file.
- Templates for investigations, detection records, tuning reports, ground truth, and alert labels.
- Scripts: `check_docs.py`, `calc_metrics.py`, `Invoke-Det001AuthSimulation.ps1` (untested draft).

### Notes

- No exercises run, no screenshots captured, no results measured.
- License not yet selected.
