<#
.SYNOPSIS
  This script performs the installation or uninstallation of [PACKAGENAME]

.DESCRIPTION
  This script is a framework and standardisation for installing apps focussed on Intune.
  It performs an install or uninstall depending on the "type" parameter
  
.INPUTS
  -Type		The type of deployment to perform. Options: [Install, Uninstall]. Default is: Install.

.OUTPUTS
  Transcript logfile: c:\programdata\$BrandName\Log\$logfile
  Registry Enry: HKLM\SOFTWARE\$BrandName\Packages\

.EXAMPLE
	powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1 -Type "Install""
	powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1 -Type "Uninstall"
	
.NOTES
  Version:        1.7
  Author:         Marcus Jaken ~ Microsoft Cloud Consultant @ Advantive B.V
  Creation Date:  2021-05-19
  
#>
		
#--------------------------------------------------[Run script in 64bit]-----------------------------------------------------------

	If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
		Try {
			&"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
		}
		Catch {
			Throw "Failed to start $PSCOMMANDPATH"
		}
		Exit
	}

#---------------------------------------------------------[Input]------------------------------------------------------------------

	#Set Default parameter
	Param (
		$Type = 'Install'
	)

	## Load the Config.xml
	[Xml]$config = Get-Content "$($exeScriptDir)IntuneConfig.xml"
        $BrandName = "$($config.config.BrandName)"
        $Packagename = "$($config.config.Packagename)"
        $Version = "$($config.config.Version)"
        $installdate = Get-Date -Format "yyyy/MM/dd HH:mm"
        $exeScriptDir = $PSScriptRoot
        $logfile = "$Packagename" + "_" + "$Version.log"
        $RegkeyName = "$Packagename" + "_" + "$Version"
	Write-Host "Setting adjustable Variables $($config.config.BrandName), $($config.config.Packagename), $($config.config.Version)", "Install folder: $exeScriptDir", "Loading configuration: $($exeScriptDir)Config.xml"

#-----------------------------------------------------[Initialisation]-------------------------------------------------------------

	#Create Log-directory
	if(!(Test-Path "$($env:ProgramData)\$BrandName")) { 
        New-Item -Path "$($env:ProgramData)" -Name "$BrandName" -ItemType "directory" -Force -ErrorAction SilentlyContinue
    }    
	
#-----------------------------------------------------------[Functions]------------------------------------------------------------

	# Registry Module
	Function RegisterInstallation() {
		Param(
			[Parameter(Mandatory=$True)][String]$ErrorLevel
		)
		If ($ErrorLevel -eq "0") {
			Write-Host "Create Registry installation key HKLM\SOFTWARE\$BrandName\Packages\$RegkeyName"
			New-Item -Path Registry::"HKLM\SOFTWARE\$BrandName\Packages\$RegkeyName" -type Directory -Force -ErrorAction SilentlyContinue
			new-itemproperty Registry::"HKLM\SOFTWARE\$BrandName\Packages\$RegkeyName" -Name "Version" -Value $Version -PropertyType String -Force -ErrorAction SilentlyContinue
			new-itemproperty Registry::"HKLM\SOFTWARE\$BrandName\Packages\$RegkeyName" -Name "Install_Date" -Value $installdate -PropertyType String -Force -ErrorAction SilentlyContinue
		} 
    EXIT $ErrorLevel
	} 
	
	Function UnregisterInstallation() {
		Param(
			[Parameter(Mandatory=$True)][String]$ErrorLevel
		)
		If ($ErrorLevel -eq "0") {
			Write-Host "Delete Registry installation key HKLM\SOFTWARE\$BrandName\Packages\$RegkeyName"
			Remove-Item -Path "HKLM:\SOFTWARE\$BrandName\Packages\$RegkeyName" -Force
	} 
    EXIT $ErrorLevel
	} 	
	

#-----------------------------------------------------------[Execution]------------------------------------------------------------

	## Do not remove, setting error level to zero before installation
        $Error.Clear()

	If ($Type -ine 'Uninstall') {
		Start-Transcript "$($env:ProgramData)\$BrandName\Log\$Type-$logfile"
		
		#[Prerequisits]------------------------------------------------------------------------------------------------------------
		
		#[/Prerequisits]-----------------------------------------------------------------------------------------------------------
		
		#[Instalation]-------------------------------------------------------------------------------------------------------------
		
		Function Install {
			Write-Host "Teamviewer installer Host 15.17.6"
			$msifile = "$($exeScriptDir)\TeamViewer_Host.msi"
				$msiargs = @(
					"/i"
					"`"$msifile`""
					'APITOKEN='
					'CUSTOMCONFIGID='
					'DESKTOPSHORTCUTS=0'
					"SETTINGSFILE=`"$($exeScriptDir)\2021.tvopt`""
					"/qn"
				)
			(start-process msiexec.exe -ArgumentList $msiargs -wait -PassThru).ExitCode
			Start-Sleep -s 10
		}
		Install
				
		#[/Instalation]------------------------------------------------------------------------------------------------------------
		
		If ($Error.Count -gt 0) {
			RegisterInstallation -ErrorLevel 101
		} else {
		}
		
		RegisterInstallation -ErrorLevel 0

		Stop-Transcript
	}
	ElseIf ($Type -ieq 'Uninstall') {
		Start-Transcript "$($env:ProgramData)\$BrandName\Log\$Type-$logfile"
		
		#[Uninstallation]----------------------------------------------------------------------------------------------------------
		
		Function Uninstall {
			Start-Process -FilePath "msiexec.exe" -ArgumentList "/X{F9631805-F9F3-457E-B213-5E3213C1C16C} /qn" -Wait -Passthru
		}
		Uninstall
		
		#[/Uninstallation]---------------------------------------------------------------------------------------------------------
		
		If ($Error.Count -gt 0) {
			UnregisterInstallation -ErrorLevel 101
		} else {
		}
		
		UnregisterInstallation -ErrorLevel 0		

		Stop-Transcript
	}
	
#------------------------------------------------------------[Exiting]-------------------------------------------------------------

