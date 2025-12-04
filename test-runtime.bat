@echo off
echo Testing OpenHands runtime image...

echo.
echo Testing ghcr.io/all-hands-ai/runtime:0.62-nikolaik
docker run --rm ghcr.io/all-hands-ai/runtime:0.62-nikolaik /bin/bash -c "echo 'Runtime test successful' && ls -la /openhands/micromamba/bin/micromamba"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Trying alternative runtime: ghcr.io/all-hands-ai/runtime:0.62.0
    docker run --rm ghcr.io/all-hands-ai/runtime:0.62.0 /bin/bash -c "echo 'Runtime test successful' && ls -la /openhands/micromamba/bin/micromamba"
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Trying latest runtime
        docker run --rm ghcr.io/all-hands-ai/runtime:latest /bin/bash -c "echo 'Runtime test successful' && ls -la /openhands/micromamba/bin/micromamba"
    )
)

echo.
echo Runtime test complete.
pause