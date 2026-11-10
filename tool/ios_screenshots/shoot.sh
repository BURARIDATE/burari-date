#!/bin/zsh
# iOSのシミュレーターで、結合テスト(integration_test/)を動かし、「SNAP:<名前>」の合図ごとに撮る。
# 使い方: tool/ios_screenshots/shoot.sh <シミュレーターのUDID> <出力先> [テストのファイル]
#   ストア用: integration_test/store_screenshots_test.dart(既定)
#   全画面の通し: integration_test/full_walkthrough_test.dart
# ステータスバーは9:41・電池満タンに整える。手順は docs/iOSリリース手順.md を参照。
U=$1; OUT=$2; LOG=$OUT/run.log
mkdir -p $OUT; OUT=$(cd $OUT && pwd); LOG=$OUT/run.log; : > $LOG
xcrun simctl terminate $U com.buraridate.burariDate 2>/dev/null
xcrun simctl uninstall $U com.buraridate.burariDate 2>/dev/null
xcrun simctl status_bar $U override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
cd "$(dirname "$0")/../.."
flutter test ${3:-integration_test/store_screenshots_test.dart} --flavor prod -d $U > $LOG 2>&1 &
PID=$!
seen=""
while kill -0 $PID 2>/dev/null; do
  for name in $(grep -o 'SNAP:[0-9a-z_]*' $LOG | cut -d: -f2); do
    if [[ " $seen " != *" $name "* ]]; then
      if [[ $name != 03_* ]]; then
        xcrun simctl status_bar $U override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
        sleep 1
      fi
      xcrun simctl io $U screenshot $OUT/$name.png >/dev/null 2>&1
      seen="$seen $name"
      echo "shot $name"
    fi
  done
  sleep 0.1
done
wait $PID; echo "exit $?"
xcrun simctl status_bar $U clear
tail -5 $LOG
