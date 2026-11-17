# Harvest Deck — Godot Feel Lab v0.6

Godot 4 + GDScript. GitHub 저장소에서 관리하는 프로젝트입니다.

## 실행

Godot 4.6.3 일반판에서 `project.godot`을 가져온 뒤 F6 대신 F5로 실행합니다.
Linux 데스크톱에서 키보드 이동·수확·납품·응대·현금 회수를 실제 확인했습니다.
Mac·터치 기기·청음·사람의 손맛 평가는 아직 확인하지 않았습니다.

- WASD / 방향키: 이동. 진행 방향으로 가까운 과일을 자동 절삭합니다.
- 터치 드래그: 이동 코드 포함. 실기기 검증 전입니다.
- 민트색 JUICE 원: 순차 납품 → 과일별 FIFO 가공(0.45초) → 완제품.
- 파란 STAND TO SERVE 원: 서 있는 동안 손님에게 1개씩 응대·판매(0.7초).
- 산호색 MIXER 원: 회수한 현금 $40로 F키 또는 HUD 버튼을 눌러 1회 강화(0.45→0.25초/개). 진행 중 작업의 진행률 유지.
- 보라색 HIRE 원: 회수한 현금 $30로 E키 또는 HUD 버튼을 눌러 계산원 고용. 이후 자동 응대.
- 금색 COLLECT 원: 판매대금 회수. 가방 초과 보상은 바닥에 남고 가까이 가면 줍습니다.
- 1: 화면 흔들림, 2: 전체 음향, 3: 대상 반동·번쩍임, 4: 25ms 대상 국소 정지.
- 5: 연속 엔진/부하음만 ON/OFF. - / =: 볼륨 조절(기본65%).
- M: 화면 흔들림 없는 reduced-motion. P / Esc: 일시정지·재개. R: 초기화.

## 지금 구현한 범위

이동, 두 과일의 반복 절삭, 다수 동시 명중, 실제 명중별 제한된 카메라 흔들림,
직접 합성한 타격음·엔진/명중 부하음 루프, 피격 반동·번쩍임, 입자, 재료 적층·흔들림, 적재 한도,
귀환 납품, 재료/가공/완제품 분리·판매대금 회수, 재생성, 효과별 비교 토글.

현재 그래픽은 코드로 그린 테스트용 도형입니다. 원본 에셋은 사용하지 않습니다.
손님은 최대5명의 실제 FIFO 줄로 도착하고 완제품1개를 구매합니다. 종류 지정 주문·수확 직원은 아직 없습니다. 계산원은 $30로 한 번 고용할 수 있습니다.
사이버펑크, 낮밤, 카드 시스템도 미구현입니다. 원본 재현 완료가 아닙니다.

## 검증

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --headless --path . --quit-after 120
```

99개 검증 통과. 결과와 한계는 `docs/HANDOFF.md`에 있습니다.
렌더링 가능한 데스크톱에서는 `tests/visual_smoke.gd`를 별도 실행할 수 있습니다.
자동 체크는 주관적인 타격감이나 원본과의 유사성을 증명하지 않습니다.

## 이어서 개발

`docs/HANDOFF.md` → `docs/ROADMAP.md` → `docs/REFERENCE_PARITY.md` 순서로 읽습니다.
GitHub main이 개발 기준입니다. 차후 작업은 최신 main을 수정합니다.

가공은 단일 믹서이며 강화로 처리 시간이 줄어듭니다. 계산원 고용 전에는 직접 응대합니다. 다음은 과일 해금입니다.
실제 화면에서 확인한 상태 변화는 `docs/PLAY_CHECK.md`에 있습니다.
비교용 최초 기본형은 `checkpoints/g1-v0.1.zip`으로 보존했습니다. 별도 폴더에 풀어 비교하세요.
동일 시드·경로 비교: `godot --headless --path . --script tests/feel_replay.gd`.

## 웹 플레이 / 배포

https://syjkim0125.github.io/harvest-deck/

GitHub Actions의 Godot Web 작업은 import → 99개 회귀 검사 → 리플레이 → 런타임 검사 → 웹 export 후 Pages에 배포합니다.
GitHub Settings → Pages → Source는 GitHub Actions입니다.
로컬 웹 빌드: `mkdir -p build/web && godot --headless --path . --export-release Web build/web/index.html`.
Godot 4.6.3 export templates가 필요합니다. `python3 -m http.server 8000 --directory build/web`로 실행합니다.
HTML 파일을 더블클릭하는 file:// 실행은 지원하지 않습니다.
웹은 단일 스레드 / Compatibility 렌더러입니다. 브라우저 오디오가 잠겨 있으면 게임 화면을 클릭하세요.
배포 실행별 Actions artifact에서도 웹 빌드를 받을 수 있습니다.
