# Environment variables
# $env:cwd      => current working directory
# $env:core     => current core configuration
# $env:config   => current proxy configuration
# $env:mmdb     => current mmdb configuration

$env:cwd = Split-Path -Path $MyInvocation.MyCommand.Path
$env:cwd_root = $env:cwd + "/../"
$env:cwd_data = $env:cwd_root + "data/"



function Show-Menu {
    Clear-Host
    Write-Output "Choose operation:"
    Write-Output "1. update/download core 🚀"
    Write-Output "2. update/download mmdb 🗄️"
    Write-Output "3: update subscription 🔄"
    Write-Output "4: setting uwp ⚙️"
    Write-Output "5: run 🐱"
    Write-Output "0: quit 🔚"

    $key = [System.Console]::ReadKey($true) # Read-Host "input your instruct"

    switch ($key.KeyChar) {

        '1' {
            Clear-Host
            Write-Output "Start update/download core 🚀"

            Update-Core

            Pause
            Show-Menu
        }

        '2' {
            Clear-Host
            Write-Output "Start update/download mmdb 🗄️"

            Update-MMDB

            Pause
            Show-Menu
        }
        '3' {
            Clear-Host
            Write-Output "Start update subscription 🔄"


            Update-Subscription

            Pause
            Show-Menu
        }

        '4' {
            Clear-Host
            Write-Output "Start setting uwp ⚙️"

            Open-UWP-Settings

            Pause
            Show-Menu
        }

        '5' {
            Clear-Host
            Write-Output "Start running 🐱"

            Running-Cat

            Pause
            Show-Menu

        }


        '0' {
            Clear-Host
            exit
        }


        default {
            Write-Output "`n invaild choose, try again"
            Pause
            Show-Menu
        }
    }
}

function Pause {
    Write-Output "Type anything plz..."
    [System.Console]::ReadKey($true)
}


function Init() {
    # We wish environment variables have set
    $env_file = $env:cwd_root + ".env.ps1"
    if (Test-Path -Path $env_file) {
        Write-Output "load envenvironment variables."
    }
    else {
        Write-Output "envenvironment file does not exist. refer readme first!"
    }

    . $env_file

    $env:core       = $env:cwd_data + "core.exe"
    $env:mmdb       = $env:cwd_data + "Country.mmdb"
    $env:config     = $env:cwd_data + "config.yaml"
    $env:uwp        = $env:cwd_data + "uwp.exe"

    return $env
}


# Update Subscription
function Update-Subscription() {
    $bak = $env:config + ".bak"

    curl -L $env:download_address -o $env:config # --noproxy "*"

    (type $env:config)  -replace "allow-lan: false", "allow-lan: true"      > $bak
    (type $bak)         -replace "mixed-port: 7890", "mixed-port: 10800"    > $env:config

    rm $bak
}


function Update-Core() {
    $address = Get-Github-Lastest-Release-Url "MetaCubeX/mihomo"

    $origin_path = $env:cwd_data + "core.zip"

    fetch $address $origin_path

    Expand-Archive -Path $origin_path -DestinationPath $env:cwd_data -Force

    if (Test-Path -Path $env:core) {
        rm $env:core
    }

    $extracted_files = Get-ChildItem -Path $env:cwd_data
    foreach ($file in $extracted_files) {
        if ($file.Name -match "^mihomo-windows") {
            Rename-Item -Path $file.FullName -NewName "core.exe"
        }
    }
}


function Update-MMDB() {
    $address = "https://github.com/Loyalsoldier/geoip/releases/latest/download/Country.mmdb"
    fetch $address $env:mmdb
}

function fetch($url, $target) {
    if (Test-Path -Path $target) {
        Write-Output "Target file have existed. Skip updating temporarily."
    }
    else {
        curl -L $url -o $target
    }
}


function Open-UWP-Settings() {
    $softwareName = "Enable Loopback Utility"
    $installedSoftware = winget list | Select-String -Pattern $softwareName

    if ($installedSoftware) {
        Write-Output "$softwareName has installed, skipping installation"
        $softwarePath = "C:\Program Files (x86)\EnableLoopback\EnableLoopback.exe"
        if (Test-Path $softwarePath) {
            Start-Process $softwarePath
        } else {
            Write-Output "cannot found executable file, please confirm correct path"
        }
    }
    else {
        Write-Output "start installation"
        
        $uwp_address = "https://telerik-fiddler.s3.amazonaws.com/fiddler/addons/enableloopbackutility.exe"

        fetch $uwp_address $env:uwp

        if (Test-Path $env:uwp) {
            Start-Process $env:uwp
        } else {
            Write-Output "cannot found executable file, please confirm correct path"
        }
    }

}


function Running-Cat () {
    if (-not (Test-Path $env:core)) {
        Write-Output "cannot found core, please confirm have running 1"
        return
    }
    if (-not (Test-Path $env:mmdb)) {
        Write-Output "cannot found mmdb, please confirm have running 2"
        return
    }
    if (-not (Test-Path $env:config)) {
        Write-Output "cannot found config, please confirm have running 3"
        return
    }

    Start-Process -FilePath $env:core -ArgumentList "-d", $env:cwd_data
}

function Get-Github-Lastest-Release-Url($repo) {
    # repo params should be like, MetaCubeX/mihomo

    # Judge current windows cpu architectures
    $filter = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "windows-amd64" } else { "windows-arm64" }

    $response = curl -s "https://api.github.com/repos/$repo/releases/latest" | ConvertFrom-Json

    # when we meet the github limit, we should return address to keep it run well
    if ($response.message -like "*API rate limit exceeded*") {
        Write-Host "API rate limit exceeded. Please authenticate or try again later."
        Write-Host "For more information, visit: $($response.documentation_url)"
        Write-Host "We will use the address build-in."
        return "https://github.com/MetaCubeX/mihomo/releases/download/v1.18.9/mihomo-windows-amd64-v1.18.9.zip"
    }

    # get all "browser_download_url" include filter 
    $windowsLinks = $response.assets | Where-Object { $_.name -match $filter } | Select-Object -ExpandProperty browser_download_url

    # we always get the lastest one.
    return $windowsLinks[-1]
}


Init
# TODO: Wait-User
Show-Menu
