@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%\.."

if not defined DOCKERHUB_USER (
    echo.
    echo Error: DOCKERHUB_USER is not set.
    echo Set it to your Docker Hub username, e.g. set DOCKERHUB_USER=myuser
    endlocal
    exit /b 1
)

call :buildpush "images\systems\debian-base" "%DOCKERHUB_USER%/debian-slim-baseimage:trixie-latest" || goto error
call :buildpush "images\systems\fedora-base" "%DOCKERHUB_USER%/fedora-baseimage:latest" || goto error
call :buildpush "images\systems\wine-base" "%DOCKERHUB_USER%/wine-baseimage:latest" || goto error
call :buildpush "images\games\asa-docker" "%DOCKERHUB_USER%/asa-wine:latest" || goto error
goto end

:buildpush
echo.
echo === Building %~1 ===
pushd "%~1"
docker image build -t "%~2" .
if errorlevel 1 (
    popd
    exit /b 1
)
docker image push "%~2"
if errorlevel 1 (
    popd
    exit /b 1
)
popd
exit /b 0

:error
echo.
echo Build/push failed.
endlocal
exit /b 1

:end
echo.
echo All images built and pushed.
endlocal
exit /b 0
