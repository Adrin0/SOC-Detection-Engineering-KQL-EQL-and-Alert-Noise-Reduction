# Detection Rules

Machine-readable rule logic. Explanations, test procedures, and status live in
[docs/detections/](../docs/detections/) and the exercise docs.

| Folder | Contents | Format |
|---|---|---|
| `kql/` | Hunting queries KQL-01 to KQL-08 | One query per `.kql` file, paste into Discover |
| `eql/` | Detections DET-002 to DET-006 | One query per `.eql` file |
| `threshold/` | DET-001 | Draft rule definition, JSON |

## Status of these files

**Every file here is an untested draft.** None has been run against the lab stack.

The `.draft.json` file is hand-written in the shape of an Elastic detection rule definition.
It is **not** an export from Kibana and deliberately has no `id` or `rule_id`, because none
exists until the rule is created. When a rule has been created and validated, export it from
Kibana (Security, Rules, Export) and commit the exported `.ndjson` beside the draft, then
record the validation date in its detection record.
