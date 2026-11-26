# SF 게임 리서치·실험 기록

## 2026-11-25 · Living Galaxy Alpha 0.2 · 브랜치 feature/living-galaxy-alpha / PR #3

- **기준점:** main 9e401fb972b6b6eb14a2a484f71db012f163f135 (기존 SF 전투 타격감 프로토타입). 기존 과일 게임은 별도 `legacy/harvest-deck-v0.8.11`.
- **사용자 요구:** 민간 선장·함선 선택, 독립적인 정부/상인/종교/반군/해적 세력과 영토전쟁, 항로 이벤트, 채집/함대전·잠입/행성 탐험/직업·동료, 제작/본거지 판매·방어 및 덱빌딩을 연결한 우주 RPG. 기존 탐험 재미 P0.
- **리서치 1:** [Mount & Blade II: Bannerlord 개발자 블로그 — NPC 영주 목표·캠페인 AI](https://www.taleworlds.com/en/Games/Bannerlord/Blog/4). 채택: 플레이어와 무관하게 서로 다른 국가가 이웃 전선에서 교전하며 이유가 있는 뉴스로 표현. 전체 군단 AI/정치 시뮬레이션은 MVP에서 보류.
- **리서치 2:** [RimWorld Console Edition 공식 기능 페이지 — AI 서사 사건과 정착지 방문·습격](https://rimworld.double11.com/features). 채택: 세계 사건은 서사와 선택을 제공해야 함. 무작위 전리품 수치만 나열하지 않고 교전/구조/검문/호송 조우로 확장할 예정. 복잡한 욕구 시스템은 보류.
- **기술 근거:** [Godot 4.6 RandomNumberGenerator](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html). 세력 전쟁과 항행 조우는 고정 시드로 같은 결과를 재현할 수 있게 구현.
- **가설:** '전투가 자동 웨이브로 이어지던 구조' 대신 민간 선장이 항성 지도에서 위험도·세력·항로를 보고 목적지를 선택하며, 전투에서 얻은 물자를 가져오고 세력 뉴스가 변화하면 여행 동기가 생길 수 있다.
- **구현:** `scripts/sf_galaxy_sim.gd`(5개 세력 + 자유 민간/5개 거점/인접 항로/시드 이벤트/세력 충돌/네임드 영입 차단/연료·전리품·명성), `scripts/sf_belt_scroll.gd`(선장/우주선 2지선다, 별 지도, 목적지 탭 후 기존 전투, 복귀), `tests/sf_galaxy.gd`, `.github/workflows/web.yml` 검증 단계, `docs/LIVING_GALAXY_VISION.md` 설계.
- **자동 검증:** PR #3 GitHub Actions Godot 4.6.3 CI: SF COMBAT 15/15, SF GALAXY 21/21, Godot Web export 완료 (첫 성공 run id 45556592764). 이후 추가 문서 커밋에 대한 CI 확인은 별도 필요.
- **자체 리뷰 — 개선:** 초기 플레이에서 행선지를 고를 수 있고 항행 시 연료/세력 뉴스/조우가 갱신되므로 단순 고정 아레나보다 탐험 목표가 분명해지는 첫 실험.
- **자체 리뷰 — 남은 문제:** 현재 별지도는 거점 이동·전투 연결만 있으며 실제 행성의 공간 분기 탐험/숨겨진 보상·외계 생물 구조, 선체 우주전·생존/직업·장비 제작/상점·덱/거점은 미구현. 진영 전투는 인접 관계 기반 단순 난수 시뮬레이션이며 역사적 유사성/장기 밸런스 미검증. '탐험 재미 개선 성공'이라고 단정하지 않음.
- **다음 수용 테스트:** 사용자에게 2개 서로 다른 항로 탭→섹터 전투→부품 회수→다른 항로 점프를 수행하게 하고, 자신이 어떤 위험/보상을 보고 선택했는지, 무엇을 발견했는지 설명할 수 있는지 확인. 휴대폰 실기기/아동/청음/전투 손맛은 미검증.
- **다음 1개 구현:** 행성 한 지역에 위험도가 다른 2갈래 **물리적인 탐험 분기**와 숨겨진 외계 생물 단서 1종을 연결. 별지도 버튼·텍스트만 추가하지 않음.

## 2026-11-26 · P0 integration catch-up
- #9 main 6d7ffe87, Actions main push 45723494190 build+deploy successful. #11 merge 83db196b, CI 45737457468 combat 21/21 and galaxy 39/39, export+build-info artifact. Hidden targets, terrain, cache, escort extraction, original explorer poses and defeat visual, contextual hints. ObjectDB warnings persisted after audio cleanup.
- Current follow-up: V-001 locked lunge/counter/one damage event, compact galaxy header and on-demand details, 360×640/393×852 native render + synthetic touch screenshot artifact, public SHA verification step, research ledger U007–009. Cached references: https://playabsolum.com/ and https://www.mintrocketgames.com/ (principles only, no asset copying). Review evidence issue #10 comment 7178910288. CI pending at branch creation; native capture does not certify real mobile or fun. User quality FAIL; remaining multi-room terrain, distinct enemy art and human audio/motion A/B.
