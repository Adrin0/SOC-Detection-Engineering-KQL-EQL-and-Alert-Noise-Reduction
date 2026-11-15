# DET-NNN — Tuning Report: Title

| | |
|---|---|
| **Rule** | Link to the detection record |
| **Experiment stage** | E1 Baseline / E2 Threshold / E3 Exception / E4 Suppression / E5 Regression |
| **Run date (UTC)** | |
| **Ground truth file** | Path under `results/` |
| **Labeled alerts file** | Path under `results/` |

## Rule configuration

The exact query, threshold, grouping fields, interval, look-back, exceptions, and
suppression settings used for this run. State the single change from the previous stage.

## Test conditions

Time window, hosts and accounts involved, which ground-truth activities were run, and
anything unusual in the environment during the run.

## Measurements

| Measure | Value |
|---|---|
| Matching events | |
| Alerts | |
| True positives | |
| False positives | |
| False negatives | |
| Precision | |
| Recall | |

Values come from `scripts/calc_metrics.py`. Paste its output below.

```
output
```

## False-positive analysis

Group false positives by cause. For each group: count, cause, and whether it is safe to
exclude.

## False-negative analysis

For each missed activity: was the event missing, a field missing, or the logic too narrow?

## Decision

Keep, revert, or modify the change, and why. Note any coverage given up.

## Screenshots

Link files that exist. List pending ones by filename.
