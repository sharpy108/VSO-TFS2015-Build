[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    $teamProject,
    $targetStageName,
    $rmserver,
    $port,
    $userName,
    $password,
    $Domain)

"Starting Trigger RM step"

"Importing Modules"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"

"Collecting Parameter Information"

$teamFoundationServerUrl = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI 
$buildDefinition = $env:BUILD_DEFINITIONNAME
$buildNumber = $env:BUILD_BUILDNUMBER
$droplocation = $env:BUILD_DROPLOCATION

"Executing with the following parameters:`n"
"  RMserver Name: $rmserver"
"  Port number: $port"
"  Team Foundation Server URL: $teamFoundationServerUrl"
"  Team Project: $teamProject"
"  Build Definition: $buildDefinition"
"  Build Number: $buildNumber"
"  Drop Location: $dropLocation"
"  Target Stage Name: $targetStageName`n"

# Use if you want to see all environment variables
#Get-Childitem env:

$exitCode = 0

trap
{
  $e = $error[0].Exception
  $e.Message
  $e.StackTrace
  if ($exitCode -eq 0) { $exitCode = 1 }
}

$scriptName = $MyInvocation.MyCommand.Name

"Executing Script $scriptName"

$scriptPath = Split-Path -Parent (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path

"On path $scriptPath"

Push-Location $scriptPath    

$server = [System.Uri]::EscapeDataString($teamFoundationServerUrl)
$project = [System.Uri]::EscapeDataString($teamProject)
$definition = [System.Uri]::EscapeDataString($buildDefinition)
$build = [System.Uri]::EscapeDataString($buildNumber)
$targetStage = [System.Uri]::EscapeDataString($targetStageName)

$serverName = $rmserver + ":" + $port
$orchestratorService = "http://$serverName/account/releaseManagementService/_apis/releaseManagement/OrchestratorService"

$uri = "$orchestratorService/InitiateReleaseFromBuild?teamFoundationServerUrl=$server&teamProject=$project&buildDefinition=$definition&buildNumber=$build&targetStageName=$targetStage"
"Executing the following API call:`n`n$uri"

$status = @{
    "2" = "InProgress";
    "3" = "Released";
    "4" = "Stopped";
    "5" = "Rejected";
    "6" = "Abandoned";
}

$wc = New-Object System.Net.WebClient
#$wc.UseDefaultCredentials = $true
# rmuser should be part rm users list and he should have permission to trigger the release.

$wc.Credentials = new-object System.Net.NetworkCredential($userName, $password, $Domain)

try
{
    $releaseId = $wc.DownloadString($uri)

    $url = "$orchestratorService/ReleaseStatus?releaseId=$releaseId"

    $releaseStatus = $wc.DownloadString($url)

    Write-Host -NoNewline "Submitted Release..."

}
catch [System.Exception]
{
    if ($exitCode -eq 0) { $exitCode = 1 }
    Write-Host "`n$_`n" -ForegroundColor Red
}

if ($exitCode -eq 0)
{
  "`nThe script completed successfully.`n"
}
else
{
  $err = "Exiting with error: " + $exitCode + "`n"
  Write-Host $err -ForegroundColor Red
}

Pop-Location

exit $exitCode





