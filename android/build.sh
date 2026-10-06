#!/usr/bin/env bash
# BallFot APK derleme betiği (Gradle gerektirmez).
# Gerekenler: JDK 17+, Android SDK (platforms;android-34 ve build-tools).
#   export ANDROID_HOME=~/Android/Sdk
#   ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

: "${ANDROID_HOME:?ANDROID_HOME ayarlı değil (Android SDK klasörü)}"
BT="${BUILD_TOOLS:-$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)}"
JAR="$ANDROID_HOME/platforms/android-34/android.jar"
KS="${KEYSTORE:-$HOME/.android/debug.keystore}"
KS_PASS="${KEYSTORE_PASS:-android}"

rm -rf out assets && mkdir -p out/classes assets
cp ../index.html assets/index.html

"$BT/aapt2" compile --dir res -o out/res.zip
"$BT/aapt2" link -o out/unsigned.apk -I "$JAR" --manifest AndroidManifest.xml -A assets \
  --min-sdk-version 23 --target-sdk-version 34 --version-code 1 --version-name 1.0 out/res.zip

javac --release 8 -nowarn -cp "$JAR" -d out/classes src/com/ballfot/app/MainActivity.java
"$BT/d8" --min-api 23 --lib "$JAR" --output out $(find out/classes -name '*.class')
(cd out && zip -qj unsigned.apk classes.dex)

"$BT/zipalign" -f 4 out/unsigned.apk out/aligned.apk
"$BT/apksigner" sign --ks "$KS" --ks-pass "pass:$KS_PASS" --out out/BallFot.apk out/aligned.apk
"$BT/apksigner" verify out/BallFot.apk
echo "Hazır: android/out/BallFot.apk"
