# Set your AWS SSO profile name here
# Example format: sso-<ACCOUNT_ID>-<ROLE_NAME>
$env:AWS_PROFILE = "YOUR_AWS_PROFILE_NAME_HERE"
Write-Host "AWS Profile set to:" $env:AWS_PROFILE
Write-Host ""
Write-Host "NOTE: Edit this file and replace YOUR_AWS_PROFILE_NAME_HERE with your actual AWS SSO profile name."
Write-Host "You can find your profile name by running: aws configure list-profiles"
