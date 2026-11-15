# DET-001 — Results

**No experiment has been run. Every value below is pending.** The plan is in
[docs/05-alert-tuning.md](../../docs/05-alert-tuning.md).

Fill a stage in only from `scripts/calc_metrics.py` output on a ground-truth file and a
labeled alert file that are committed under `results/`. Do not edit earlier stages after the
fact; add a dated note instead.

## Summary

| Metric | Baseline | Tuned |
|---|---|---|
| Total alerts | Pending | Pending |
| True positives | Pending | Pending |
| False positives | Pending | Pending |
| False negatives | Pending | Pending |
| Precision | Pending | Pending |
| Recall | Pending | Pending |

## Per stage

| Stage | Run date | Rule configuration | Matching events | Alerts | TP | FP | FN | Precision | Recall | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|
| E1 Baseline | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| E2 Threshold adjustment | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| E3 Narrow exception | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| E4 Alert suppression | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| E5 Regression test | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending | Pending |

## Data files

| File | Purpose | Present |
|---|---|---|
| `results/baseline/ground-truth.csv` | Activities run for the baseline | No |
| `results/baseline/alerts-labeled.csv` | Baseline alerts, labeled | No |
| `results/tuned/ground-truth.csv` | Activities replayed against the tuned rule | No |
| `results/tuned/alerts-labeled.csv` | Tuned alerts, labeled | No |
