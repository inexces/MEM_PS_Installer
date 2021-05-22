<#
.SYNOPSIS
  This script performs the installation or uninstallation of [PACKAGENAME]

.DESCRIPTION
  This script is a framework and standardisation for installing apps focussed on Intune.
  It performs an install or uninstall depending on the "type" parameter
  Vars
  $PSScriptRoot
  $($Settings.config.BrandName)
  $($Settings.config.App.Packagename)
  $($Settings.config.App.AppVersion)
  $($Settings.config.App.PackVersion)
  $($Settings.config.EventLogSrc)
  
.INPUTS
  -Type		The type of deployment to perform. Options: [Install, Uninstall]. Default is: Install.

.OUTPUTS
  Log file: %SystemRoot%\System32\Winevt\Logs\NAME.evtx
  Registry Enry: HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\

.EXAMPLE
	powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1 -Type "Install""
	powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1 -Type "Uninstall"
	
.NOTES
  Version:        1.8
  Author:         Marcus Jaken ~ Microsoft Cloud Consultant @ Advantive B.V
  Creation Date:  2021-05-19
  
#>
		
#--------------------------------------------------[Run script in 64bit]-----------------------------------------------------------

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
	Try { &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH }
	Catch { Throw "Failed to start $PSCOMMANDPATH" }
	Exit
}

#---------------------------------------------------------[Input]------------------------------------------------------------------

#Set Default parameter
#	Param(
#		[Parameter(Mandatory=$True)][String]$Type
#        $Type = "Install"
#	)

## Load the Config.xml
[Xml]$Settings = Get-Content "$($PSScriptRoot)\IntuneConfig.xml"
$Present = Get-Date -Format "yyyy/MM/dd HH:mm"
$Package = $($Settings.config.App.Packagename) + " " + $($Settings.config.App.AppVersion)
$MessageInput =  "Setting Variables for $($Settings.config.BrandName); $($Settings.config.App.Packagename), $($Settings.config.App.AppVersion), Install folder: $PSScriptRoot"

#-----------------------------------------------------[Initialisation]-------------------------------------------------------------

#Create Company-directory & Eventlog
New-EventLog -LogName $($Settings.config.BrandName) -Source $Package -ErrorAction SilentlyContinue
# if(!(Test-Path "$($env:ProgramData)\$($Settings.config.BrandName)")) { 
# New-Item -Path "$($env:ProgramData)" -Name "$($Settings.config.BrandName)" -ItemType "directory" -Force -ErrorAction SilentlyContinue
# $MessageInitialisation = "Created `"$($env:ProgramData)\$($Settings.config.BrandName)`""
# }    

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function WriteEventlog {
		Param ( 
			[Parameter(Mandatory=$true)]
			[string]$GetMessage
		)
		$writemessage = "IntuneSetup: " + $Package + " - " + $GetMessage
		Write-EventLog -LogName $($Settings.config.BrandName) -Source $Package -EventID 1 -EntryType "Information" -Message $writemessage -Category 1
}

Function RegisterInstallation() {
	Param(
		[Parameter(Mandatory=$True)][String]$ErrorLevel
	)
	If ($ErrorLevel -eq "0") {
		WriteEventlog -GetMessage "Create Registry installation key HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$Package"
		New-Item -Path Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)" -type Directory -Force -ErrorAction SilentlyContinue
		new-itemproperty Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)" -Name "Installed" -Value $Present -PropertyType String -Force -ErrorAction SilentlyContinue
	} Else {
		WriteEventlog -GetMessage "Error during installation $Error, total errors: $($error.count)"
	}
EXIT $ErrorLevel
} 

Function UnregisterInstallation() {
	Param(
		[Parameter(Mandatory=$True)][String]$ErrorLevel
	)
	If ($ErrorLevel -eq "0") {
		WriteEventlog -GetMessage "Delete Registry installation key HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$Package"
		Remove-Item -Path "HKLM:\SOFTWARE\$($Settings.config.BrandName)\Packages\$Package" -Force
} 
EXIT $ErrorLevel
} 	

#-----------------------------------------------------------[Execution]------------------------------------------------------------

WriteEventlog -GetMessage $MessageInput

## Do not remove, setting error level to zero before installation
$Error.Clear()

If ($Type -ine 'Uninstall') {
	
																			  WriteEventlog -GetMessage "Starting Prerequisits"
	#[Prerequisits]----------------------------------------------------------------------------------------------[Prerequisits]

	#[/Prerequisits]--------------------------------------------------------------------------------------------[/Prerequisits]
																			 WriteEventlog -GetMessage "Finishing Prerequisits"
	
																			  WriteEventlog -GetMessage "Starting Installation"
	#[Instalation]------------------------------------------------------------------------------------------------[Instalation]
	New-EventLog -LogName $($Settings.config.BrandName) -Source $Package			
	#[/Instalation]----------------------------------------------------------------------------------------------[/Instalation]
																			 WriteEventlog -GetMessage "Finishing Installation"		

	If ($Error.Count -gt 0) {
		RegisterInstallation -ErrorLevel 101
	} else {
		RegisterInstallation -ErrorLevel 0
	}

}
ElseIf ($Type -ieq 'Uninstall') {
	
																			WriteEventlog -GetMessage "Strating Uninstallation"
	#[Uninstallation]------------------------------------------------------------------------------------------[Uninstallation]
			
	#[/Uninstallation]----------------------------------------------------------------------------------------[/Uninstallation]
																		   WriteEventlog -GetMessage "Finishing Uninstallation"

	If ($Error.Count -gt 0) {
		UnregisterInstallation -ErrorLevel 101
	} else {
		UnregisterInstallation -ErrorLevel 0	
	}
	


}

#------------------------------------------------------------[Exiting]-------------------------------------------------------------


