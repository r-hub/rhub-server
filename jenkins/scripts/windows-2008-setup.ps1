
## Otherwise PowerShell defaults to older TLS, which is not supported
## by many web sites any more
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$LocalTempDir = $env:TEMP

Function Download {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [string]$Url,
        [Parameter(Position=1, Mandatory=1)]
        [string]$Dest
    )

    (new-object System.Net.WebClient).DownloadFile($Url, $Dest)
}

Function Set-Timezone {
    tzutil /g
    tzutil /s "GMT Standard Time"
    tzutil /g
}

Function Install-Git {
    $giturl = "https://github.com/git-for-windows/git/releases/download/v2.20.1.windows.1/Git-2.20.1-64-bit.exe"
    $gitfile = "$LocalTempDir\git-install.exe"

    Download "$giturl" "$gitfile"

    start-process "$gitfile" -argumentlist `
      "/VERYSILENT","/NORESTART","/NOCANCEL","/SP-","/CLOSEAPPLICATIONS","/RESTARTAPPLICATIONS","/COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -wait
}

Function Install-Java {
    $javaurl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=236886_42970487e3af4f5aa5bca3f542482c60"
    $javafile = "$LocalTempDir\java-install.exe"

    Download "$javaurl" "$javafile"

    start-process "$javafile" -argumentlist "/s" -wait
}

Function Install-Chrome {
    $ChromeInstaller = "ChromeInstaller.exe";
    Download 'http://dl.google.com/chrome/install/375.126/chrome_installer.exe' `
      "$LocalTempDir\$ChromeInstaller"
    & "$LocalTempDir\$ChromeInstaller" /silent /install;
    $Process2Monitor = "ChromeInstaller";
    Do {
	$ProcessesFound = Get-Process |
	  ?{$Process2Monitor -contains $_.Name} |
	  Select-Object -ExpandProperty Name;
	If ($ProcessesFound) {
	    "Still running: $($ProcessesFound -join ', ')" | Write-Host;
	    Start-Sleep -Seconds 2
	} else {
	    rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose
	}
    } Until (!$ProcessesFound)
}

Function Updates-Off {
    & reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v AUOptions /t REG_DWORD /d 3
}

Function Install-R {
    $CRAN = "https://cloud.r-project.org"
    $DevelUrl = $CRAN + "/bin/windows/base/R-devel-win.exe"

    $Version = $(ConvertFrom-JSON $(Invoke-WebRequest "http://rversions.r-pkg.org/r-release-win").Content).version
    If ($Version -eq "3.2.4") {
	$Version = "3.2.4revised"
    }

    $Oldrel = $(ConvertFrom-JSON $(Invoke-WebRequest "http://rversions.r-pkg.org/r-oldrel").Content).version

    $ReleaseUrl = $CRAN + "/bin/windows/base/R-" + $Version + "-win.exe"
    $PatchedUrl = $CRAN + "/bin/windows/base/R-" + $Version + `
      "patched-win.exe"
    $OldrelUrl = $CRAN + "/bin/windows/base/old/" + $Oldrel + `
      "/R-" + $Oldrel + "-win.exe"

    $DevelFile   = "$LocalTempDir\R-devel-win.exe"
    $ReleaseFile = "$LocalTempDir\R-release-win.exe"
    $PatchedFile = "$LocalTempDir\R-patched-win.exe"
    $OldrelFile  = "$LocalTempDir\R-oldrel-win.exe"

    Download "$DevelUrl"   "$DevelFile"
    Download "$ReleaseUrl" "$ReleaseFile"
    Download "$PatchedUrl" "$PatchedFile"
    Download "$OldrelUrl"  "$OldrelFile"

    Start-Process -FilePath "$ReleaseFile" -ArgumentList "/VERYSILENT" -NoNewWindow -Wait
    Start-Process -FilePath "$OldrelFile"  -ArgumentList "/VERYSILENT" -NoNewWindow -Wait
    Start-Process -FilePath "$PatchedFile" -ArgumentList "/VERYSILENT" -NoNewWindow -Wait
    Start-Process -FilePath "$DevelFile"   -ArgumentList "/VERYSILENT" -NoNewWindow -Wait
}

Function Install-Rtools {
    $rtoolsver = $(Invoke-WebRequest ($CRAN + "/bin/windows/Rtools/VERSION.txt")).Content.Split(' ')[2].Split('.')[0..1] -Join ''
    $rtoolsurl = $CRAN + "/bin/windows/Rtools/Rtools$rtoolsver.exe"

    $rtoolsfile = "$LocalTempDir\Rtools.exe"
    Download "$rtoolsurl" "$rtoolsfile"

    Start-Process -FilePath "$rtoolsfile" -ArgumentList /VERYSILENT -NoNewWindow -Wait

    # TODO: this should update, really....
    setx path "$c:\rtools34\bin"
}

