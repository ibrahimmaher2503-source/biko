@echo off
REM Create production keystore for BikeRide
REM Run this once and store the keystore securely

"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v ^
  -storetype PKCS12 ^
  -keystore bikeride-release.keystore ^
  -alias bikeride ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -storepass YOUR_STORE_PASSWORD ^
  -keypass YOUR_KEY_PASSWORD ^
  -dname "CN=BikeRide, OU=Engineering, O=BikeRide, L=Cairo, ST=Cairo, C=EG"

echo.
echo ====================================
echo Production keystore created!
echo Location: bikeride-release.keystore
echo ====================================
echo.
echo IMPORTANT:
echo 1. Keep this file secure - DO NOT commit to Git
echo 2. Store passwords in a safe location
echo 3. Add to .gitignore
echo 4. Get SHA fingerprints with:
echo    keytool -keystore bikeride-release.keystore -list -v -alias bikeride
echo.

pause