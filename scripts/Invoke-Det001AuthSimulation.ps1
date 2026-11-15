<#
.SYNOPSIS
    Generates failed logons (Security Event ID 4625) against a local synthetic test account
    on THIS computer and records the activity in a ground-truth CSV. For experiment DET-001.

.DESCRIPTION
    UNTESTED DRAFT. Review before running.

    Safety limits built in:
      - Targets the local computer only. There is no parameter for a remote host or domain.
      - The account must be an existing LOCAL account whose name starts with "det" followed
        by three digits and a hyphen (for example det001-sim). Create it yourself first.
      - Each attempt uses a random password, so no real credential is ever supplied.

    Prerequisites:
      - Failure auditing enabled:  auditpol /set /subcategory:"Logon" /failure:enable
      - Windows 11 locks an account after 10 failed attempts by default. Keep -Attempts
        below the lockout threshold (see: net accounts) or use one account per burst.

.EXAMPLE
    .\Invoke-Det001AuthSimulation.ps1 -Account det001-sim -Attempts 8 -DelaySeconds 5 `
        -ActivityId A01 -Class malicious_sim -Description "Rapid guessing" `
        -GroundTruthPath ..\results\baseline\ground-truth.csv
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^det\d{3}-[A-Za-z0-9-]+$')]
    [string]$Account,

    [ValidateRange(1, 30)]
    [int]$Attempts = 5,

    [ValidateRange(0, 3600)]
    [int]$DelaySeconds = 2,

    [Parameter(Mandatory = $true)]
    [string]$ActivityId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('malicious_sim', 'benign')]
    [string]$Class,

    [Parameter(Mandatory = $true)]
    [string]$GroundTruthPath,

    [string]$Description = ''
)

$ErrorActionPreference = 'Stop'

if (-not (Get-LocalUser -Name $Account -ErrorAction SilentlyContinue)) {
    throw "Local account '$Account' does not exist. Create a dedicated test account first."
}

Add-Type -Namespace Det001 -Name Native -MemberDefinition @'
[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern bool LogonUser(string user, string domain, string pass, int logonType, int provider, out IntPtr token);
[DllImport("kernel32.dll")]
public static extern bool CloseHandle(IntPtr handle);
'@

if (-not $PSCmdlet.ShouldProcess("$env:COMPUTERNAME\$Account", "Generate $Attempts failed logon(s)")) {
    return
}

$start = (Get-Date).ToUniversalTime()
$failed = 0
for ($i = 1; $i -le $Attempts; $i++) {
    $wrong = [guid]::NewGuid().ToString('N')
    $handle = [IntPtr]::Zero
    # Logon type 3 (network), default provider, local computer only (".")
    $ok = [Det001.Native]::LogonUser($Account, '.', $wrong, 3, 0, [ref]$handle)
    if ($ok) {
        [void][Det001.Native]::CloseHandle($handle)
        Write-Warning "Attempt $i unexpectedly succeeded."
    }
    else {
        $failed++
    }
    Write-Host ("Attempt {0}/{1} at {2:HH:mm:ss}Z" -f $i, $Attempts, (Get-Date).ToUniversalTime())
    if ($i -lt $Attempts -and $DelaySeconds -gt 0) { Start-Sleep -Seconds $DelaySeconds }
}
$end = (Get-Date).ToUniversalTime()

$row = [pscustomobject]@{
    activity_id = $ActivityId
    start_utc   = $start.ToString('yyyy-MM-ddTHH:mm:ssZ')
    end_utc     = $end.ToString('yyyy-MM-ddTHH:mm:ssZ')
    host        = $env:COMPUTERNAME
    account     = $Account
    class       = $Class
    event_count = $failed
    description = $Description
}
$parent = Split-Path -Parent $GroundTruthPath
if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
$row | Export-Csv -Path $GroundTruthPath -Append -NoTypeInformation -Encoding UTF8

Write-Host "Recorded activity $ActivityId ($failed failed logons) in $GroundTruthPath"
Write-Host "Review the host column before committing; replace the hostname if it should not be published."
