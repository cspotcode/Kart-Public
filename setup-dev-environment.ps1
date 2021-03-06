param(
    [switch]$help,
    [switch]$fixPowershellExecutionPolicy,
    [switch]$forceRecreateBuildScripts,
    [switch]$build,
    [switch]$run,
    [switch]$runDedicated
)

$ErrorActionPreference = 'Stop'

# Catering to windows powershell.  Prefer using powershell core, but if you don't have that, we'll do our best
if(-not $IsLinux -and -not $IsMacOS -and -not $IsWindows) {
    $IsWindows = $true
}

if($fixPowershellExecutionPolicy) {
    Start-Process -Verb runas powershell.exe -ArgumentList @("-NoLogo", "-NoProfile", "-Command", "Set-ExecutionPolicy -Confirm RemoteSigned")
}

if($help) {
    write-host ''
    write-host -ForegroundColor Green -BackgroundColor Black 'Welcome to SRB2Kart developer shell'
    write-host ''
    write-host 'This is a PowerShell where you can run ./setup-dev-environment.ps1'
    write-host './setup-dev-environment.ps1 is a script to automatically compile srb2kart on Windows.'
    write-host 'It will automatically download and configure the necessary compiler tools and SRB2Kart assets.'
    write-host 'To setup compiler tools and assets:'
    write-host '    ./setup-dev-environment.ps1'
    write-host 'To also build and run the game:'
    write-host '    ./setup-dev-environment.ps1 -build -run'
    write-host 'To force a cmake re-generate:'
    write-host '    ./setup-dev-environment.ps1 -forceRecreateBuildScripts'
    write-host ''
    return
}

$buildDir = "$PSScriptRoot/build"
$cmakeToolchain = "MinGW Makefiles"
$binName = "srb2kart.exe"
if($IsLinux) {
    $buildDir = "$PSScriptRoot/build-linux"
    $cmakeToolchain = "Unix Makefiles"
    $binName = "srb2kart"
}

$toolchainBaseDir = "$PSScriptRoot/toolchain"
$toolchainDownloadsDir = "$toolchainBaseDir/downloads"
if(-not (test-path $toolchainBaseDir)) { new-item -ItemType Directory $toolchainBaseDir }
if(-not (test-path $toolchainDownloadsDir)) { new-item -ItemType Directory $toolchainDownloadsDir }

if($IsWindows) {
    $cmakeZipDownload = "$toolchainDownloadsDir/cmake.zip"
    $cmakeExtractDir = "$toolchainBaseDir/cmake"
    $cmakeZipUri = 'https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2-windows-x86_64.zip'
    $cmakeBinDir = "$cmakeExtractDir/cmake-3.21.2-windows-x86_64/bin"
    $cmakeCommand = "$cmakeBinDir/cmake.exe"
    if(-not (test-path $cmakeCommand)) {
        Write-Host "Local copy of cmake not found.  Extracting..."
        if (-not (test-path $cmakeZipDownload)) {
            Write-Host "Local download of cmake not found.  Downloading..."
            Invoke-WebRequest -uri $cmakeZipUri -OutFile $cmakeZipDownload
            Write-Host "Downloaded local copy of cmake"
        }
        Expand-Archive $cmakeZipDownload $cmakeExtractDir
        Write-Host "Extracted local copy of cmake."
    }
}

$installerPath = "$PSScriptRoot/assets/srb2kart-v13-Installer.zip"
$installerZipUri = 'https://github.com/STJr/Kart-Public/releases/download/v1.3/srb2kart-v13-Installer.exe'
$installerExtractedPath = "$PSScriptRoot/assets/installer"
if (-not (Test-Path $installerExtractedPath)) {
    Write-Host "Assets from the SRB2Kart installer not found.  Attempting to extract..."
    if (-not (Test-Path $installerPath)) {
        Write-Host "Installer not found.  Downloading..."
        Invoke-WebRequest -uri $installerZipUri -OutFile $installerPath
    }
    Expand-Archive -Path $installerPath -DestinationPath $installerExtractedPath
    Write-Host "Extracted installer $installerPath into $installerExtractedPath"
}

if($IsWindows) {
    $mingwInstallDir = "$toolchainBaseDir/mingw"
    $mingwBinDir = "$mingwInstallDir/bin"
    $mingwGetZip= "$toolchainDownloadsDir/mingw-get.zip"
    $mingwGetZipUri = 'https://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip/download'
    $mingwGetExtractedDir = "$mingwInstallDir"
    $mingwGetCommand = "$mingwGetExtractedDir/bin/mingw-get.exe"
    $mingwMakeCommand = "$mingwInstallDir/bin/mingw32-make.exe"

    if (-not (test-path $mingwMakeCommand)) {
        Write-Host "Local mingw toolchain not found."
        if (-not (test-path $mingwGetCommand)) {
            Write-Host "Local mingw-get installer not found."
            if (-not (test-path $mingwGetZip)) {
                Write-Host "Local mingw download not found.  Downloading..."
                # Invoke-Webrequest does not work, possibly due to user-agent, possibly due to sourceforge server behavior with redirects
                $webclient = New-Object System.Net.WebClient
                $webclient.DownloadFile($mingwGetZipUri, $mingwGetZip)
                Write-Host "Downloaded mingw installer."
            }
            Write-Host "Extracting mingw installer..."
            Expand-Archive -Path $mingwGetZip -DestinationPath $mingwGetExtractedDir
            Write-Host "Extracted mingw installer."
        }
        Write-Host "Using mingw-get to install local mingw toolchain..."
        & $mingwGetCommand install gcc mingw32-make mingw32-gdb
        Write-Host "Installed local mingw toolchain."
    }
}

if($IsWindows) {
    Write-Host "Adding local mingw and cmake toolchains to your PATH"
    # TODO avoid adding these every time; after the first invocation in a shell, they're already there
    $env:Path = "$mingwBinDir;$cmakeBinDir;$($env:Path)"
}

Write-Host "Success.  Local toolchain has been configured."

if($forceRecreateBuildScripts) {
    remove-item -Recurse $buildDir
    new-item -ItemType Directory $buildDir/bin
}

if(-not (test-path $buildDir/bin/chars.kart)) {
    Expand-Archive -Path $installerPath -DestinationPath $buildDir/bin
    remove-item $buildDir/bin/srb2kart.exe
}

if(-not (test-path $buildDir/CMakeCache.txt)) {
    cmake -B $buildDir -G $cmakeToolchain
}

if($build) {
    cmake --build $buildDir --config Debug -j 10 --
}
if($run -or $runDedicated) {
    $extraArgs = @()
    if($runDedicated) {
        $extraArgs = @('-dedicated')
    }
    $beforePwd = $PWD.Path
    try {
        set-location $buildDir/bin
        Write-Host $PWD.Path
        & ./$binName @extraArgs
    } finally {
        set-location $beforePwd
    }
}
