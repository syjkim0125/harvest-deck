# VOID CARAVAN — Feature-to-Reference Router

> **개발 자동화용 1분 이내 진입점** · 2026-11-25 · [기획 단일 출처](LIVING_GALAXY_VISION.md) · [전체 이미지/출처 18개](VISUAL_REFERENCE_BOARD.md) · [디자인 협업 규칙](DESIGN_HANDOFF.md)
>
> **원칙: 매시간 18개 이미지를 전부 다시 읽지 않는다.** 이번에 구현할 기능 **1개를 먼저 결정하고 해당 행의 1~2개 레퍼런스만** 살펴본다. 이미지 목록은 UI/아트 결정을 내릴 때만 열고, 기계적인 버그 픽스에는 열지 않는다.

**시각 아트 결정 시 별도 기준**: 사용자가 승인한 [아트 디렉션](ART_DIRECTION.md)은 **회화적인 Vanillaware 계열 2D 무대 표현 원리 + Kindchenschema 기반 귀여운 캐릭터/외계 생물**이다. 픽셀아트만 강제하지 않으며, 원본 에셋 복제는 금지. **개발 기능 레퍼런스**는 아래 표를 사용하되, UI/스프라이트/조명/캐릭터 결정이 필요한 그때만 [디자인 레퍼런스 라우터](DESIGN_REFERENCE_ROUTER.md)의 해당 장면 **한 행**을 추가 참고한다. 개발 세션은 이 때문에 매번 18게임 이미지를 탐색하지 않는다.

**행동/재미 이론 캐시:** [GAME_DESIGN_THEORY.md](GAME_DESIGN_THEORY.md)에는 라프 코스터의 배우는 재미·피드백·변주·숙련·주체적 선택과 GDC 개발자 발표/연구의 **실험/수용 테스트**가 정리되어 있다. [VIDEO_RESEARCH_INBOX.md](VIDEO_RESEARCH_INBOX.md)의 사용자 영상 6개는 **원본 자막/화면 검증 전까지 내용 미확인**. 개발 세션은 독립 리뷰가 고른 **관련 원칙 ID 1개**와 단일 게임 레퍼런스만 읽고, 이미 문서화된 근거를 불필요하게 재검색하지 않는다.

## 매 실행의 최소 조회 순서

1. 최신 `main` 커밋·진행 중 PR·직전 HANDOFF의 **새 SF 시스템 기록**·열린 P0/P1·사용자 최신 피드백을 확인한다. 중복 구현이나 구 과일 게임 확대 방지.
2. 다음 한 기능이 정해지면 아래 표의 **레퍼런스 1개, 필요하면 비교용 1개**를 선택한다. 전체 기획서는 **비전/시점/기능 우선순위가 바뀔 때만** 관련 절을 펼친다.
3. 게임 메커닉 검증에는 관련 게임의 **공식 설명·플레이 영상/1차 개발자 자료** 1~2개를 확인한다. **비주얼 배치/애니메이션**의 경우에만 [비주얼 보드](VISUAL_REFERENCE_BOARD.md)의 대응 절을 읽고 해당 이미지 원본을 본다. 유효한 새 근거가 없으면 지난 결론을 재사용한다.
4. `docs/RESEARCH_LOG.md`에 단 한 행으로 기록: `기능 | 선택 레퍼런스/링크 | 관찰된 원리 | 우리 방식/복제하지 않을 것 | 수용 테스트 | 구현 SHA`. 이미 판단된 동일 원리를 매번 재조사하지 않는다.
5. 구현→Godot CI/웹 export→Pages 확인. **테스트 통과는 손맛/재미/사용자 사용성 완료와 다르다.** 기존 직접 사용자 P0(타격감·탐험 발견) 재검증 전 해결 선언 금지.

## 기능별 참조 라우터 (최대 2개만 선택)

