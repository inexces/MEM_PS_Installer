<#
.SYNOPSIS
  This script performs the installation or uninstallation of [PACKAGENAME]

.DESCRIPTION
  This script is a framework and standardisation for installing apps focussed on Intune.
  It performs an install or uninstall depending on the "type" parameter.
  
.INPUTS
  -Type		The type of deployment to perform. Options: [Install, Uninstall]. Default is: Install.

.OUTPUTS
  Registry Entry: HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\
  Eventlog Entry: in BrandName log

.EXAMPLE
  powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1"
  powershell.exe -executionpolicy bypass -noprofile -noninteractive -file ".\IntuneSetup.ps1" -Type "Uninstall"
	
.NOTES
- Version:        1.8.3
- Author:         Ã¢Â«Â»Ã¢Â«Â»Ã¢Â«Â½ Marcus Jaken ~ Microsoft Ã¢ËœÂ Consultant @ Advantive B.V Ã¢Â«Â½Ã¢Â«Â»Ã¢Â«Â»
				  Twitter: @marcusjaken
- Creation Date:  2021
  
#>

param(
    $type = "Install"
    )

#----------------------------------------------------[Run script in 64bit]-------------------------------------------------------

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
	Try { &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH }
	Catch { Throw "Failed to start $PSCOMMANDPATH" }
	Exit
}

#-----------------------------------------------------------[Input]--------------------------------------------------------------

## Load the Config.xml
[Xml]$Settings = Get-Content "$($PSScriptRoot)\IntuneConfig.xml"
$Present = Get-Date -Format "yyyy/MM/dd HH:mm"
$Package = $($Settings.config.App.Packagename) + " " + $($Settings.config.App.AppVersion)
$MessageInput =  "Setting Variables for $($Settings.config.BrandName); $($Settings.config.App.Packagename), $($Settings.config.App.AppVersion), Install folder: $PSScriptRoot"

#-------------------------------------------------------[Initialisation]---------------------------------------------------------

#Create Company-directory & Eventlog
New-EventLog -LogName $($Settings.config.BrandName) -Source $Package -ErrorAction SilentlyContinue

#---------------------------------------------------------[Functions]------------------------------------------------------------

If ($Settings.config.log -eq '1') { Function WriteEventlog {
		Param ( 
			[Parameter(Mandatory=$true)]
			[string]$GetMessage
		)
		$writemessage = "IntuneSetup: " + $Package + " - " + $GetMessage
		Write-EventLog -LogName $($Settings.config.BrandName) -Source $Package -EventID 1 -EntryType "Information" -Message $writemessage -Category 1
} }

If ($Settings.config.SetReg -eq '1') { Function RegisterInstallation() {
	Param(
		[Parameter(Mandatory=$True)][String]$ErrorLevel
	)
	If ($ErrorLevel -eq "0") {
		WriteEventlog -GetMessage "Create Registry installation key HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$Package"
		New-Item -Path Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)" -type Directory -Force -ErrorAction SilentlyContinue
		new-itemproperty Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)" -Name "Installed" -Value $Present -PropertyType String -Force -ErrorAction SilentlyContinue
	} Else {
		WriteEventlog -GetMessage "Error during installation $Error, total errors: $($error.count)"
	}
EXIT $ErrorLevel
} }

If ($Settings.config.SetReg -eq '1') { Function UnregisterInstallation() {
	Param(
		[Parameter(Mandatory=$True)][String]$ErrorLevel
	)
	If ($ErrorLevel -eq "0") {
		WriteEventlog -GetMessage "Deleted Registry installation key HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)"
		Remove-Item -Path Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)" -Force
		new-itemproperty Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)" -Name "Uninstalled" -Value $Present -PropertyType String -Force -ErrorAction SilentlyContinue
    } Else {
		WriteEventlog -GetMessage "Error during uninstallation $Error, total errors: $($error.count)"
	}
EXIT $ErrorLevel
} }

#---------------------------------------------------------[Execution]------------------------------------------------------------

WriteEventlog -GetMessage $MessageInput

If ($Type -eq 'Install') {
																				WriteEventlog -GetMessage "Starting Prerequisits"
#[Prerequisits]----------------------------------------------------------------------------------------------------[Prerequisits]

#[/Prerequisits]--------------------------------------------------------------------------------------------------[/Prerequisits]
																			   WriteEventlog -GetMessage "Finishing Prerequisits"
																			   									   $Error.Clear()
		
																				WriteEventlog -GetMessage "Starting Installation"
#[Instalation]------------------------------------------------------------------------------------------------------[Instalation]

	if(!(Test-Path "c:\installation")) { 
		New-Item -Path "c:\" -Name "installation" -ItemType "directory" -Force -ErrorAction SilentlyContinue
		$MessageInitialisation = "Created `"$($env:ProgramData)\$($Settings.config.BrandName)`""
	}
		
#[/Instalation]----------------------------------------------------------------------------------------------------[/Instalation]
																			   WriteEventlog -GetMessage "Finishing Installation"		

		If ($Error.Count -gt 0) {
			RegisterInstallation -ErrorLevel 101
		} else {
			RegisterInstallation -ErrorLevel 0
		}

}


ElseIf ($Type -eq 'Uninstall') {
																						                           $Error.Clear()
																			  WriteEventlog -GetMessage "Starting Uninstallation"
#[Uninstallation]------------------------------------------------------------------------------------------------[Uninstallation]

	if(!(Test-Path "c:\uninstallation")) { 
		New-Item -Path "c:\" -Name "uninstallation" -ItemType "directory" -Force -ErrorAction SilentlyContinue
		$MessageInitialisation = "Created `"$($env:ProgramData)\$($Settings.config.BrandName)`""
	}

#[/Uninstallation]----------------------------------------------------------------------------------------------[/Uninstallation]
																		     WriteEventlog -GetMessage "Finishing Uninstallation"

	If ($Error.Count -gt 0) {
		UnregisterInstallation -ErrorLevel 101
	} else {
		UnregisterInstallation -ErrorLevel 0	
	}
	
}

#------------------------------------------------------------[Exiting]-------------------------------------------------------------