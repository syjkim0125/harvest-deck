# Handoff — v0.6 / 2026-11-17 KST

## 기준 / 보존
Library libfile_e5fb49d15230819192d425860e2c9edd 최신version4를 새로 가져옴.
입력ZIP SHA256 41a839dfdd7dab10d406844bac7cf617f481682d714877bdb8684aced07c5d50.
expected_current_version=4로 동일ZIP 교체. checkpoints/g1-v0.1.zip 그대로 보존.
Godot4.6.3/GDScript. 저장소/Sites 변경 없음.

## 실제 코드 변경
- G2 production.upgrade_mixer(): 회수 지갑40 차감/spent_cash 기록/중복 구매 방지.
  단일 믹서0.45→0.25초/개. 추가 병렬 믹서가 아님.
- 진행 중 작업의 완료 비율을 유지해 mix_elapsed를 새 시간으로 환산.
  재료종류/대기재고/완제품/고객/돈을 삭제하거나 중복 생성하지 않음.
- 산호색 강화패드(460,310),반경80 내 F키 또는 고정HUD 버튼으로 구매.
  pause/거리/자금/이미강화 조건으로 입력과 버튼을 각각 보호.
- 믹서 도형/회전날/강화 후 색변경 및 실제 mix_duration 기반 진행바.
  가게 제목과 믹서가 겹치지 않도록 제목 위치/폰트 정리.
- 실제 버그 회귀: _unhandled_input에서만 touch release를 받으면 UI위 놓기를 놓쳐
  drag가 유지될 수 있음. raw _input에서 활성index의 release를 먼저 해제.
  press는 여전히 UI가 소비한 후 unhandled일 때만 이동 시작.

## 명령 / 실제 결과
프로젝트루트:
`godot --headless --path . --editor --import --quit` PASS
`godot --headless --path . --script tests/run.gd` 99 checks /0 failures
`godot --headless --path . --script tests/feel_replay.gd` 5조건 PASS
`godot --headless --path . --quit-after 120` PASS
로그 docs/*-output.txt. 기존82개 통과 후 터치해제 회귀를 추가하니83개 중1개실패;
입력 수정+시설 검사 추가 후99개 통과.
기본/강화 동일10재료·2초:4개/8개 완성, 전체재고10 유지.
진행률 보존/중복구매/미회수대금 구매불가/pause·거리/30·60·120Hz/직원과통합 회귀 포함.
5효과18초경로는 구매없이 명중39/재고26/판매4/현금회수20으로 유지.
자동 테스트 수가 손맛/원본 동등성의 증거는 아님.

## 실제 창
최신run06을UI로import/F5. 판매대금45회수→40시설구매→잔액5,
MIXER0.25sACTIVE/믹서색변경을 확인. 이후 RAW10→4,READY20→26으로 가공 진행.
구체 키입력/상태는 PLAY_CHECK.md. UI시간은 정밀처리속도 계측 아님.
F키 경로만 실제구매. HUD버튼/모바일터치는 자동이벤트검사만 수행.
청음/인간손맛/원본 모션동등성/폰/Mac/GPU성능 미검증.
이번원본새계측 없음; 이전200ms랜드마크측정만 유지.

## 다음
1. G2 다음 과일 해금. 기존0/1종류가 처음부터열려 있어 진행규칙을정리하고
   해금전 절삭/재생성/납품과해금후보상을 일관되게 구현. 리플레이 영향 명시.
   기본형 비교물은 보존하고 G3진입전 G2포함 기본형도 별도체크포인트 권장.
2. G1 원본30fps 다구간추적/절삭주기/추적·진동분리/청음·인간평가 필요.
3. G1/G2 IN_PROGRESS,이후 G3사이버펑크→G4낮밤→G5진짜덱.
고정75초실패/재고초기화 강제없음. 다음과일은 아직해금시스템없음.

## GitHub / Web 이전
이후 개발 기준은 syjkim0125/harvest-deck main. export_presets.cfg의 Web 프리셋으로 Pages에 배포. 단일 스레드로 COOP/COEP 헤더 의존성을 제거. 기존 게임 동작은 유지.
