#!/usr/bin/env python3
"""
Generate Korean TTS audio files for star-tour-translator using OpenAI TTS (shimmer voice).
Each phrase is hashed for stable file names. Existing files are skipped.

Usage:  OPENAI_API_KEY=sk-... python3 generate-audio.py
"""
import hashlib
import json
import os
import sys
import time
import urllib.request
import urllib.error

API_KEY = os.environ.get('OPENAI_API_KEY')
if not API_KEY:
    print('ERROR: OPENAI_API_KEY environment variable not set')
    sys.exit(1)

VOICE = 'shimmer'
MODEL = 'gpt-4o-mini-tts'
INSTRUCTIONS = (
    'Speak in a bright, clear, youthful Korean female tour guide voice. '
    'Pronounce naturally and gently. Slightly higher pitch, friendly and welcoming.'
)
OUT_DIR = 'audio'

# Korean phrases — must match index.html exactly
PHRASES = [
    "안녕하세요. 오늘 잘 부탁드립니다.",
    "저는 오카무라입니다. 오늘 가이드를 맡고 있습니다.",
    "죄송합니다. 저는 한국어를 못해서 이 앱으로 안내해 드리겠습니다.",
    "질문에는 답변드리기 어려울 수 있습니다. 양해 부탁드립니다.",
    "오늘은 별이 빛나는 하늘과 함께 손님을 촬영하는 '별 사진 촬영' 투어입니다.",
    "돌아가실 때는 지금 오신 길로 돌아가 주세요.",
    "지금부터 바다까지 안내해 드리겠습니다. 따라와 주세요.",
    "가는 길이 조금 험하니 발밑을 조심해 주세요.",
    "주변 나무에도 주의해 주세요.",
    "자연 생물이 있으니 밟지 않도록 조심해 주세요.",
    "운이 좋으면 야자집게도 볼 수 있습니다.",
    "천천히 오셔도 괜찮습니다.",
    "모래사장의 바위 위에 서 주세요.",
    "모래사장의 바위에 앉아 주세요.",
    "조금 더 중앙으로 모여 주세요.",
    "한 팀당 5컷까지 촬영합니다.",
    "이 패널에서 1번부터 7번까지 포즈를 골라 주세요.",
    "다음 포즈로 넘어가겠습니다.",
    "1번 포즈로 부탁드립니다. 뒷모습이에요.",
    "2번 포즈로 부탁드립니다. 마주보기예요.",
    "3번 포즈로 부탁드립니다. 정면에서 손가락으로 가리켜 주세요.",
    "4번 포즈로 부탁드립니다. 뒷모습에서 손가락으로 가리켜 주세요.",
    "5번 포즈로 부탁드립니다. 정면에서 하늘을 바라봐 주세요.",
    "6번 포즈로 부탁드립니다. 단체로 각자 다른 방향을 봐 주세요.",
    "7번 포즈로 부탁드립니다. 단체로 같은 방향을 봐 주세요.",
    "'스타트'라고 하면 움직이지 말아 주세요.",
    "'OK'라고 할 때까지 그대로 있어 주세요.",
    "움직이면 사진이 흔들립니다.",
    "숨을 참지 않으셔도 괜찮습니다.",
    "별을 향해 손가락으로 가리켜 주세요.",
    "손가락이 몸에 가려지지 않도록 해 주세요.",
    "다른 사람과 겹치지 않도록 해 주세요.",
    "조명을 켜겠습니다. 조금 눈부실 수 있습니다.",
    "조명을 끄겠습니다.",
    "한 번 더 찍겠습니다.",
    "찍었습니다! 감사합니다.",
    "조금 더 오른쪽으로 돌아 주세요.",
    "조금 더 왼쪽으로 돌아 주세요.",
    "손가락을 오른쪽으로 향해 주세요.",
    "손가락을 위로 향해 주세요.",
    "손가락을 왼쪽으로 향해 주세요.",
    "턱을 올려 주세요.",
    "턱을 내려 주세요.",
    "조금 더 가까이 와 주세요.",
    "조금 더 떨어져 주세요.",
    "카메라 쪽을 봐 주세요.",
    "카메라를 보지 마세요.",
    "시선을 멀리 향해 주세요.",
    "웃어 주세요.",
    "자연스러운 표정으로 괜찮습니다.",
    "한 장 남았습니다.",
    "마지막 컷입니다.",
    "이것으로 촬영을 마치겠습니다. 수고 많으셨습니다.",
    "사진은 나중에 보내드리겠습니다.",
    "오늘 감사했습니다.",
    "조심히 돌아가세요.",
    "움직이지 마세요. 위험합니다.",
    "이쪽으로 오세요.",
    "괜찮으세요?",
    "잠시만 기다려 주세요.",
]

def hash_id(text: str) -> str:
    return hashlib.sha1(text.encode('utf-8')).hexdigest()[:10]

def generate(text: str, out_path: str) -> int:
    body = json.dumps({
        'model': MODEL,
        'voice': VOICE,
        'input': text,
        'instructions': INSTRUCTIONS,
        'response_format': 'mp3',
    }).encode('utf-8')
    req = urllib.request.Request(
        'https://api.openai.com/v1/audio/speech',
        data=body,
        headers={
            'Authorization': f'Bearer {API_KEY}',
            'Content-Type': 'application/json',
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    with open(out_path, 'wb') as f:
        f.write(data)
    return len(data)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    mapping = {}
    skipped = 0
    generated = 0
    total_bytes = 0
    for ko in PHRASES:
        h = hash_id(ko)
        mapping[ko] = h
        out_path = os.path.join(OUT_DIR, f'{h}.mp3')
        if os.path.exists(out_path):
            print(f'  SKIP {h}  {ko[:40]}')
            skipped += 1
            continue
        try:
            n = generate(ko, out_path)
            print(f'  GEN  {h}  ({n:>6} bytes)  {ko[:40]}')
            generated += 1
            total_bytes += n
            time.sleep(0.15)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8', errors='replace')
            print(f'  ERR  {h}  HTTP {e.code}  {err_body[:120]}')
            sys.exit(1)
    with open('audio-map.json', 'w', encoding='utf-8') as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print()
    print(f'Generated: {generated}, Skipped: {skipped}, Total bytes: {total_bytes}')
    print(f'Mapping written to audio-map.json')

if __name__ == '__main__':
    main()
