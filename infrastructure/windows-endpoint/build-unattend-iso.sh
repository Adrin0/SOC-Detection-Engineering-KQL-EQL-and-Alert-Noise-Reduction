#!/usr/bin/env bash
# Run on hadron. Builds the answer ISO for VM 104 from this folder plus downloaded payloads.
#   build-unattend-iso.sh <payload-dir> <password-file> <out.iso>
# <payload-dir> must hold winlogbeat-9.5.6-windows-x86_64.zip (SHA-512 verified),
# Sysmon.zip and sysmonconfig-export.xml. <password-file> holds WIN_EP_PASSWORD=...
# The rendered autounattend.xml contains the password: the ISO is deleted after install.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
payload="$1"; pwfile="$2"; out="$3"
pw="$(grep '^WIN_EP_PASSWORD=' "$pwfile" | cut -d= -f2-)"
[[ "$pw" =~ ^[A-Za-z0-9]+$ ]] || { echo "password must be alphanumeric" >&2; exit 1; }
stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT
sed "s/@@PASSWORD@@/$pw/g" "$here/autounattend.template.xml" > "$stage/autounattend.xml"
cp "$here/bootstrap.ps1" "$here/winlogbeat.yml" "$stage/"
cp "$payload"/{winlogbeat-9.5.6-windows-x86_64.zip,Sysmon.zip,sysmonconfig-export.xml} "$stage/"
cp /root/claudecode/proxmox-soc-lab/infrastructure/elastic/ca.crt "$stage/ca.crt"
cp /root/.ssh/id_rsa.pub "$stage/administrators_authorized_keys"
genisoimage -quiet -J -r -V WINEP -o "$out" "$stage"
chmod 600 "$out"
echo "built $out"
