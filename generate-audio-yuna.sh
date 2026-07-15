#!/bin/bash
# Generate Korean TTS audio using macOS built-in "Yuna" voice (free, offline).
# Output: AAC in .m4a container (small, plays on iOS Safari + Web Audio API).
# Usage: bash generate-audio-yuna.sh

set -e

VOICE="Yuna"
RATE=175   # words per minute (default-ish; app also has speed control)

mkdir -p audio
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

generate() {
  local text="$1"
  local hash=$(printf '%s' "$text" | shasum -a 1 | cut -c1-10)
  local out="audio/$hash.m4a"
  say -v "$VOICE" -r "$RATE" -o "$TMP/tmp.aiff" "$text"
  afconvert -f m4af -d aac -b 64000 "$TMP/tmp.aiff" "$out" >/dev/null 2>&1
  local size=$(wc -c < "$out" | tr -d ' ')
  printf "  GEN  %s  (%s bytes)  %s\n" "$hash" "$size" "${text:0:34}"
  echo "$hash|$text" >> audio-map.txt
}

> audio-map.txt

while IFS= read -r line; do
  [ -z "$line" ] && continue
  generate "$line"
done <<'PHRASES'
처음 뵙겠습니다. 이번 촬영을 담당하는 오카무라라고 합니다.
저는 한국어를 못해서 번역 앱으로 말씀드리겠습니다.
별 사진 촬영은 몇 초간 멈춰 주셔야 하니 잘 부탁드립니다.
'레디, 스타트'라고 하면 멈춰 주세요. 끝나면 'OK'라고 말씀드립니다.
구름이 끼어 있어서 잠시만 기다려 주세요.
사진이 흔들렸어요.
촬영이 끝났습니다.
은하수가 저쪽에 보이니까 이쪽 방향으로 서 주세요.
카메라와 나란히 서 주세요.
안녕하세요. 오늘 별 사진 촬영을 담당하는 오카무라입니다.
촬영 매수는 인원수에 따라 달라집니다. 어른 두 분이면 다섯 장이고, 어른이 한 분 늘 때마다 한 장씩 늘어납니다.
별 사진은 움직이면 흔들리기 때문에, 약 6초간 멈춰 주셔야 합니다.
'레디, 스타트'라고 하면 멈춰 주세요. 'OK'라고 할 때까지 그대로 계셔 주세요.
카메라 설정상, 하늘과 인물 둘 다에 초점을 맞출 수는 없습니다. 기본적으로 하늘에 초점을 맞춥니다.
평소에는 인물을 조금 어둡게 촬영합니다. 밝게 하고 싶으시면 말씀해 주세요.
저는 한국어를 못해서, 번역 앱을 사용해 대화하겠습니다.
별 사진은 날씨와의 싸움입니다. 구름이 끼면 시간이 걸릴 수 있습니다.
날씨가 좋지 않은 경우에는 촬영이 취소될 수도 있습니다. 미리 양해 부탁드립니다.
이곳은 빛이 전혀 없고 자연이 풍부한 곳이라, 별이 아주 아름답게 보입니다.
그만큼 벌레가 나옵니다. 벌레 기피제를 준비해 두었으니, 자유롭게 사용해 주세요.
저것이 은하수입니다. 수많은 별이 모여 강처럼 보입니다.
저것이 북두칠성입니다. 일곱 개의 별이 국자 모양으로 늘어서 있습니다.
저것이 북극성입니다. 항상 북쪽에 있고, 움직이지 않는 별입니다.
저것이 견우와 직녀입니다. 칠석 전설 속, 1년에 한 번만 만날 수 있는 별입니다.
PHRASES

echo "DONE"
echo "Total files: $(ls audio/*.m4a 2>/dev/null | wc -l | tr -d ' ')"
echo "Total size: $(du -sh audio | cut -f1)"
