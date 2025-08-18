@echo off
echo Destroying OpenHands Infrastructure...
echo.

cd /d "%~dp0\.."

echo Step 1: Destroying EC2 instance...
terraform destroy -target=aws_instance.openhands -auto-approve

echo.
echo Step 2: Destroying security group rules...
terraform destroy -target=aws_security_group_rule.ssh -auto-approve
terraform destroy -target=aws_security_group_rule.openhands_web -auto-approve
terraform destroy -target=aws_security_group_rule.outbound -auto-approve

echo.
echo Step 3: Destroying security group...
terraform destroy -target=aws_security_group.openhands -auto-approve

echo.
echo Step 4: Destroying remaining infrastructure...
terraform destroy -auto-approve

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Infrastructure destroyed successfully!
    echo ===============================================
) else (
    echo.
    echo Destruction failed. Check the error messages above.
)

pause