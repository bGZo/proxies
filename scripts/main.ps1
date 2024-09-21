$env:cwd = Split-Path -Path $MyInvocation.MyCommand.Path


function Show-Menu {
  Clear-Host
  Write-Host "Choose operation:"
  Write-Host "1. update/download core 🚀"
  Write-Host "2. update/download mmdb 🗄️"
  Write-Host "3: update subscription 🔄"
  Write-Host "0: quit 🔚"

  $key = [System.Console]::ReadKey($true) # Read-Host "input your instruct"

  switch ($key.KeyChar) {

    '1' {
          Clear-Host
          Update-Core
          Pause
          Show-Menu
      }
      '2' {
        Clear-Host
        Update-MMDB
        Pause
        Show-Menu

      }
      '3' {
        Clear-Host
        Update-Subscription($env:download_address, $env:config)
        Pause
        Show-Menu
      }

      '0' {
        Clear-Host
        exit
      }

      default {
          Write-Host "`n invaild choose, try again"
          Pause
          Show-Menu
      }
  }
}

function Pause {
  Write-Host "Type anything plz..."
  [System.Console]::ReadKey($true) 
}


function Init-Environment() {
    # We wish environment variables have set
    $env_file        = $env:cwd + "\..\.env.ps1"
    if (Test-Path -Path $env_file) {
        echo "load envenvironment variables."
    } else {
        echo "envenvironment file does not exist. refer readme first!"
    }

    . $env_file
    $env:output_path = $env:cwd + "\..\data\config.yaml"

    return $env
}


# Update Subscription
function Update-Subscription(){
  $output_path_bak = $env:output_path + ".bak"

    curl -L $env:download_address -o $env:output_path # --noproxy "*"

    (type $env:output_path) -replace "allow-lan: false", "allow-lan: true" > $output_path_bak
    (type $output_path_bak) -replace "mixed-port: 7890", "mixed-port: 10800" > $env:output_path
    rm $output_path_bak
}


function Update-Core(){
  $address = "https://github.com/MetaCubeX/mihomo/releases/download/v1.18.8/mihomo-windows-amd64-v1.18.8.zip" 
  $origin_path = $env:cwd + "\..\data\core.zip"
  $target_path = $env:cwd + "\..\data\"

  fetch $address $origin_path

  Expand-Archive -Path $origin_path -DestinationPath $target_path -Force
  
  $target_file = $env:cwd + "\..\data\core.exe"
  if (Test-Path -Path $target_file) {
    rm $target_file
  }

  $extracted_files = Get-ChildItem -Path $target_path
  foreach ($file in $extracted_files) {
    if ($file.Name -match "^mihomo-windows") {
      Rename-Item -Path $file.FullName -NewName "core.exe"
    }
  }
}


function Update-MMDB(){
  $core_zip = $env:cwd + "/../data/Country.mmdb"
  $address = "https://github.com/Loyalsoldier/geoip/releases/download/202409190112/Country.mmdb"
  fetch $address $core_zip
}

function fetch($url, $target){
  if (Test-Path -Path $target) {
    echo "Target file have existed. Skip updating temporarily."
  } else {
    curl -L $url -o $target
  }
}


Init-Environment
# TODO: Wait-User
Show-Menu
