<#
The script is provided "AS IS" with no warranties.
#>
function Check_BD{
  $check = (Get-Item "HKLM:Software\Bitdefender\Endpoint Security\Bdec\" -EA Ignore).Property -contains "install_version"
  return $check;
}
$exitCode = 0
#FILL IN company_code_base64 - the info can be found in your Gravity Zone - "aHR0cHM6Ly9jbG91ZGd6L ... Zz1lbi1VUw=="
$company_code_base64 = "FILL ME IN"
$random_folder = "C:\Windows\Temp\" + -join ((48..57) + (97..122) | Get-Random -Count 32 | % {[char]$_}) + "\"
$installFile = $random_folder + "setupdownloader_[" + $company_code_base64 + "].exe"
# Start logging to TEMP in file "scriptname".log
Start-Transcript -Path "C:\Windows\Temp\bitdefender_installation_win.log" -Append | Out-Null
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
Write-Host "Admin security context: " $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
try
{
  if (!(Check_BD)) {
    Write-Host "Creating random folder in Temp."
    new-item $random_folder -itemtype directory
    Write-Host "Downloading Bitdefender."
    Invoke-WebRequest -Uri "https://cloudgz.gravityzone.bitdefender.com/Packages/BSTWIN/0/setupdownloader.exe"  -OutFile ("{0}setupdownloader.exe" -f $random_folder)
    Write-Host "Checking signature for the executable."
    $executableCertHash = (Get-AuthenticodeSignature ("{0}setupdownloader.exe" -f $random_folder)).SignerCertificate.Thumbprint
    if ($executableCertHash -eq "41D7D5EA6C45CA283662D55CC8A854635D569823") {
      Move-Item -LiteralPath ("{0}setupdownloader.exe" -f $random_folder) -Destination $installFile  -Force
      Write-Host "Installtinfg from: " + $installFile
      Start-Process $installFile  -ArgumentList "/bdparams /silent silent" -Wait -NoNewWindow
      Start-Sleep -s 30
      if (Check_BD) {
        Remove-Item -LiteralPath $random_folder -Force -Recurse
        Write-Host "Successfully installed Bitdefender."
      }
      else {
        Throw "Unsuccessfully installed Bitdefender."
      }
    }
    else {
      Throw "Certificate for the executable is not valid."
    }
  }
  else {
    Write-Host "Bitdefender already installed"
  }
}
catch
{
  Remove-Item -LiteralPath $random_folder -Force -Recurse
  $_
  $exitCode = -1
}
Stop-Transcript | Out-Null
exit $exitCode
