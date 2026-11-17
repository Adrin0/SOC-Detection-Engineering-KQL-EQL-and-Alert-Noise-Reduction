# Windows 11 endpoint: VM 104 `soc-win-ep`

Since 2026-11-17 the Windows endpoint is a Proxmox VM rather than the physical Windows PC, so
exercises can be reverted to a clean snapshot. It is built unattended from the Windows 11 ISO.
The physical PC is no longer part of the lab. Its old Winlogbeat 7.17.26 still runs and fails
to connect; uninstalling it is up to the owner.

| Item | Value |
|---|---|
| VM | 104 `soc-win-ep`, q35 + OVMF (Secure Boot keys enrolled), vTPM 2.0, `cpu: host` |
| Resources | 2 vCPU, 4 GiB (no balloon), 64 GB SATA disk on `local-lvm` |
| Network | `vmbr0` e1000e, static 192.168.1.62/24, gateway and DNS 192.168.1.1 |
| OS | Windows 11 Pro (image index 6), generic install key, **not activated** |
| Account | Local admin `soc`. Password in `proxmox-soc-lab/secrets/win-ep.env` |
| Management | OpenSSH Server, key-only (hadron's root key), port 22 open to 192.168.1.56 and .45 only |
| Telemetry | Sysmon (SwiftOnSecurity config, commit `1836897`), Winlogbeat 9.5.6 → Logstash 192.168.1.60:5044 |
| Auditing | Logon and Credential Validation success+failure, Process Creation success, PowerShell script block logging |
| Power | On demand: `onboot 0` (ADR-003). Snapshot `clean-baseline` |

Hardware is SATA and e1000e so Windows Setup needs no virtio drivers.

## Files

| File | Purpose |
|---|---|
| `autounattend.template.xml` | Answer file: wipes disk 0 (GPT), installs Pro, creates `soc`, skips OOBE, runs `bootstrap.ps1` at first logon. `@@PASSWORD@@` is filled in at build time |
| `bootstrap.ps1` | First-logon setup: static IP, power, OpenSSH, firewall rules, audit policy, Sysmon (only if Microsoft-signed), Winlogbeat service. No secrets. Log: `C:\Windows\Temp\soc-bootstrap.log` |
| `build-unattend-iso.sh` | Renders the answer file and packs it with the payloads into an answer ISO (volume `WINEP`) |
| `winlogbeat.yml` | Winlogbeat config (Sysmon, Security, PowerShell, System, Application) |

## Rebuild from scratch (on hadron)

1. Download the payloads into an empty directory and verify them:
   `winlogbeat-9.5.6-windows-x86_64.zip` with its `.sha512` from artifacts.elastic.co
   (`sha512sum -c`), `Sysmon.zip` from download.sysinternals.com, and `sysmonconfig-export.xml`
   from SwiftOnSecurity/sysmon-config at a pinned commit. `bootstrap.ps1` refuses to install
   Sysmon unless its Authenticode signature is valid and from Microsoft.
2. `build-unattend-iso.sh <payload-dir> ../../../proxmox-soc-lab/secrets/win-ep.env /var/lib/vz/template/iso/win-ep-unattend.iso`
3. Create and start the VM:
   ```bash
   qm create 104 --name soc-win-ep --machine q35 --bios ovmf --ostype win11 --cpu host --cores 2 \
     --memory 4096 --balloon 0 --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 \
     --tpmstate0 local-lvm:1,version=v2.0 --sata0 local-lvm:64,discard=on,ssd=1 \
     --net0 e1000e,bridge=vmbr0,firewall=1 --vga std --onboot 0 \
     --ide2 local:iso/Windows11_Client_x64_en-us_26300_9457.iso,media=cdrom \
     --ide0 local:iso/win-ep-unattend.iso,media=cdrom --boot 'order=sata0;ide2'
   qm start 104   # then press Enter a few times for "Press any key to boot from CD"
   ```
   Only send keys in the first few seconds. Once Setup is running, Enter would hit its Cancel button.
4. Wait for `C:\Windows\Temp\soc-bootstrap.done` (about 30 min):
   `ssh soc@192.168.1.62 'Test-Path C:\Windows\Temp\soc-bootstrap.done'`
5. Load the Winlogbeat index template and ingest pipelines once. On VM 102, first temporarily allow
   9200 from 192.168.1.62 in `soc-guard.nft`. Then run this from hadron. The credentials go on the
   command line and are not saved on Windows:
   ```bash
   P=$(grep ^ELASTIC_PASSWORD= proxmox-soc-lab/secrets/elastic.env | cut -d= -f2)
   ssh soc@192.168.1.62 "cd 'C:\Program Files\Winlogbeat'; .\winlogbeat.exe setup --index-management --pipelines -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=[\"https://192.168.1.60:9200\"]' -E 'output.elasticsearch.ssl.certificate_authorities=[\"C:\Program Files\Winlogbeat\ca.crt\"]' -E output.elasticsearch.username=elastic -E output.elasticsearch.password=$P"
   ```
   Then remove the temporary 9200 rule.
6. `.\winlogbeat.exe test config`, `.\winlogbeat.exe test output`, `Start-Service winlogbeat`.
7. Eject both ISOs, delete `win-ep-unattend.iso` (it holds the password), shut down, and take
   `qm snapshot 104 clean-baseline`.

## Revert after an exercise

```bash
qm rollback 104 clean-baseline && qm start 104
```

## Verify

In Kibana Discover on `winlogbeat-*`, `event.code: "1"` should return Sysmon process events with
`process.name` and `event.category: "process"` populated. If those fields are missing, the routing
pipeline did not run: check step 5.
