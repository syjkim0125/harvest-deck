# VOID CARAVAN — Scene-Based Design Reference Router

> **디자인 자동화 3시간 주기의 최소 조회 인덱스** · 2026-11-25. 우선순위: [ART_DIRECTION.md](ART_DIRECTION.md) → **이 문서에서 해당 장면 1행** → 필요 시 [VISUAL_REFERENCE_BOARD.md](VISUAL_REFERENCE_BOARD.md) **해당 절만**. 개발 기능별 출처는 [REFERENCE_ROUTER.md](REFERENCE_ROUTER.md).
>
> **고정 DNA는 매번 재검색하지 않음**: '바닐라웨어 계열의 풍부한 회화적 2D 표현 원리 + Kindchenschema를 활용한 귀엽고 고유한 동료'가 사용자가 선택한 핵심 방향이다. 전체 자료/게임 18개/이 논문을 매회 읽지 말고, 해당 기능 제작에 직접 필요한 레퍼런스 **기본 1~2개(최대 3개)**만. 기존 캐릭터/에셋을 복제하지 않는다.

**디자인의 재미·행동 근거:** [GAME_DESIGN_THEORY.md](GAME_DESIGN_THEORY.md)의 K-02/G-02(행동 피드백), K-01/G-01(탐험 발견), K-05(주체성), G-04(과도한 주스/장식의 위험)는 실제 화면이 예쁘면서도 *무엇을 할지 보이는가*를 검증할 때 참고. [VIDEO_RESEARCH_INBOX.md](VIDEO_RESEARCH_INBOX.md)의 사용자 6개 영상은 **모두 자막·장면 분석 검증됨**. 특히 U-004의 실루엣 차별화/거절 기록/실제 게임 화면 비교를 아트 PR의 기준으로 사용하고 U-006의 도구는 선택적으로 검토. 단 원본 스프라이트/캐릭터 복제 금지. 매번 전체 이론 문서를 통독하지 않고 현재 장면의 한 가지 원리만 선택.

## 0 · 먼저 선택: 이번 작업의 아트 목적 하나

