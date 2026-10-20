param([switch]$ConfirmLive)
if(-not $ConfirmLive){throw 'Pass -ConfirmLive to change the selected Lightroom photo'}
$ErrorActionPreference='Stop'
$plugin=Join-Path (Split-Path $PSScriptRoot -Parent) 'PhotobridgeIA.lrplugin'
$client=Join-Path $plugin 'PhotobridgeIAClient.ps1'
$bridge=Join-Path $plugin 'bridge'
function RunAction([string]$action,[string]$options=''){
 if($options){& $client -Action $action -Options $options | Out-Null}
 else{& $client -Action $action | Out-Null}
}
function ReadState {
 $s=@{}
 foreach($line in (Get-Content (Join-Path $bridge 'state.txt'))){
  $kv=$line.Split([char]'=',2)
  if($kv.Count -eq 2){$s[$kv[0]]=$kv[1]}
 }
 return $s
}
function ReadSettings {
 RunAction inspect_full
 $file=Get-ChildItem $bridge -Filter 'settings-inspect_full-*.txt' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if(-not $file){throw 'No develop settings readback'}
 return @(Get-Content $file.FullName | Sort-Object)
}
RunAction inspect
$before=ReadState
if($before.ConvertToGrayscale -ne 'false'){throw 'Select a color photo'}
$old=ReadSettings
if(-not (Test-Path -LiteralPath $before.file)){throw 'RAW file inaccessible'}
$sha=(Get-FileHash -LiteralPath $before.file -Algorithm SHA256).Hash
try{
 RunAction treatment 'value=grayscale'
 RunAction inspect
 $bw=ReadState
 if($bw.photo_id -ne $before.photo_id -or $bw.ConvertToGrayscale -ne 'true'){throw 'B&W not confirmed'}
 Write-Output 'BLACK_WHITE_VERIFIED=true'
}finally{
 RunAction inspect
 $current=ReadState
 if($current.photo_id -eq $before.photo_id -and $current.ConvertToGrayscale -eq 'true'){
  RunAction treatment 'value=color'
 }
}
RunAction inspect
$after=ReadState
$new=ReadSettings
$rawUnchanged=($sha -eq (Get-FileHash -LiteralPath $before.file -Algorithm SHA256).Hash)
$diff=@(Compare-Object $old $new)
$restored=($after.photo_id -eq $before.photo_id -and $after.ConvertToGrayscale -eq 'false' -and $rawUnchanged -and $diff.Count -eq 0)
Write-Output ('RAW_HASH_UNCHANGED='+$rawUnchanged)
Write-Output ('DEVELOP_SCALAR_DIFF_COUNT='+$diff.Count)
Write-Output ('RESTORED='+$restored)
if(-not $restored){throw 'Develop state not fully restored'}
