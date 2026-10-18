# Dev helper: open a URL on the connected phone, force-stopped and cold, then
# capture a screenshot. Used to hand-verify marketplace links, which a status
# code cannot do for Shopee or TikTok Shop.
#
#   ./tool/device_open.ps1 -Label orashare -Url https://shopee.ph/... -Pkg com.shopee.ph
param(
  [Parameter(Mandatory = $true)][string]$Label,
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$Pkg = '',
  [int]$WaitSeconds = 14
)

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$out = "$env:TEMP\pp_$Label.png"

# A stale app keeps whatever page it was on and silently "passes" the check.
foreach ($p in @($Pkg, 'com.android.chrome')) {
  if ($p) { & $adb shell am force-stop $p | Out-Null }
}
Start-Sleep -Seconds 3

& $adb shell am start -a android.intent.action.VIEW -d $Url | Out-Null
Start-Sleep -Seconds $WaitSeconds

$focus = (& $adb shell dumpsys window | Select-String 'mCurrentFocus' | Select-Object -First 1).ToString().Trim()
& $adb shell screencap -p /sdcard/pp.png | Out-Null
& $adb pull /sdcard/pp.png $out | Out-Null

Write-Output "LABEL   $Label"
Write-Output "FOCUS   $focus"
Write-Output "SHOT    $out"