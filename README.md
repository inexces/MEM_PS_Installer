# MEM_PS_Installer
Simple Intune Software Package Framework

## .SYNOPSIS
This script performs the installation or uninstallation of [PACKAGENAME]
  
## .DESCRIPTION
This script is a framework and standardisation for installing apps focussed on Intune.
It performs an install or uninstall depending on the "type" parameter.
  
## .INPUTS
-Type		The type of deployment to perform. Options: [Install, Uninstall]. Default is: Install.
  
## .OUTPUTS
Registry Entry: HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages
Eventlog Entry: in BrandName log
  
## .EXAMPLE
powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1
powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1 -Type "Uninstall"
	
## .NOTES
- Version:        1.8.1
- Author:         Marcus Jaken ~ Microsoft ☁ Consultant @ Advantive B.V / marcus.jaken@advantive.nl
- Creation Date:  2021

## .CODESNIPS
###### Install with MSIEXEC
	Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/update $($msp.FullName) /quiet" -Wait -Passthru
###### Uninstall with MSIEXEC
	Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/x{} /qn" -Wait -Passthru
###### Install EXE
	Start-Process -FilePath "$dirFiles\OSDD.exe" -ArgumentList /s, v"/qb INSTALLDIR=\"C:\PRGS\PTC\Creo_Elements\Direct_Drafting_20.1\" MELS=\"CADLIC\" ALLUSERS=1 ADDLOCAL=ALL " -Wait -Passthru
###### Chocolaty
	powershell.exe -executionpolicy bypass -noprofile -noninteractive Start-Process -Wait -FilePath "C:\ProgramData\chocolatey\choco.exe" -ArgumentList "install logitech-options -y"
###### Install with MSIEXEC advanced
	Write-Host "Autodesk Inventor LT 2020"
	$msifile = "Img\x64\ILT\inventor.msi"
	$msiargs = @(
		"/i"
		"`"$msifile`""
		'TRANSFORMS="Img\x64\en-us\ILT\inventor.mst;Img\x64\ILT\inventor-INTUNE.mst"'
		'ADSK_EULA_STATUS="#1"'
		'ADSK_SOURCE_ROOT="Img\"'
		'FILESINUSETEXT=""'
		'REBOOT=ReallySuppress'
		'ADSK_SETUP_EXE=1'
		"/qn"
	)
	$installcommand = (start-process msiexec.exe -ArgumentList $msiargs -wait -PassThru).ExitCode
	Start-Sleep -s 15
###### TIMEOUT
	Start-Sleep -s 15
###### SET USER RIGHTS
	if((Test-Path C:\DIR)) {
			$Acl = Get-Acl -Path "C:\DIR"
			$sid = New-Object System.Security.Principal.SecurityIdentifier ([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid, $null)
			$permissions = New-Object System.Security.AccessControl.FileSystemAccessRule ($sid, 'Modify', 'ObjectInherit,ContainerInherit', 'None', 'Allow')
			$acl.AddAccessRule($permissions)
			Set-Acl -path C:\DIR $acl
		}
###### COPY SHORTCUT DESKTOP
	Copy-Item "$PSScriptRoot\Modeling 20.lnk" -Destination "C:\Users\Public\Desktop\Modeling 20.lnk" -Force
###### COPY SHORTCUT STARTMENU
	Copy-Item "$PSScriptRoot\Modeling 20.lnk" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Modeling 20.lnk" -Force
###### Delete Desktop ICON
	Remove-Item -Force "C:\Users\Public\Desktop\DWG TrueView 2021 - English.lnk"
###### Create Shortcut
	$Shell = New-Object –ComObject ("WScript.Shell")
	$ShortCut = $Shell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BGInfo.lnk")
	$ShortCut.TargetPath="`"C:\Program Files\BGInfo\Bginfo64.exe`""
	$ShortCut.Arguments="`"C:\Program Files\BGInfo\custom.bgi`" /timer:0 /silent /nolicprompt"
	$ShortCut.IconLocation = "Bginfo64.exe, 0";
	$ShortCut.Save()
###### Create Script support folder
	if(!(Test-Path "$($env:ProgramData)\$($Settings.config.BrandName)")) { 
		New-Item -Path "$($env:ProgramData)" -Name "$($Settings.config.BrandName)" -ItemType "directory" -Force -ErrorAction SilentlyContinue
		$MessageInitialisation = "Created `"$($env:ProgramData)\$($Settings.config.BrandName)`""
	}
