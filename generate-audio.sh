#!/bin/bash
# Generate Korean TTS audio using OpenAI shimmer voice
# Usage: OPENAI_API_KEY=sk-... bash generate-audio.sh

set -e

if [ -z "$OPENAI_API_KEY" ]; then
  echo "ERROR: OPENAI_API_KEY not set"; exit 1
fi

mkdir -p audio

INSTRUCTIONS='Speak in a bright, clear, youthful Korean female tour guide voice. Pronounce naturally and gently. Slightly higher pitch, friendly and welcoming.'

generate() {
  local text="$1"
  local hash=$(printf '%s' "$text" | shasum -a 1 | cut -c1-10)
  local out="audio/$hash.mp3"
  if [ -f "$out" ]; then
    echo "  SKIP $hash  ${text:0:40}"
    echo "$hash|$text" >> audio-map.txt
    return
  fi
  local payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'gpt-4o-mini-tts',
  'voice':'shimmer',
  'input':sys.argv[1],
  'instructions':sys.argv[2],
  'response_format':'mp3'
}))" "$text" "$INSTRUCTIONS")
  local code=$(curl -s -o "$out" -w "%{http_code}" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://api.openai.com/v1/audio/speech)
  if [ "$code" = "200" ]; then
    local size=$(wc -c < "$out" | tr -d ' ')
    printf "  GEN  %s  (%s bytes)  %s\n" "$hash" "$size" "${text:0:40}"
    echo "$hash|$text" >> audio-map.txt
    sleep 0.15
  else
    echo "  ERR  $hash  HTTP $code"
    cat "$out"; rm -f "$out"
    exit 1
  fi
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
PHRASES

echo "DONE"
echo "Total files: $(ls audio/*.mp3 2>/dev/null | wc -l | tr -d ' ')"
echo "Total size: $(du -sh audio | cut -f1)"
