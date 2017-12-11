function Add-ITGlueAPIKey {
        Write-Host "Setting APIKey:"
		$apikey = "INSERT_API_KEY_HERE"
		$encapikey = ConvertTo-SecureString $apikey -asplaintext -force
        $x_api_key =   $encapikey

        Set-Variable -Name "ITGlue_API_Key"  -Value $x_api_key -Option ReadOnly -Scope global -Force
}


function Remove-ITGlueAPIKey {
    Remove-Variable -Name "ITGlue_API_Key"  -Force  
}

function Get-ITGlueAPIKey {
    $ITGlue_API_Key
    Write-Host "Use Get-ITGlueAPIKey -Force to retrieve the unencrypted copy." -ForegroundColor "Red"
}

New-Alias -Name Set-ITGlueAPIKey -Value Add-ITGlueAPIKey