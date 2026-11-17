# Changelog

Notable changes to this repository. Dates are ISO 8601.

## 2026-11-17

### Changed

- Network diagrams in the README and `docs/01-lab-architecture.md` redrawn for the current
  virtual infrastructure: Windows endpoint as VM 104 `soc-win-ep` (192.168.1.62) on `vmbr0`,
  plus VM 100 `mgmt`, VM 101 `opnsense` (stopped, planned isolation), ports, and addresses.
- Architecture status, network, and verification tables updated: VM 103 now reaches Logstash
  on 5044; Windows telemetry from VM 104 and its `clean-baseline` snapshot are not verified.

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
