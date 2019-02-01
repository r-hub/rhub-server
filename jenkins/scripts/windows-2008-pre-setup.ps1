
## This must be run first, and then the machine must be rebooted
## to make WMF5.1 available.

$LocalTempDir = $env:TEMP;
$url = "https://go.microsoft.com/fwlink/?linkid=839523"
$dest = "$LocalTempDir\wmf51.zip"

(new-object System.Net.WebClient).DownloadFile($url, $dest)

function Expand-ZIPFile {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [string]$file,
        [Parameter(Position=1, Mandatory=1)]
        [string]$destination
    )

    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
	$shell.Namespace($destination).copyhere($item)
    }
}

$xdir = "$LocalTempDir\wmf51"
mkdir "$xdir"
Expand-ZIPFile "$dest" "$xdir"

powershell.exe -ExecutionPolicy Bypass -Command "$xdir\Install-WMF5.1.ps1 -AcceptEula"
