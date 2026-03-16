@echo off
REM Check production keystore fingerprints
REM Use these SHA fingerprints in Firebase Console

echo Select keystore to check:
echo 1. Debug keystore (default)
echo 2. Production keystore (bikeride-release.keystore)
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo Checking DEBUG keystore...
    echo ====================================
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -keystore "C:\Users\berog\.android\debug.keystore" -list -v -alias androiddebugkey -storepass android -keypass android
) else if "%choice%"=="2" (
    echo.
    set /p storepath="Enter keystore path (or press Enter for bikeride-release.keystore): "
    if "%storepath%"=="" set storepath=bikeride-release.keystore

    set /p storepass="Enter store password: "
    set /p keyalias="Enter key alias (or press Enter for 'bikeride'): "
    if "%keyalias%"=="" set keyalias=bikeride

    echo.
    echo Checking PRODUCTION keystore...
    echo ====================================
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -keystore "%storepath%" -list -v -alias %keyalias% -storepass %storepass%
) else (
    echo Invalid choice!
    pause
    exit /b
)

echo.
echo ====================================
echo Copy the SHA-1 and SHA-256 to:
echo 1. Firebase Console - Project Settings - Your Apps
echo 2. Google Cloud Console - API Restrictions
echo ====================================
echo.

pause