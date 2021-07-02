<#
.SYNOPSIS
  This script performs the installation

.DESCRIPTION
  This script is a framework and standardisation for installing apps focussed on Intune.
  
.OUTPUTS
  Registry Entry: HKLM\SOFTWARE\BrandName\Packages\

.NOTES
- Version:        1.9
- Author:         Marcus Jaken ~ Microsoft Consultant @ Advantive B.V
				  Twitter: @marcusjaken
- Creation Date:  2021
  
#>

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
		New-Item -Path Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)" -type Directory -Force -ErrorAction SilentlyContinue
		new-itemproperty Registry::"HKLM\SOFTWARE\$($Settings.config.BrandName)\Packages\$($Settings.config.App.Packagename)\$($Settings.config.App.AppVersion)\$($Settings.config.App.PackVersion)" -Name "Installed" -Value $Present -PropertyType String -Force -ErrorAction SilentlyContinue
	} Else {
		WriteEventlog -GetMessage "Error during installation $Error, total errors: $($error.count)"
	}
EXIT $ErrorLevel
}

#---------------------------------------------------------[Execution]------------------------------------------------------------

																				WriteEventlog -GetMessage "Starting Prerequisits"
#[Prerequisits]----------------------------------------------------------------------------------------------------[Prerequisits]

#[/Prerequisits]--------------------------------------------------------------------------------------------------[/Prerequisits]
																			   WriteEventlog -GetMessage "Finishing Prerequisits"
																			   									   $Error.Clear()
		
																				WriteEventlog -GetMessage "Starting Installation"
#[Instalation]------------------------------------------------------------------------------------------------------[Instalation]
		
#[/Instalation]----------------------------------------------------------------------------------------------------[/Instalation]
																			   WriteEventlog -GetMessage "Finishing Installation"		

	If ($Error.Count -gt 0) {
		RegisterInstallation -ErrorLevel 101
	} else {
		RegisterInstallation -ErrorLevel 0
	}

#------------------------------------------------------------[Exiting]-------------------------------------------------------------