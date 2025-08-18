@echo off
echo Starting OpenHands...
set LITELLM_API_KEY=openhands-key-2024
docker-compose up -d
echo.
echo OpenHands is starting up...
echo Access it at: http://localhost:8150
echo.
echo To stop OpenHands, run: docker-compose down
pause