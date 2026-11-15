#!/usr/bin/env python3
"""Calculate detection metrics from a ground-truth record and labeled alerts.

Standard library only.

Inputs (CSV, headers as in templates/):
  ground truth : activity_id,start_utc,end_utc,host,account,class,event_count,description
                 class is "malicious_sim" or "benign"
  alerts       : alert_id,alert_time_utc,rule,host,account,label,activity_id,notes
                 label is "TP" or "FP"; a TP must name the malicious_sim activity it detected

Definitions:
  TP        alerts labeled TP
  FP        alerts labeled FP
  FN        malicious_sim activities that no TP alert references
  precision TP / (TP + FP)                       counted per alert
  recall    detected activities / all malicious_sim activities   counted per activity

Usage:
  python scripts/calc_metrics.py --ground-truth results/baseline/ground-truth.csv \
      --alerts results/baseline/alerts-labeled.csv [--json out.json]
"""
import argparse
import csv
import json
import sys

GT_COLS = {"activity_id", "class"}
ALERT_COLS = {"alert_id", "label", "activity_id"}
CLASSES = {"malicious_sim", "benign"}
LABELS = {"TP", "FP"}


def read_csv(path, required):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        missing = required - set(reader.fieldnames or [])
        if missing:
            sys.exit(f"{path}: missing column(s): {', '.join(sorted(missing))}")
        return [{k: (v or "").strip() for k, v in row.items() if k} for row in reader]


def compute(gt_rows, alert_rows):
    errors = []
    activities = {}
    for n, row in enumerate(gt_rows, start=2):
        aid, cls = row["activity_id"], row["class"]
        if not aid:
            errors.append(f"ground truth line {n}: empty activity_id")
        elif aid in activities:
            errors.append(f"ground truth line {n}: duplicate activity_id {aid}")
        elif cls not in CLASSES:
            errors.append(f"ground truth line {n}: class must be one of {sorted(CLASSES)}, got '{cls}'")
        else:
            activities[aid] = cls

    tp = fp = 0
    detected = set()
    for n, row in enumerate(alert_rows, start=2):
        label, aid = row["label"].upper(), row["activity_id"]
        if label not in LABELS:
            errors.append(f"alerts line {n}: label must be TP or FP, got '{row['label']}' (label every alert first)")
            continue
        if label == "TP":
            if activities.get(aid) != "malicious_sim":
                errors.append(f"alerts line {n}: TP must reference a malicious_sim activity_id, got '{aid}'")
                continue
            tp += 1
            detected.add(aid)
        else:
            if aid and aid not in activities:
                errors.append(f"alerts line {n}: unknown activity_id '{aid}'")
                continue
            fp += 1
    if errors:
        sys.exit("Cannot calculate metrics:\n  " + "\n  ".join(errors))

    malicious = sorted(a for a, c in activities.items() if c == "malicious_sim")
    missed = [a for a in malicious if a not in detected]
    return {
        "total_alerts": tp + fp,
        "true_positives": tp,
        "false_positives": fp,
        "false_negatives": len(missed),
        "malicious_activities": len(malicious),
        "detected_activities": len(detected),
        "benign_activities": sum(1 for c in activities.values() if c == "benign"),
        "precision": round(tp / (tp + fp), 4) if (tp + fp) else None,
        "recall": round(len(detected) / len(malicious), 4) if malicious else None,
        "missed_activity_ids": missed,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--ground-truth", required=True)
    ap.add_argument("--alerts", required=True)
    ap.add_argument("--json", help="also write the result to this JSON file")
    args = ap.parse_args()

    result = compute(read_csv(args.ground_truth, GT_COLS), read_csv(args.alerts, ALERT_COLS))

    def fmt(v):
        return "n/a (no data)" if v is None else str(v)

    print("| Metric | Value |")
    print("|---|---|")
    for key in ("total_alerts", "true_positives", "false_positives", "false_negatives",
                "malicious_activities", "detected_activities", "benign_activities",
                "precision", "recall"):
        print(f"| {key.replace('_', ' ').capitalize()} | {fmt(result[key])} |")
    if result["missed_activity_ids"]:
        print("\nMissed activities: " + ", ".join(result["missed_activity_ids"]))

    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
            fh.write("\n")


if __name__ == "__main__":
    main()
