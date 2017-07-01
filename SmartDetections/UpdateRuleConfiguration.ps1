#
# This script will configure your Azure Application Insights Smart Detection rules.
# You can enabled/disable the rule, set whether to send emails to owners, contributers and readers, and add custom email addresses that will get the emails.
# You can read more about it here: https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-diagnostics
#

# mandatory resource parameters
$subscription = ""
$resourceGroup = ""
$appName = ""

# rule configuration
$ruleName = "slowserverresponsetime" # should be one of: slowserverresponsetime, longdependencyduration, slowpageloadtime, degradationinserverresponsetime, degradationindependencyduration
$enabled = $true
$sendEmailsToSubscriptionOwners = $true
$customEmails = @();

# authentication parameters
$tenantName = ""

# create the autoherization token (manual approach)
# taken from: https://blogs.technet.microsoft.com/paulomarques/2016/03/21/working-with-azure-active-directory-graph-api-from-powershell/
# for full automation, the token will need to be retrieved by a non-manual approach
function GetAuthToken {
    param
    (
        [Parameter(Mandatory = $true)]
        $TenantName
    )
 
    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll" 
    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll" 
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null 
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
 
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"  
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob" 
    $resourceAppIdURI = "https://management.azure.com/" 
    $authority = "https://login.windows.net/$TenantName" 
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority 
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
 
    return $authResult
}

$token = GetAuthToken -TenantName $tenantName
$authHeader = @{
    'Authorization' = $token.CreateAuthorizationHeader()
}

$uri = "https://management.azure.com/subscriptions/$($subscription)/resourcegroups/$($resourceGroup)/providers/microsoft.insights/components/$($appName)/ProactiveDetectionConfigs?ConfigurationId=$($ruleName)&api-version=2015-05-01"

$body = @{
    "name"                           = $ruleName;
    "enabled"                        = $enabled;
    "sendEmailsToSubscriptionOwners" = $sendEmailsToSubscriptionOwners;
    "customEmails"                   = $customEmails;
}

$bodyJson = $body | ConvertTo-Json

Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Put -Body $bodyJson -ContentType "application/json"