| 실제 작업 / 신호 | 1순위 | 비교용 2순위 | 확인할 원리 / 우리 게임 실험 | 이미지 보드 해당 절 |
| --- | --- | --- | --- | --- |
| **항성 지도·세력 전쟁·NPC 행동** | [Bannerlord](https://www.taleworlds.com/en/games/bannerlord/) | [EVE Online](https://www.eveonline.com/) | 독립 세력 목표·충돌의 원인이 항로·세력 소식에 실제 영향을 미치는가 | §01 |
| **우주 항해·항로 선택·조우** | [Black Flag](https://www.ubisoft.com/ko-kr/game/assassins-creed/iv-black-flag) | [Uncharted Waters Origin](https://store.steampowered.com/app/1574360/Uncharted_Waters_Origin/) | 움직이는 과정에 발견과 위험·보상이 있는가. 지도는 단순 이동 메뉴가 아닌가 | §02 |
| **우주선 간 포격·회피·선회** | [Black Flag](https://www.ubisoft.com/en-us/game/assassins-creed/IV-black-flag) | [EVE Online](https://www.eveonline.com/) | 방향·거리·예고·위치 판단이 승패를 가르는가 | §02 / §01 |
| **P0 행성 타격감·회피/반격** | [Absolum](https://playabsolum.com/) | [Shadow over Mystara](https://store.steampowered.com/app/229480/Dungeons__Dragons_Chronicles_of_Mystara/) | 실제 명중시 경직/밀림/시각적 타격 확인, 헛공격과 구별, 손가락 조작의 지연 없는 회복 | §03 |
| **P0 행성 발견/갈림길** | [Absolum](https://playabsolum.com/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 탐험 전보다 다른 장소/선택/뜻밖의 발견/귀환 이유가 생기는가 | §03 / §06 |
| **우주생물·동료 모집/역할/기술트리** | [Monster Sanctuary](https://monster-sanctuary.com/) | [Cassette Beasts](https://www.cassettebeasts.com/) | 캐릭터의 독특한 행동과 개성, 동료 발견과 배치 간 선택 | §04 |
| **선장 질문·직업/하이브리드 분화** | [Langrisser I & II](https://www.nisamerica.com/games/langrisser) | [Monster Sanctuary](https://monster-sanctuary.com/) | 능력치뿐 아니라 탐험/협상에서 새로운 행동 선택지가 생기는가 | §04 |
| **승무원 생존·일감 배치·함선 내부** | [RimWorld](https://ludeon.com/blog/faq/) | [Cult of the Lamb](https://influencers.devolverdigital.com/cult-of-the-lamb) | 승무원이 실제 공간에서 일하고 쉬는 행동이 읽히는가 | §05 / §04 |
| **제작/상점·전리품의 경제적 의미** | [Moonlighter](https://digitalsungames.com/games/moonlighter/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 부품→설비→제품→NPC 판매→다음 원정이 연결되는가 | §06 |
| **설비/판매 공간의 동선·병목** | [Overcooked! 2](https://www.team17.com/games/overcooked-2) | [RimWorld](https://ludeon.com/blog/faq/) | 메뉴가 아닌 재료와 작업자 이동으로 상태가 보이는가 | §06 / §05 |
| **전초기지 습격·포탑·위험-보상** | [Dome Keeper](https://rawfury.com/games/dome-keeper/) | [Fallout 4](https://fallout.bethesda.net/en/games/fallout-4) | 떠날 때와 돌아올 때의 리스크, 물리적 건물·방어선 변화 | §07 |
| **모바일 첫 90초/제스처·정보 가독성** | [Cut the Rope](https://www.paladinstudios.com/cut-the-rope/) | [DAVE THE DIVER](https://www.mintrocketgames.com/ko/game/game.php) | 설명/버튼 추가 대신 사물의 위치·애니메이션·반응으로 입력 발견 | §08 |
| **전투 카드·진행 런·덱 선택** | [Monster Sanctuary](https://monster-sanctuary.com/) | [Vampire Survivors](https://poncle.games/vampire-survivors) **비교용만** | A/B 선택 이후 행동/위험/보상 차이; 자동공격 장르 회귀 금지 | §04 / §09 |
| **픽셀 아트/화면 통일·애니메이션 일관성** | [Absolum](https://playabsolum.com/) | [Cult of the Lamb](https://influencers.devolverdigital.com/cult-of-the-lamb) | 자산을 복제하지 말고 정보 계층·실루엣·동작 읽기 원리만 비교 | §03 / §04 |

## 선택 금지/중지 조건

- *진행과 무관한 레퍼런스*를 조사하지 않는다. 예: 세력 AI를 개발하면서 Moonlighter 상점 이미지를 읽을 필요 없음.
- 기존 **과일·체인소 수확**, 레퍼런스 게임의 **캐릭터·스크린샷·원본 픽셀·음향**을 VOID CARAVAN 게임 에셋으로 재사용하지 않는다.
- 레퍼런스 보드의 외부 이미지 일부는 깨지거나 재호스팅 권한이 없을 수 있다. 원본 스크린샷은 **기획 비교 전용**; 완성 게임 에셋은 독자 제작.
- **디자인 전용 변경**은 [DESIGN_HANDOFF.md](DESIGN_HANDOFF.md)의 통합 규칙을 따른다. 게임플레이 코어를 바꾸는 작업은 개발 세션 단독 소유.
- 해당 참고작에서 실험할 원리가 없다면 리서치를 더 늘리지 말고 **현재 코드·실사용자 관찰에 근거한 최소 변경**을 먼저 진행한다.

## 현재 개발 우선순위 / 다음 번 입력

지금까지 구현: 선장/시작 함선 선택, 5개 항성 지도와 초기 세력 사건, 기존 행성 전투, 전리품 귀환. **현재 P0**: 사용자가 타격감 부족 및 탐험 재미 부재를 직접 보고. 따라서 다음 기능의 기본 참조는 **Absolum(전투 경직·회피/반격 또는 분기) + DAVE THE DIVER(발견·회수·귀환의 이유)**이며, 구체적으로 선택된 기능에 하나 또는 둘만 읽는다. 상황 변경 시 이 단락만 교체한다.