**기능이 먼저, 참고작은 나중**. 최신 main SHA, 한 장면의 실제 게임 플레이와 P0 사용자 피드백, 오픈된 design/* PR, 다음 작업 후보만 확인한다. 실제 에셋이 이미 있으면 중복 제작하지 말고 개선/통합 여부만 판단한다.

| 기능/장면 · 작업 신호 | 1순위 스타일 참조 | 2순위 형태/기능 참조 | 필요한 때만 3순위 | 추출할 *원리* | 제출할 실제 산출물과 합격 기준 |
| --- | --- | --- | --- | --- | --- |
| **행성 발견·자연/유적의 깊이** | [Odin Sphere](https://atlus-vanillaware.jp/) | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 회화적 식생의 전·중·후 레이어, 빛으로 암시하는 비밀 공간, 경로 가독성 | 한 화면 2~3레이어+발견 오브젝트. 360×640에서 갈림길/대상을 설명 없이 구별 |
| **P0 지상 전투 타격·적/히어로 분리** | [Odin Sphere](https://atlus-vanillaware.jp/) | [Absolum](https://playabsolum.com/) | [Dragon's Crown](https://atlus-vanillaware.jp/) | 큰 포즈 대비, 준비→접촉→경직→회복, 중요한 순간 배경 채도 억제 | 준비/명중/빗나감 3상태 원본 프레임 시트; 화면 흔들림만 늘리지 않음 |
| **외계 생물 신규 1종·구조/호감** | [Odin Sphere](https://atlus-vanillaware.jp/) | [Monster Sanctuary](https://monster-sanctuary.com/) | [Cassette Beasts](https://www.cassettebeasts.com/) | 회화적 2D 질감 + *Kindchenschema*: 둥근 이마·큰 눈·볼·작은 코/입, 고유 움직임 | 서로 다른 귀여움 강도 A/B/C 실루엣과 idle/발견 반응. 축소 시 적/동료 오인 없음 |
| **직업별 승무원/선장 초상·장비** | [Unicorn Overlord](https://unicorn-overlord.com/en/) | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [Langrisser](https://www.nisamerica.com/games/langrisser) | 의상/도구로 직업이 읽히고 얼굴/포즈로 개성 표현, 서로 다른 귀여움 강도 | 파일럿/기술자 구별 가능한 실루엣 2안+작업 포즈 1개 |
| **항성 지도·정부/종교/반란/해적 세력** | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [EVE Online](https://www.eveonline.com/) | [Bannerlord](https://www.taleworlds.com/en/games/bannerlord/) | 다층 우주 공간의 경이감, 각 진영 실루엣/광원, 위험·경로 읽기 | 5개 항성 탐색 UI 시안 또는 한 세력 함선 3/4방향 실루엣 |
| **우주 항해·함선 간 전투/포격** | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [Black Flag](https://www.ubisoft.com/en-us/game/assassins-creed/IV-black-flag) | [EVE Online](https://www.eveonline.com/) | 진입 방향/속도/위험의 시각화·거리감, 선체의 고유한 광원 | 원본 측면/탑다운 함선 이미지 + 경고/피격 2프레임 비교 |
| **우주선 내부의 따뜻한 일상/생존** | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [RimWorld](https://ludeon.com/blog/faq/) | [Cult of the Lamb](https://influencers.devolverdigital.com/cult-of-the-lamb) | 간접광, 생활 소품, 승무원 간 동선·감정표현, 작은 방의 밀도 | 침실/정비실 1모듈 또는 작업자 1명 idle/작업시트. 배경과 사물 구분 |
| **Lab 장비 제작·업그레이드** | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [Overcooked! 2](https://www.team17.com/games/overcooked-2) | [Moonlighter](https://digitalsungames.com/games/moonlighter/) | 생산 전/중/후 상태가 사물·빛·행동으로 보이게 | 원본 Lab 작업대 상태 3단계. 배치/픽업 가독성 |
| **방문 NPC/상점·제작품 진열** | [Odin Sphere](https://atlus-vanillaware.jp/) | [Moonlighter](https://digitalsungames.com/games/moonlighter/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 장식적인 공간에서도 진열/고객/가격/판매 가능 물체 구분 | 작은 상점 구역과 고객 동작 1종, 구매 상태 2개 |
| **행성 본거지·터렛·방어/거점 성장** | [Unicorn Overlord](https://unicorn-overlord.com/en/) | [Dome Keeper](https://rawfury.com/games/dome-keeper/) | [Fallout 4](https://fallout.bethesda.net/en/games/fallout-4) | 원근/높낮이/시설 밀도, 업그레이드 변화와 위험 전조 | 1단계/2단계 기지 비교 + 터렛 피격 가독성 |
| **카드 UI·직업 트리·덱빌딩** | [Unicorn Overlord](https://unicorn-overlord.com/en/) | [Monster Sanctuary](https://monster-sanctuary.com/) | [Cut the Rope](https://www.paladinstudios.com/cut-the-rope/) | 캐릭터/직업 의미가 드러나는 정보 계층, 선택 차이를 미리 예고 | 읽을 글 1줄 미만으로 이해되는 선택 UI + 고대비 예시 |
| **일반 모바일 터치·첫 화면** | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [Cut the Rope](https://www.paladinstudios.com/cut-the-rope/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 화면 포컬 포인트, 터치 대상의 손가락 영역, 장면 연출의 정보 계층 | 세로 360×640/393×852 가독성 비교. 설명문 증가 금지 |
| **네임드 인물/진영 문화 아트** | [Unicorn Overlord](https://unicorn-overlord.com/en/) | [13 Sentinels](https://atlus.com/13sentinels/lang/uk/) | [Bannerlord](https://www.taleworlds.com/en/games/bannerlord/) | 생애/세력/직급이 상징되는 고유 장비·자세·조명 | 세력장 1명 원본 실루엣과 복식 규칙. 게임 내 영입 가능 표시 금지 |

**선택 로직:** 한 작업에 기본 레퍼런스 2개면 충분. 3번째는 실제 결함을 비교할 이유가 있을 때만. 예: '생물 표정 귀여움'은 Monster Sanctuary + Odin Sphere + Kindchenschema 논문의 특성 요약(세 번째 게임 불필요), '항성 지도 정보 밀도'는 13 Sentinels + EVE. **작업과 무관한 모든 항목은 읽지 않는다.**

## 1 · 지식 캐시(매회 불필요한 재검색 금지)

- **Vanillaware art principles:** [PlayStation/Atlus 프로듀서 원문](https://blog.playstation.com/?p=334534)에서 회화적 배경, 광원을 이용한 분위기, 연극 무대 같은 카메라/레이어 구성을 참조. [ATLUS × Vanillaware](https://atlus-vanillaware.jp/)에서 대표작 확인. 이 둘의 **원리 요약은 ART_DIRECTION.md에 캐시**되어 있으므로 새로운 제작 의사결정이 있을 때만 원문 열기.
- **Kindchenschema:** [Glocker et al. (2009)](https://doi.org/10.1111/j.1439-0310.2008.01603.x) / [2024년 개념 검토](https://doi.org/10.1098/rspb.2024.0570). 큰 머리/큰 눈/둥근 뺨·작은 코와 입은 **귀여움 설계 단서**일 뿐, 최적 애착·최고 매출·최적 얼굴 비율을 보장하는 게임 디자인 공식이 아니다. 이미 ART_DIRECTION.md에 정리되어 있다.
- **그 외 18개 기계적 참고작:** [VISUAL_REFERENCE_BOARD.md](VISUAL_REFERENCE_BOARD.md)의 해당 §만 열고, 원본 스크린샷을 게임 제작 소스로 복제하지 않는다.

## 2 · 작업 시작 ~ PR 제출까지 최소 루프

1. 최신 GitHub main+관련 UI 코드/실제 화면(가능할 때)과 다른 개발 세션의 PR을 확인. **사용자가 직접 보고한 P0 타격감·탐험 부재**를 우선.
2. **이번 3시간 동안 실제 제작할 화면 또는 에셋 한 가지**만 지정. 이 표의 **해당 1행** 선택.
3. 레퍼런스 1~2개에서 시각적 원리를 추출하고 **원본 독자 미술**로 드로잉/레이어/스프라이트 제작. 먼저 캐릭터·적·상호작용 대상 실루엣을 검증한 뒤 장식/광원 추가.
4. 360×640과 393×852 게임 뷰포트 기준 실제 표시 크기 확인(실행 환경에 없으면 수치 계산/목업 상태를 구분). **아트 감성보다 모바일 조작과 발견할 대상 인식이 먼저**.
5. design/<feature> 브랜치 → assets/design-proposals/<feature>/ 원본+preview 파일 및 docs/design/<feature>.md 기록 → PR. **게임 스크립트/scene/main 수정 금지.**
6. 개발 세션에는 '관련 기능과 통합 가능한 PR, 에셋 위치/크기/피벗/애니메이션 프레임, 예상 조작·가독성 개선'만 넘긴다. 통합되지 않은 PR을 완성 게임 기능으로 보고하지 않는다.
7. 각 시안은 PROPOSED / REVIEWED / INTEGRATED / PLAYTESTED를 구분. 테스트와 주관적 플레이 감각은 다르며 7세 사용자 검증 전까지 미검증.

## 3 · 현재 다음 작업 추천

**현재 플레이어의 직접 P0는 타격감 부족과 행성 탐험의 발견 부재**. 개발 코드가 실제 진행 중인 기능부터 선택해 **(A) 외계 생물이 숨어 있는 행성 분기 배경 1장** 또는 **(B) 타격 전/명중/피격 3상태 캐릭터 프레임**을 제안하되 중복 PR이 이미 있다면 새로운 문제를 선택. 스타맵/카드 등을 장식적으로 전면 리디자인하는 것은 후순위.

## 4 · 지양할 제작 패턴

- '바닐라웨어 스타일'을 **자사 IP의 캐릭터나 특정 화면을 재현하라**는 뜻으로 해석 금지.
- 기존 SF 0.2의 임시 1px 픽셀 텍스처를 새로운 회화적 2D 작품의 절대 기준으로 강제 금지. 기획 변경과 실제 렌더링 방식 전환은 사용자에게 차이를 보여준 뒤 게임 엔진 통합.
- 레퍼런스 이미지를 다운로드해 게임의 배경·캐릭터 스프라이트나 마케팅 에셋으로 재활용 금지.
- 겉보기 예쁜 정지 콘셉트 아트 한 장만 제출하고 실제 화면에서의 크기/레이어/가독성을 기록하지 않는 것 금지.