Function Install-Latex {
    $latexurl = "https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/miktexsetup-2.9.6942-x64.zip"
    $latexfile = "$LocalTempDir\miktex.xip"
    Download $latexurl $latexfile
    $xdir = "$LocalTempDir\miktex"
    mkdir "$xdir"
    & 'c:\rtools34\bin\unzip.exe' "$latexfile" -d "$xdir"
    & "$xdir\miktexsetup.exe" --quiet  --package-set=complete download
    & "$xdir\miktexsetup.exe" --quiet  --package-set=complete install
}

Function Install-Pandoc {
    $url1 = "https://files.r-hub.io/pandoc/windows/pandoc-1.19.2.1.zip"
    $url2 = "https://files.r-hub.io/pandoc/windows/pandoc-citeproc-0.10.4.zip"
    $file1 = "$LocalTempDir\pandoc.zip"
    $file2 = "$LocalTempDir\pandoc-citeproc.zip"

    Download "$url1" "$file1"
    Download "$url2" "$file2"

    $xdir = "$LocalTempDir\pandoc"
    mkdir "$xdir"
    & 'c:\rtools34\bin\unzip.exe' -o "$file1" -d "$xdir"
    & 'c:\rtools34\bin\unzip.exe' -o "$file2" -d "$xdir"

    cp "$xdir\*.exe" c:\windows\
}

Function Install-Aspell {
    $spellurl = "http://ftp.gnu.org/gnu/aspell/w32/Aspell-0-50-3-3-Setup.exe"
    $spellfile = "$LocalTempDir\aspell-setup.exe"

    Download "$spellurl" "$spellfile"

    & "$spellfile" /VERYSILENT /NORESTART /NOCANCEL
}

Function Get-Jenkins {
    $swarmversion = "3.9"
    $swarmurl = "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$swarmversion/swarm-client-$swarmversion.jar"
    $swarmfile = "c:\Users\rhub\jenkins-swarm-client.jar"

    Download "$swarmurl" "$swarmfile"
}

Function Get-LocalSoft {
    $localurl = "https://github.com/rwinlib/local330/archive/master.zip"
    $localfile = "$LocalTempDir\local330.zip"

    Download "$localurl" "$localfile"

    mkdir -force c:\R
    ## We need the WMF5.1 update for this, powershell 2.0 does not have it
    expand-archive -path "$localfile" -destinationpath "c:\R"
    mv "c:\R\local330-master" "c:\R\local330"

    $glpk32url = "https://www.stats.ox.ac.uk/pub/Rtools/goodies/multilib/glpk32.zip"
    $glpk64url = "https://www.stats.ox.ac.uk/pub/Rtools/goodies/multilib/glpk64.zip"
    $glpk32file = "$LocalTempDir\glpk32.zip"
    $glpk64file = "$LocalTempDir\glpk64.zip"

    Download "$glpk32url" "$glpk32file"
    Download "$glpk64url" "$glpk64file"

    expand-archive -path "$glpk32file" -destinationpath "c:\R\glpk32"
    expand-archive -path "$glpk64file" -destinationpath "c:\R\glpk64"

    $sym32url = "https://www.stats.ox.ac.uk/pub/Rtools/goodies/multilib/symphony32.zip"
    $sym64url = "https://www.stats.ox.ac.uk/pub/Rtools/goodies/multilib/symphony64.zip"
    $sym32file = "$LocalTempDir\sym32.zip"
    $sym64file = "$LocalTempDir\sym64.zip"

    Download "$sym32url" "$sym32file"
    Download "$sym64url" "$sym64file"

    expand-archive -path "$sym32file" -destinationpath "c:\R\symphony32"
    expand-archive -path "$sym64file" -destinationpath "c:\R\symphony64"

    $mv = "c:\R\Makevars.win"
    "LIB_XML=c:/R/local330"              | AC "$mv"
    "LIB_GSL=c:/R/local330"              | AC "$mv"
    "GLPK_HOME=c:/R/glpk32"              | AC "$mv"
    "SYMPHONY_HOME=c:/R/symphony32"      | AC "$mv"
    "DLLFLAGS+=-Lc:/R/local330/lib/i386" | AC "$mv"

    $mv64 = "c:\R\Makevars.win64"
    "LIB_XML=c:/R/local330"              | AC "$mv64"
    "LIB_GSL=c:/R/local330"              | AC "$mv64"
    "GLPK_HOME=c:/R/glpk64"              | AC "$mv64"
    "SYMPHONY_HOME=c:/R/symphony64"      | AC "$mv64"
    "DLLFLAGS+=-Lc:/R/local330/lib/x64"  | AC "$mv64"

    SETX LOCAL_SOFT c:\R\local330
    SETX R_MAKEVARS_WIN "$mv"
    SETX R_MAKEVARS_WIN64 "$mv64"
}

Function Get-Scripts {
    git clone https://github.com/r-hub/wincheck.git c:\users\rhub\wincheck
    cp c:\users\rhub\wincheck\*.ps1 c:\users\rhub\documents\
}

Updates-Off
Set-Timezone

Install-Git
Install-Java
Install-Chrome
Install-R
Install-Rtools
Install-Latex
Install-Pandoc
Install-Aspell

Get-Jenkins
Get-LocalSoft
Get-Scripts