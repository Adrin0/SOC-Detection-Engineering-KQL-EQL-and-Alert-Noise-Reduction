# Datasets

| Folder | Contents | Committed |
|---|---|---|
| `synthetic/` | Small, hand-reviewed synthetic or fully sanitized samples used to explain a detection | Yes |
| `raw/` | Raw exports from the lab | No, git-ignored |

Currently empty. No telemetry has been exported.

## Rules

- Real endpoint logs are not committed. They contain usernames, hostnames, addresses, and command lines from a personal machine.
- A sample may be committed only after every account name, hostname, address, SID, and path has been replaced, and the file says at the top that it is sanitized or synthetic.
- Synthetic data is for illustrating field shapes and for testing scripts. It is never used as evidence that a detection works, and no metric in this repository is calculated from it.
- Ground-truth and labeled-alert CSVs for experiments belong in `results/`, not here.
