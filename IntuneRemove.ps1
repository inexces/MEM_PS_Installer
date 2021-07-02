<#
.SYNOPSIS
  This script performs the uninstallation

.DESCRIPTION
  This script is a framework and standardisation for installing apps focussed on Intune.
  
.OUTPUTS
  Registry Entry: HKLM\SOFTWARE\[BrandName]\Packages\

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

#---------------------------------------------------------[Functions]------------------------------------------------------------

Function WriteEventlog {
		Param ( 
			[Parameter(Mandatory=$true)]
			[string]$GetMessage
		)
		$writemessage = "IntuneSetup: " + $Package + " - " + $GetMessage
		Write-EventLog -LogName $($Settings.config.BrandName) -Source $Package -EventID 1 -EntryType "Information" -Message $writemessage -Category 1
}

Function UnregisterInstallation() {
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
}

#---------------------------------------------------------[Execution]------------------------------------------------------------

																						                           $Error.Clear()
																			  WriteEventlog -GetMessage "Starting Uninstallation"
#[Uninstallation]------------------------------------------------------------------------------------------------[Uninstallation]

#[/Uninstallation]----------------------------------------------------------------------------------------------[/Uninstallation]
																		     WriteEventlog -GetMessage "Finishing Uninstallation"

	If ($Error.Count -gt 0) {
		UnregisterInstallation -ErrorLevel 101
	} else {
		UnregisterInstallation -ErrorLevel 0	
	}

#------------------------------------------------------------[Exiting]-------------------------------------------------------------