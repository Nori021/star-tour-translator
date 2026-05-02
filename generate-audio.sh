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
안녕하세요. 오늘 잘 부탁드립니다.
저는 오카무라입니다. 오늘 가이드를 맡고 있습니다.
죄송합니다. 저는 한국어를 못해서 이 앱으로 안내해 드리겠습니다.
질문에는 답변드리기 어려울 수 있습니다. 양해 부탁드립니다.
오늘은 별이 빛나는 하늘과 함께 손님을 촬영하는 '별 사진 촬영' 투어입니다.
돌아가실 때는 지금 오신 길로 돌아가 주세요.
지금부터 바다까지 안내해 드리겠습니다. 따라와 주세요.
가는 길이 조금 험하니 발밑을 조심해 주세요.
주변 나무에도 주의해 주세요.
자연 생물이 있으니 밟지 않도록 조심해 주세요.
운이 좋으면 야자집게도 볼 수 있습니다.
천천히 오셔도 괜찮습니다.
모래사장의 바위 위에 서 주세요.
모래사장의 바위에 앉아 주세요.
조금 더 중앙으로 모여 주세요.
한 팀당 5컷까지 촬영합니다.
이 패널에서 1번부터 7번까지 포즈를 골라 주세요.
다음 포즈로 넘어가겠습니다.
1번 포즈로 부탁드립니다. 뒷모습이에요.
2번 포즈로 부탁드립니다. 마주보기예요.
3번 포즈로 부탁드립니다. 정면에서 손가락으로 가리켜 주세요.
4번 포즈로 부탁드립니다. 뒷모습에서 손가락으로 가리켜 주세요.
5번 포즈로 부탁드립니다. 정면에서 하늘을 바라봐 주세요.
6번 포즈로 부탁드립니다. 단체로 각자 다른 방향을 봐 주세요.
7번 포즈로 부탁드립니다. 단체로 같은 방향을 봐 주세요.
'스타트'라고 하면 움직이지 말아 주세요.
'OK'라고 할 때까지 그대로 있어 주세요.
움직이면 사진이 흔들립니다.
숨을 참지 않으셔도 괜찮습니다.
별을 향해 손가락으로 가리켜 주세요.
손가락이 몸에 가려지지 않도록 해 주세요.
다른 사람과 겹치지 않도록 해 주세요.
조명을 켜겠습니다. 조금 눈부실 수 있습니다.
조명을 끄겠습니다.
한 번 더 찍겠습니다.
찍었습니다! 감사합니다.
조금 더 오른쪽으로 돌아 주세요.
조금 더 왼쪽으로 돌아 주세요.
손가락을 오른쪽으로 향해 주세요.
손가락을 위로 향해 주세요.
손가락을 왼쪽으로 향해 주세요.
턱을 올려 주세요.
턱을 내려 주세요.
조금 더 가까이 와 주세요.
조금 더 떨어져 주세요.
카메라 쪽을 봐 주세요.
카메라를 보지 마세요.
시선을 멀리 향해 주세요.
웃어 주세요.
자연스러운 표정으로 괜찮습니다.
한 장 남았습니다.
마지막 컷입니다.
이것으로 촬영을 마치겠습니다. 수고 많으셨습니다.
사진은 나중에 보내드리겠습니다.
오늘 감사했습니다.
조심히 돌아가세요.
움직이지 마세요. 위험합니다.
이쪽으로 오세요.
괜찮으세요?
잠시만 기다려 주세요.
PHRASES

echo "DONE"
echo "Total files: $(ls audio/*.mp3 2>/dev/null | wc -l | tr -d ' ')"
echo "Total size: $(du -sh audio | cut -f1)"
