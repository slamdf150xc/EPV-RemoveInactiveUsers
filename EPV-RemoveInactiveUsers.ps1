################################### GET-HELP #############################################
<#
.SYNOPSIS
 	This script will read the raw Active/Non-Active Users report from the PrivateArk client
	and then remove any "External User" listed in that report.
 
.EXAMPLE
 	.\EPV-RemoveUser.ps1
 
.INPUTS
	Prompts:
		User to log into the vault with
		Password for user
	
.OUTPUTS
	None
	
.NOTES
	AUTHOR:  
	Randy Brown

	VERSION HISTORY:
	1.0 3/13/2019 - Initial release
#>
##########################################################################################

######################## IMPORT MODULES/ASSEMBLY LOADING #################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

######################### GLOBAL VARIABLE DECLARATIONS ###################################

$baseURL = "https://components.cyberarkdemo.com/PasswordVault"

########################## START FUNCTIONS ###############################################

Function EPV-Login($user, $pass) {
	
	$data = @{
		username=$user
		password=$pass
		useRadiusAuthentication=$false
	}
	
	$loginData = $data | ConvertTo-Json
		
	$ret = Invoke-RestMethod -Uri "$baseURL/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon" -Method POST -Body $loginData -ContentType 'application/json'
	
	return $ret
}

Function EPV-Logoff {	
	Invoke-RestMethod -Uri "$baseURL/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logoff" -Method Post -Headers $header -ContentType 'application/json'
}

Function EPV-RemoveUser($userToRemove) {
	Invoke-RestMethod -Uri "$baseURL/WebServices/PIMServices.svc/Users/$userToRemove" -Method Delete -Headers $header -ContentType 'application/json'
}

Function Get-FileName {   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.filter = "TXT files (*.txt)| *.txt"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}

########################## END FUNCTIONS #################################################

########################## MAIN SCRIPT BLOCK #############################################

$users = Import-Csv -Path (Get-FileName)

$login_User = Read-Host "CyberArk Vault Login UserID"
$login_PW = Read-Host "Password" -AsSecureString

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($login_PW)
$login_Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$login = EPV-Login $login_User $login_Password
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Authorization", $login.CyberArkLogonResult)

ForEach ($user in $users) {
	If ($user.Type.ToLower() -eq "external user") {
		EPV-RemoveUser $user.User
	}
}

EPV-Logoff

########################### END SCRIPT ###################################################
