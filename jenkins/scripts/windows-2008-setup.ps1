
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

    $env:path = "C:\Program Files\Git\bin;$env:path"
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

Function Install-7zip {
    $zipurl = "https://www.7-zip.org/a/7z1900-x64.msi"
    $zipfile = "$LocalTempDir\7zip.msi"
    Download  "$zipurl" "$zipfile"

    msiexec /i "$zipfile" /q INSTALLDIR="C:\Program Files\7-Zip"

    $env:path = "C:\Program Files\7-Zip;$env:path"
}

Function Install-Rtools {
    $rtoolsver = $(Invoke-WebRequest ($CRAN + "/bin/windows/Rtools/VERSION.txt")).Content.Split(' ')[2].Split('.')[0..1] -Join ''
    $rtoolsurl = $CRAN + "/bin/windows/Rtools/Rtools$rtoolsver.exe"

    $rtoolsfile = "$LocalTempDir\Rtools.exe"
    Download "$rtoolsurl" "$rtoolsfile"

    Start-Process -FilePath "$rtoolsfile" -ArgumentList /VERYSILENT -NoNewWindow -Wait
}

Function Install-Latex {
    $latexurl = "https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/miktexsetup-2.9.6942-x64.zip"
    $latexfile = "$LocalTempDir\miktex.xip"
    Download $latexurl $latexfile
    $xdir = "$LocalTempDir\miktex"
    mkdir "$xdir" -force
    $repo = "https://ctan.math.illinois.edu/systems/win32/miktex/tm/packages/"
    & 7z x "$latexfile" -o"$xdir"
    & "$xdir\miktexsetup.exe" --quiet  --package-set=complete `
      "--remote-package-repository=$repo" download
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
    mkdir "$xdir" -force
    & 7z x "$file1" -aoa -o"$xdir"
    & 7z x "$file2" -aoa -o"$xdir"

    cp "$xdir\*.exe" c:\windows\
}

Function Install-Aspell {
    $spellurl = "http://ftp.gnu.org/gnu/aspell/w32/Aspell-0-50-3-3-Setup.exe"
    $spellfile = "$LocalTempDir\aspell-setup.exe"

    Download "$spellurl" "$spellfile"

    & "$spellfile" /VERYSILENT /NORESTART /NOCANCEL
}

Function Install-Jags {
    $jagsurl = "https://files.r-hub.io/jags/jags-4.3.0.zip"
    $jagsfile  = "$LocalTempDir\jags-4.3.0.zip"

    Download "$jagsurl" "$jagsfile"

    $xdir = "c:/R/jags"
    mkdir "$xdir"  -force
    & 7z x "$jagsfile" -o"$xdir"

    $mv = "c:\R\Makevars.win"
    $mv64 = "c:\R\Makevars.win64"
    "JAGS_ROOT=c:/R/jags/JAGS-4.3.0" | AC "$mv"
    "JAGS_ROOT=c:/R/jags/JAGS-4.3.0" | AC "$mv64"

    SETX JAGS_HOME "c:/R/jags/JAGS-4.3.0" /M
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

    SETX LOCAL_SOFT c:\R\local330 /M
    SETX R_MAKEVARS_WIN "$mv"     /M
    SETX R_MAKEVARS_WIN64 "$mv64" /M
}

Function Get-Scripts {
    git clone https://github.com/r-hub/wincheck.git c:\users\rhub\wincheck
    cp c:\users\rhub\wincheck\*.ps1 c:\users\rhub\documents\
}

Function Install-Perl {
    $perlurl = "http://strawberryperl.com/download/5.28.1.1/strawberry-perl-5.28.1.1-64bit.msi"
    $perlfile = "$LocalTempDir\strawberry-perl-5.28.1.1-64bit.msi"

    Download "$perlurl" "$perlfile"

    start-process msiexec -ArgumentList "/I $perlfile /passive" -wait
}

Function Install-Rtools40 {
    # Experimental Rtools40 installation
    $rtoolsurl = "https://dl.bintray.com/rtools/installer/rtools40-x86_64.exe"
    $rtoolsfile = "$LocalTempDir\rtools40-x86_64.exe"
    Download "$rtoolsurl" "$rtoolsfile"
    Start-Process -FilePath "$rtoolsfile" -ArgumentList /VERYSILENT -NoNewWindow -Wait

    # Rtools40 path is hardcoded in R-testing for now
    # setx path "$c:\rtools40\usr\bin"

    # Special build of R for Rtools40
    $TestingUrl    = "https://dl.bintray.com/rtools/installer/R-testing-win.exe"
    $TestingFile   = "$LocalTempDir\R-testing-win.exe"
    Download "$TestingUrl"   "$TestingFile"
    Start-Process -FilePath "$TestingFile" -ArgumentList "/VERYSILENT" -NoNewWindow -Wait
}

Function Update-Rtools40 {
    & C:\rtools40\usr\bin\pacman --noconfirm -Syyu
    & C:\rtools40\usr\bin\bash.exe --login -c `
      'pacman -S --needed --noconfirm $(pacman -Slq | grep mingw-w64-)'
}


Updates-Off
Set-Timezone

Install-Git
Install-Java
Install-Chrome
Install-7zip
Install-R
Install-Rtools
Install-Latex
Install-Pandoc
Install-Aspell
Install-Perl

Get-Jenkins
Get-LocalSoft
Get-Scripts

Install-Jags
