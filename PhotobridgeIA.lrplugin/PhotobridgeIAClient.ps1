param(
 [Parameter(Mandatory=$true)]
 [ValidateSet('inspect','inspect_full','capabilities','presets_list','apply','treatment','preset_apply','white_balance','crop','rotate','develop_get','develop_set','panel_show','tool_select','mask_list','mask_create','mask_invert','spot_count','curve_get','curve_set','snapshot','auto_tone','auto_wb')]
 [string]$Action,
 [string]$Options=''
)
$ErrorActionPreference='Stop'
$root=Join-Path $PSScriptRoot 'bridge'
$status=Join-Path $root 'status.txt'
$heartbeat=Join-Path $root 'heartbeat.txt'
function Bridge-Ready {
 if(-not (Test-Path $status) -or -not (Test-Path $heartbeat)){return $false}
 if((Get-Content $status -Raw) -notmatch 'version=0.6-integration-beta'){return $false}
 return ((Get-Date)-(Get-Item $heartbeat).LastWriteTime).TotalSeconds -le 12
}
if(-not (Bridge-Ready)){
 $lr=Get-Process Lightroom -ErrorAction SilentlyContinue | Select-Object -First 1
 if(-not $lr){throw 'Lightroom Classic no esta abierto'}
 $returnToDevelop=($lr.MainWindowTitle -match 'Revelar|Develop')
 $native=@'
using System;
using System.Runtime.InteropServices;
public static class PBAutoWake {
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd,uint message,IntPtr w,IntPtr l);
}
'@
 Add-Type -TypeDefinition $native
 if(-not [PBAutoWake]::PostMessage($lr.MainWindowHandle,0x111,[IntPtr]40049,[IntPtr]::Zero)){
  throw 'No se pudo abrir Biblioteca para iniciar el puente'
 }
 for($attempt=0;$attempt -lt 48;$attempt++){
  Start-Sleep -Milliseconds 250
  if(Bridge-Ready){break}
 }
 if($returnToDevelop){[PBAutoWake]::PostMessage($lr.MainWindowHandle,0x111,[IntPtr]40050,[IntPtr]::Zero)|Out-Null}
}
if(-not (Bridge-Ready)){throw 'PhotobridgeIA no responde. Comprobar que este activado en el Gestor de plugins'}
function Read-State {
 $hash=@{}
 foreach($line in (Get-Content (Join-Path $root 'state.txt'))){
  $v=$line.Split([char]'=',2)
  if($v.Length -eq 2){$hash[$v[0]]=$v[1]}
 }
 return $hash
}
function Send-Command([string]$verb,[string[]]$extras){
 $id=$verb+'-'+[guid]::NewGuid().ToString('N').Substring(0,14)
 $lines=New-Object 'System.Collections.Generic.List[string]'
 $lines.Add('id='+$id)
 $lines.Add('action='+$verb)
 foreach($extra in $extras){$lines.Add($extra)}
 $cmd=Join-Path $root 'command.txt'
 if(Test-Path $cmd){throw 'Otra solicitud esta pendiente'}
 $tmp=Join-Path $root ('pending-'+$id+'.tmp')
 [IO.File]::WriteAllLines($tmp,$lines,[Text.UTF8Encoding]::new($false))
 [IO.File]::Move($tmp,$cmd)
 for($i=0;$i -lt 120;$i++){
  Start-Sleep -Milliseconds 250
  $r=Get-Content (Join-Path $root 'response.txt') -Raw -ErrorAction SilentlyContinue
  if($r -and $r -match ('(?m)^id='+[regex]::Escape($id)+'\r?$')){
   if($r -notmatch '(?m)^status=ok\r?$'){throw ('Lightroom rechazo la orden: '+($r -replace '[\r\n]','; '))}
   return $id
  }
 }
 throw 'No hubo respuesta del plugin en 30 segundos'
}
$mutex=New-Object System.Threading.Mutex($false,'Local\PhotobridgeIACommandLock')
if(-not $mutex.WaitOne(0)){throw 'Otra solicitud PhotobridgeIA sigue activa'}
try {
 $extras=@()
 if($Action -ne 'inspect'){
  [void](Send-Command 'inspect' @())
  $state=Read-State
  if(-not $state.photo_id -or -not $state.catalog){throw 'Lightroom no identifico la foto seleccionada'}
  $extras+=('photo_id='+$state.photo_id)
  $extras+=('catalog='+$state.catalog)
 }
 if($Options.Trim()){
  foreach($entry in ($Options -split ';')){
   $kv=$entry.Split([char]'=',2)
   if($kv.Length -ne 2 -or $kv[0] -notmatch '^[A-Za-z][A-Za-z0-9_]{0,60}$' -or $kv[0] -in @('id','action','photo_id','catalog') -or $kv[1] -match '[\r\n]' -or $kv[1].Length -gt 300){throw ('Opcion no valida: '+$entry)}
   $extras+=($kv[0]+'='+$kv[1])
  }
 }
 $id=Send-Command $Action $extras
 $prefix=@{inspect_full='settings';presets_list='presets';capabilities='capabilities';develop_get='develop';mask_list='masks';mask_create='masks';mask_invert='masks';spot_count='spots';tool_select='tool';curve_get='curves';curve_set='curves';snapshot='snapshot';auto_tone='auto';auto_wb='auto'}[$Action]
 Write-Output ('OK action='+$Action+' id='+$id)
 if($Action -eq 'inspect'){Get-Content (Join-Path $root 'state.txt')}
 elseif($prefix){$file=Join-Path $root ($prefix+'-'+$id+'.txt');if(Test-Path $file){Get-Content $file}}
 else {Write-Output 'Ajustes aplicados en Lightroom Classic'}
}
finally { $mutex.ReleaseMutex();$mutex.Dispose() }

