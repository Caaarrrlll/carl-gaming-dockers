@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%\.."

call :buildpush "images\debian-base" "caaarrrlll/debian-slim-baseimage:trixie-latest" || goto error
call :buildpush "images\fedora-base" "caaarrrlll/fedora-baseimage:latest" || goto error
call :buildpush "images\wine-base" "caaarrrlll/wine-baseimage:latest" || goto error
call :buildpush "images\asa-docker" "caaarrrlll/asa-wine:latest" || goto error
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
