@echo off
REM Set your AWS SSO profile name here
REM Example format: sso-<ACCOUNT_ID>-<ROLE_NAME>
set AWS_PROFILE=YOUR_AWS_PROFILE_NAME_HERE
echo AWS Profile set to: %AWS_PROFILE%
echo.
echo NOTE: Edit this file and replace YOUR_AWS_PROFILE_NAME_HERE with your actual AWS SSO profile name.
echo You can find your profile name by running: aws configure list-profiles
