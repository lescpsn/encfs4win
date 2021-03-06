@ECHO OFF
SETLOCAL
Setlocal EnableDelayedExpansion
REM build-dokany.bat
REM *****************************************************************************
REM Author:   Charles Munson <jetwhiz@jetwhiz.com>
REM 
REM ****************************************************************************
REM Copyright (c) 2016, Charles Munson
REM 
REM This program is free software: you can redistribute it and/or modify it
REM under the terms of the GNU Lesser General Public License as published by the
REM Free Software Foundation, either version 3 of the License, or (at your
REM option) any later version.
REM 
REM This program is distributed in the hope that it will be useful, but WITHOUT
REM ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
REM FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
REM for more details.
REM 
REM You should have received a copy of the GNU Lesser General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.


REM versioning variables 
set SOURCE_URI=https://github.com/dokan-dev/dokany.git

REM Allow user to choose to use legacy dokan or not 
set USE_LEGACY_DOKAN=

REM provide legacy dokan support 
if defined USE_LEGACY_DOKAN (
  set VERSION=v0.7.4
  set VERSION_STR=0.7.4
) else (
  set VERSION=v1.0.3
  set VERSION_STR=1.0.3
)



REM ========= DO NOT EDIT BELOW THIS LINE =====================



REM set up some globally-constant settings
set SRC_DIR_NAME=dokan


REM don't bother if they already have an installation
if defined DOKAN_ROOT (
  if exist "%DOKAN_ROOT%\Win32\Release\dokan1.lib" (
    if exist "%DOKAN_ROOT%\Win32\Release\dokanfuse1.lib" (goto :already_installed)
  )
)


REM Failed to find dokan -- ask user if they want us to build it for them
echo.
if "%INTERACTIVE%"=="1" (
    SET /P CONFIRM_BUILD="Dokan (DOKAN_ROOT) was not detected.  Should we install it now? (Y/n): "
    if /I NOT "!CONFIRM_BUILD!"=="y" exit /b 1
)


REM move into deps folder 
if NOT exist "deps" mkdir deps
pushd deps


REM Clone git repository and switch to VERSION release 
echo.
echo ==================================================
echo             CLONING DOKANY REPOSITORY (%VERSION%)            
echo ==================================================
git clone %SOURCE_URI% %SRC_DIR_NAME% > %SRC_DIR_NAME%-clone.log
pushd %SRC_DIR_NAME%
git clean -ffdx
git reset --hard %VERSION%
git checkout %VERSION%

REM upgrade legacy solution 
if defined USE_LEGACY_DOKAN (
  echo.
  echo ~~~~~ Upgrading legacy solution ~~~~~
  echo.
  cmd /c devenv "dokan.sln" /upgrade
)

REM build libraries 
echo.
echo ==================================================
echo              BUILDING DOKANY LIBRARIES             
echo ==================================================
if defined USE_LEGACY_DOKAN (
  msbuild dokan.sln /p:PlatformToolset=v140  /p:ForceImportBeforeCppTargets="%DEPS_DIR%\dokan-legacy.props" /p:Configuration=Release /p:Platform=Win32 /t:Clean,Build
) else (
  msbuild dokan.sln /p:Configuration=Release /p:Platform=Win32 /t:Clean,Build
)

REM verify necessary libraries were successfully built 
if defined USE_LEGACY_DOKAN (
  if NOT exist ".\Win32\Release\dokan.lib" goto :build_failure
  if NOT exist ".\Win32\Release\dokanfuse.lib" goto :build_failure
  copy ".\Win32\Release\dokan.lib" ".\Win32\Release\dokan1.lib"
  copy ".\Win32\Release\dokanfuse.lib" ".\Win32\Release\dokanfuse1.lib"
) else (
  if NOT exist ".\Win32\Release\dokan1.lib" goto :build_failure
  if NOT exist ".\Win32\Release\dokan1.dll" goto :build_failure
  if NOT exist ".\Win32\Release\dokanfuse1.lib" goto :build_failure
  if NOT exist ".\Win32\Release\dokanfuse1.dll" goto :build_failure
)

REM set DOKAN_ROOT environment variable 
endlocal & set DOKAN_ROOT=%CD%
setx DOKAN_ROOT "%DOKAN_ROOT%"

goto :build_success



:build_success

echo.
echo ==================================================
echo      Dokan library successfully installed! 
echo ==================================================
echo.

goto :build_end



:build_failure

echo.
echo ==================================================
echo     Failed to build necessary Dokan library! 
echo ==================================================
echo.
exit /b 1

goto :build_end



:already_installed

echo.
echo ==================================================
echo            Dokan already installed
echo ==================================================
echo.
exit /b 0

goto :build_end



:build_end
popd
popd
exit /b 0
