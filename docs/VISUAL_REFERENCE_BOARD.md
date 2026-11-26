> **기획 재정립 기준:** 아래는 비교용 원본 이미지/참고 원리 아카이브이며 화면 또는 기능 승인 아님. 최종 기준은 [GDD](LIVING_GALAXY_VISION.md). 이전 구현·제작 우선순위는 무효. 현재 핵심 참고작 Bannerlord / 대항해시대 / Black Flag / RimWorld / Absolum / Vanillaware / Zelda BOTW·TOTK. [젤다 개발자 자료](https://www.nintendo.com/us/whatsnew/ask-the-developer-vol-9-the-legend-of-zelda-tears-of-the-kingdom-part-4/).

# VOID CARAVAN — Visual & System Reference Board

> **Living Galaxy RPG / 2026-11-25 / 실무용 레퍼런스 아틀라스**  
> [제품 비전](LIVING_GALAXY_VISION.md) · [현재 플레이 프로토타입](https://syjkim0125.github.io/harvest-deck/) · [직접 플레이 피드백](SF_PLAYTEST_FEEDBACK.md)  
> 기존 참고 게임의 **외부 이미지 참조 23건(중복 포함)**과 공식 출처, 채택/배제/적용 판단을 연결했다. 이미지 URL은 외부 원격 로드이므로 원본 서버 정책에 따라 로드되지 않을 수 있다. 공식 이미지 또는 게임 스크린샷으로서 출처를 구분해 표기했다.

> **역할 구분**: 이 18개 게임은 주로 **게임 시스템/화면 구조/실무용 비교 이미지** 레퍼런스다. 최종 비주얼 방향은 별도로 사용자 승인된 **[ART_DIRECTION.md: 회화적 2D + Kindchenschema](ART_DIRECTION.md)**가 우선한다. 디자인 제작 시 전체 보드 재열람 대신 **[DESIGN_REFERENCE_ROUTER.md](DESIGN_REFERENCE_ROUTER.md)**의 해당 장면 1행(최대 3개 참고작)을 따른다. 바닐라웨어의 Odin Sphere / 13 Sentinels / Unicorn Overlord / Dragon's Crown은 **아트 원리 레퍼런스**이며 별도의 권리 있는 게임 이미지/캐릭터를 게임 자산으로 복제하지 않는다.

## 00 · 이 게임은 무엇인가?

> **살아 움직이는 여러 세력의 우주에서 중립 선장으로 시작해 항해·탐험·전투·동료 수집·제작·상점·본거지 확장으로 자신만의 세력을 키워가는 SF 회화적 2D 샌드박스 RPG.**

**1회 루프:** 민간 선장/함선 선택 → 세력 변화가 보이는 우주 항해 → 조우·행성 탐험 → 선택과 전투 → 전리품·동료 회수 → 함내 제작·판매 → 우주선/거점 확장 → 다음 항로.  
**장기 루프:** 인물의 직업·관계·두 종류의 덱 → 외교·교역·생존·영토 변화 → 평판과 세력 성장.

### 첫 화면에 배치할 핵심 레퍼런스 6

| <img src="https://cdn.akamai.steamstatic.com/steam/apps/261550/header.jpg" width="340" alt="Mount & Blade II: Bannerlord — 이미지 출처: Steam / TaleWorlds 공식 프로모션 이미지" loading="lazy" /> | <img src="https://content.eveonline.com/www/newssystem/media/67273/1/Kronos.jpg" width="340" alt="EVE Online — 이미지 출처: EVE Online 공식 뉴스 이미지 (CCP)" loading="lazy" /> |
| --- | --- |
| **Mount & Blade II: Bannerlord** · [공식 자료](https://www.taleworlds.com/en/Games/Bannerlord/Media)  <br>참고할 것: 플레이어와 무관한 세력의 외교·전쟁·영토 변화, 지역 인물과 사건  <br>피할 것: 중세 분위기와 군대 규모, 전투 애니메이션 복제  <br>**VOID CARAVAN 적용:** 플레이 중 실시간 세력 AI를 시뮬레이션하고 결과를 항로·물가·의뢰에 반영  <br><sub>이미지: Steam / TaleWorlds 공식 프로모션 이미지. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/261550/header.jpg)</sub> | **EVE Online** · [공식 자료](https://www.eveonline.com/)  <br>참고할 것: 우주선 중심의 거대 세계, 정치·경제·전쟁·탐사  <br>피할 것: MMO의 UI 밀도와 플레이 시간 압박  <br>**VOID CARAVAN 적용:** 지역 세력전의 결과가 항성 위험도와 자원 수요를 바꾸도록  <br><sub>이미지: EVE Online 공식 뉴스 이미지 (CCP). 이미지가 표시되지 않으면 [원본 열기](https://content.eveonline.com/www/newssystem/media/67273/1/Kronos.jpg)</sub> |

| <img src="https://mperials.com/images/screenshots/assassins-creed-iv-black-flag-illustrious-pirates-pack/original/sc7zd1.jpg" width="340" alt="Assassin’s Creed IV: Black Flag — 이미지 출처: MPERIALS에 게시된 Ubisoft 게임 스크린샷" loading="lazy" /> | <img src="https://www.nintendo.com/eu/media/images/06_screenshots/games_5/nintendo_switch_download_software_2/nswitchds_davethediver/NSwitchDS_DaveTheDiver_02_DEde.jpg" width="340" alt="DAVE THE DIVER — 이미지 출처: Nintendo 공식 게임 페이지 / MINTROCKET 제공" loading="lazy" /> |
| --- | --- |
| **Assassin’s Creed IV: Black Flag** · [공식 자료](https://www.ubisoft.com/ko-kr/game/assassins-creed/iv-black-flag)  <br>참고할 것: 항해의 경로 선택·가시적인 조우·배가 곧 생활 거점인 감각  <br>피할 것: 카리브해 역사 배경과 UI·함선 디자인 복제  <br>**VOID CARAVAN 적용:** 점과 선을 탭하는 현재 스타맵에서 함선 이동/조우가 보이는 항해 장면으로 진화  <br><sub>이미지: MPERIALS에 게시된 Ubisoft 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://mperials.com/images/screenshots/assassins-creed-iv-black-flag-illustrious-pirates-pack/original/sc7zd1.jpg)</sub> | **DAVE THE DIVER** · [공식 자료](https://www.mintrocketgames.com/ko/game/game.php)  <br>참고할 것: 탐험·획득과 귀환 후 운영의 리듬, 작은 발견의 누적  <br>피할 것: 초밥·해양 테마 및 미니게임 과밀화  <br>**VOID CARAVAN 적용:** 전리품의 종류가 우주선 제작·방문객 수요·다음 항로를 바꾸도록  <br><sub>이미지: Nintendo 공식 게임 페이지 / MINTROCKET 제공. 이미지가 표시되지 않으면 [원본 열기](https://www.nintendo.com/eu/media/images/06_screenshots/games_5/nintendo_switch_download_software_2/nswitchds_davethediver/NSwitchDS_DaveTheDiver_02_DEde.jpg)</sub> |

| <img src="https://cdn.akamai.steamstatic.com/steam/apps/1904480/header.jpg" width="340" alt="Absolum — 이미지 출처: Steam / Dotemu 공식 프로모션 이미지; 게임플레이는 공식 Press Kit 참조" loading="lazy" /> | <img src="https://rimworldgame.com/biotech/screenshots/impids.jpg" width="340" alt="RimWorld — 이미지 출처: RimWorld 공식 스크린샷 (Ludeon)" loading="lazy" /> |
| --- | --- |
| **Absolum** · [공식 자료](https://www.dotemu.com/PressKit/project/Games/Absolum)  <br>참고할 것: 수동 회피·반격 타이밍, 타격감·애니메이션, 경로 분기  <br>피할 것: 특정 캐릭터·배경·애니메이션/전투 기술의 복제  <br>**VOID CARAVAN 적용:** 타격감 연구 후보: 실제 피격 경직·충돌 방향·입력 피드백  <br><sub>이미지: Steam / Dotemu 공식 프로모션 이미지; 게임플레이는 공식 Press Kit 참조. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/1904480/header.jpg)</sub> | **RimWorld** · [공식 자료](https://rimworldgame.com/biotech/)  <br>참고할 것: 작업 가능한 내부 공간·승무원 행동·사건의 인과관계  <br>피할 것: 초반부터 과도한 생존 게이지와 복잡한 명령창  <br>**VOID CARAVAN 적용:** 승무원 1명이 실제 이동해 정비·제작·휴식을 하는 작은 함내 모듈부터  <br><sub>이미지: RimWorld 공식 스크린샷 (Ludeon). 이미지가 표시되지 않으면 [원본 열기](https://rimworldgame.com/biotech/screenshots/impids.jpg)</sub> |

**이 6개의 조합이 답안이라는 뜻은 아니다.** 장면의 종류와 정보 밀도/전투 읽기/운영 감성을 비교하기 위한 도구이다. 시각적으로는 특정 게임을 섞어 붙이지 않고 **VOID CARAVAN 고유의 선명한 2D 픽셀 아트 + 세력별 실루엣/색 + 차별화된 UI**로 하나의 스타일 가이드를 만든다.

## 시스템별 이미지 레퍼런스 전체

## 01 · 살아 있는 세력과 세계

**검토 질문:** 플레이어가 움직이지 않아도 사건이 발생하고, 나의 항로/의뢰가 바뀌는가?

| <img src="https://cdn.akamai.steamstatic.com/steam/apps/261550/header.jpg" width="300" alt="Mount & Blade II: Bannerlord — 이미지 출처: Steam / TaleWorlds 공식 프로모션 이미지" loading="lazy" /> | <img src="https://content.eveonline.com/www/newssystem/media/67273/1/Kronos.jpg" width="300" alt="EVE Online — 이미지 출처: EVE Online 공식 뉴스 이미지 (CCP)" loading="lazy" /> |
| :--- | :--- |
| **Mount & Blade II: Bannerlord** · [공식 자료](https://www.taleworlds.com/en/Games/Bannerlord/Media)  <br>참고할 것: 플레이어와 무관한 세력의 외교·전쟁·영토 변화, 지역 인물과 사건  <br>피할 것: 중세 분위기와 군대 규모, 전투 애니메이션 복제  <br>**VOID CARAVAN 적용:** 플레이 중 실시간 세력 AI를 시뮬레이션하고 결과를 항로·물가·의뢰에 반영  <br><sub>이미지: Steam / TaleWorlds 공식 프로모션 이미지. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/261550/header.jpg)</sub> | **EVE Online** · [공식 자료](https://www.eveonline.com/)  <br>참고할 것: 우주선 중심의 거대 세계, 정치·경제·전쟁·탐사  <br>피할 것: MMO의 UI 밀도와 플레이 시간 압박  <br>**VOID CARAVAN 적용:** 지역 세력전의 결과가 항성 위험도와 자원 수요를 바꾸도록  <br><sub>이미지: EVE Online 공식 뉴스 이미지 (CCP). 이미지가 표시되지 않으면 [원본 열기](https://content.eveonline.com/www/newssystem/media/67273/1/Kronos.jpg)</sub> |


## 02 · 항해·발견·조우

| <img src="https://mperials.com/images/screenshots/assassins-creed-iv-black-flag-illustrious-pirates-pack/original/sc7zd1.jpg" width="300" alt="Assassin’s Creed IV: Black Flag — 이미지 출처: MPERIALS에 게시된 Ubisoft 게임 스크린샷" loading="lazy" /> | <img src="https://jolstatic.fr/www/captures/6693/1/161971.jpg" width="300" alt="Uncharted Waters Origin — 이미지 출처: JeuxOnLine 게임 스크린샷 (LINE Games 제공 타이틀)" loading="lazy" /> |
| :--- | :--- |
| **Assassin’s Creed IV: Black Flag** · [공식 자료](https://www.ubisoft.com/ko-kr/game/assassins-creed/iv-black-flag)  <br>참고할 것: 항해의 경로 선택·가시적인 조우·배가 곧 생활 거점인 감각  <br>피할 것: 카리브해 역사 배경과 UI·함선 디자인 복제  <br>**VOID CARAVAN 적용:** 점과 선을 탭하는 현재 스타맵에서 함선 이동/조우가 보이는 항해 장면으로 진화  <br><sub>이미지: MPERIALS에 게시된 Ubisoft 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://mperials.com/images/screenshots/assassins-creed-iv-black-flag-illustrious-pirates-pack/original/sc7zd1.jpg)</sub> | **Uncharted Waters Origin** · [공식 자료](https://www.line.games/company/news/878)  <br>참고할 것: 항해·발견·교역의 자유로운 연결  <br>피할 것: 교역 UI 과밀화  <br>**VOID CARAVAN 적용:** 위험 루트와 안전 루트가 서로 다른 발견·보상을 제공  <br><sub>이미지: JeuxOnLine 게임 스크린샷 (LINE Games 제공 타이틀). 이미지가 표시되지 않으면 [원본 열기](https://jolstatic.fr/www/captures/6693/1/161971.jpg)</sub> |


## 03 · 행성 탐험·전투의 손맛

**검토 질문:** 경직·넉백·피격 예고·회피 반격이 실제로 읽히는가? 아직 실제 플레이 재미는 미검증.

| <img src="https://cdn.akamai.steamstatic.com/steam/apps/1904480/header.jpg" width="300" alt="Absolum — 이미지 출처: Steam / Dotemu 공식 프로모션 이미지; 게임플레이는 공식 Press Kit 참조" loading="lazy" /> | <img src="https://bitvint.com/cdn/shop/files/Dungeons_Dragons_Shadow_over_Mystara_1996_Arcade_Gameplay_Capcom_Fighter.png?v=1746455928&amp;width=1000" width="300" alt="Dungeons & Dragons: Shadow over Mystara — 이미지 출처: Bitvint에 게시된 Capcom 원작 게임 화면" loading="lazy" /> |
| :--- | :--- |
| **Absolum** · [공식 자료](https://www.dotemu.com/PressKit/project/Games/Absolum)  <br>참고할 것: 수동 회피·반격 타이밍, 타격감·애니메이션, 경로 분기  <br>피할 것: 특정 캐릭터·배경·애니메이션/전투 기술의 복제  <br>**VOID CARAVAN 적용:** 타격감 연구 후보: 실제 피격 경직·충돌 방향·입력 피드백  <br><sub>이미지: Steam / Dotemu 공식 프로모션 이미지; 게임플레이는 공식 Press Kit 참조. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/1904480/header.jpg)</sub> | **Dungeons & Dragons: Shadow over Mystara** · [공식 자료](https://store.steampowered.com/app/229480/Dungeons__Dragons_Chronicles_of_Mystara/)  <br>참고할 것: 명확한 피격 판정, 직업별 기술, 전투 진행 분기  <br>피할 것: 픽셀·몬스터·UI 원본 복제  <br>**VOID CARAVAN 적용:** 지상전 벨트스크롤 안과 쿼터뷰 안을 비교  <br><sub>이미지: Bitvint에 게시된 Capcom 원작 게임 화면. 이미지가 표시되지 않으면 [원본 열기](https://bitvint.com/cdn/shop/files/Dungeons_Dragons_Shadow_over_Mystara_1996_Arcade_Gameplay_Capcom_Fighter.png?v=1746455928&width=1000)</sub> |


## 04 · 동료·생물·직업 수집

| <img src="https://cdn.akamai.steamstatic.com/steam/apps/814370/header.jpg" width="300" alt="Monster Sanctuary — 이미지 출처: Steam / Moi Rai Games 공식 프로모션 이미지" loading="lazy" /> | <img src="https://cdn.akamai.steamstatic.com/steam/apps/1321440/header.jpg" width="300" alt="Cassette Beasts — 이미지 출처: Steam / Bytten Studio 공식 프로모션 이미지" loading="lazy" /> |
| :--- | :--- |
| **Monster Sanctuary** · [공식 자료](https://monster-sanctuary.com/)  <br>참고할 것: 생물 수집·스킬 트리·탐험 능력 개방  <br>피할 것: 턴제 전투 방식 강제  <br>**VOID CARAVAN 적용:** 외계 생물마다 전투/탐험/작업 역할 1개 이상  <br><sub>이미지: Steam / Moi Rai Games 공식 프로모션 이미지. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/814370/header.jpg)</sub> | **Cassette Beasts** · [공식 자료](https://www.cassettebeasts.com/)  <br>참고할 것: 생물 고유 외형, 관계·조합·수집 동기  <br>피할 것: 카세트·융합 그래픽/능력 복제  <br>**VOID CARAVAN 적용:** 동료를 숫자가 아닌 장면 속 함께 움직이는 존재로 표현  <br><sub>이미지: Steam / Bytten Studio 공식 프로모션 이미지. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/1321440/header.jpg)</sub> |

| <img src="https://images.everyeye.it/img-notizie/che-tipo-gioco-cult-of-the-lamb-come-funziona-v6-602875-1200x1200.webp" width="300" alt="Cult of the Lamb — 이미지 출처: Everyeye에 게시된 Massive Monster 게임 스크린샷" loading="lazy" /> | <img src="https://cdn.akamai.steamstatic.com/steam/apps/1060220/ss_5a60f8b41afb5e1f74406d0560c285648968b79f.1920x1080.jpg?t=1668469958" width="300" alt="Langrisser I & II — 이미지 출처: Steam / NIS America 게임 스크린샷" loading="lazy" /> |
| :--- | :--- |
| **Cult of the Lamb** · [공식 자료](https://influencers.devolverdigital.com/cult-of-the-lamb)  <br>참고할 것: 작은 동료의 일상 행동·애착과 시설 확장  <br>피할 것: 종교 세계관과 캐릭터 디자인 복제  <br>**VOID CARAVAN 적용:** 동료 모집 후 선내 활동/배치가 보이도록  <br><sub>이미지: Everyeye에 게시된 Massive Monster 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://images.everyeye.it/img-notizie/che-tipo-gioco-cult-of-the-lamb-come-funziona-v6-602875-1200x1200.webp)</sub> | **Langrisser I & II** · [공식 자료](https://www.nisamerica.com/games/langrisser)  <br>참고할 것: 출신 질문·직업 분기·진영과 주인공의 선택  <br>피할 것: 캐릭터/직업명과 스토리 복제  <br>**VOID CARAVAN 적용:** 선장 선택지에 결과뿐 아니라 실제 대화/조우 차이 추가  <br><sub>이미지: Steam / NIS America 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://cdn.akamai.steamstatic.com/steam/apps/1060220/ss_5a60f8b41afb5e1f74406d0560c285648968b79f.1920x1080.jpg?t=1668469958)</sub> |


## 05 · 우주선 내부와 생존

### RimWorld

<img src="https://rimworldgame.com/biotech/screenshots/impids.jpg" width="420" alt="RimWorld — 이미지 출처: RimWorld 공식 스크린샷 (Ludeon)" loading="lazy" />

**RimWorld** · [공식 자료](https://rimworldgame.com/biotech/)  
참고할 것: 작업 가능한 내부 공간·승무원 행동·사건의 인과관계  
피할 것: 초반부터 과도한 생존 게이지와 복잡한 명령창  
**VOID CARAVAN 적용:** 승무원 1명이 실제 이동해 정비·제작·휴식을 하는 작은 함내 모듈부터  
<sub>이미지: RimWorld 공식 스크린샷 (Ludeon). 이미지가 표시되지 않으면 [원본 열기](https://rimworldgame.com/biotech/screenshots/impids.jpg)</sub>


## 06 · 제작·운영·상점

| <img src="https://www.nintendo.com/eu/media/images/06_screenshots/games_5/nintendo_switch_download_software_2/nswitchds_davethediver/NSwitchDS_DaveTheDiver_02_DEde.jpg" width="300" alt="DAVE THE DIVER — 이미지 출처: Nintendo 공식 게임 페이지 / MINTROCKET 제공" loading="lazy" /> | <img src="https://i0.wp.com/aiptcomics.com/wp-content/uploads/2018/06/Screen-Shot-2018-06-05-at-4.26.36-PM.png?fit=740%2C433&amp;ssl=1" width="300" alt="Moonlighter — 이미지 출처: AIPT 리뷰에 게시된 Digital Sun 게임 화면" loading="lazy" /> |
| :--- | :--- |
| **DAVE THE DIVER** · [공식 자료](https://www.mintrocketgames.com/ko/game/game.php)  <br>참고할 것: 탐험·획득과 귀환 후 운영의 리듬, 작은 발견의 누적  <br>피할 것: 초밥·해양 테마 및 미니게임 과밀화  <br>**VOID CARAVAN 적용:** 전리품의 종류가 우주선 제작·방문객 수요·다음 항로를 바꾸도록  <br><sub>이미지: Nintendo 공식 게임 페이지 / MINTROCKET 제공. 이미지가 표시되지 않으면 [원본 열기](https://www.nintendo.com/eu/media/images/06_screenshots/games_5/nintendo_switch_download_software_2/nswitchds_davethediver/NSwitchDS_DaveTheDiver_02_DEde.jpg)</sub> | **Moonlighter** · [공식 자료](https://digitalsungames.com/games/moonlighter/)  <br>참고할 것: 원정 전리품→상점 진열·가격·판매→업그레이드  <br>피할 것: 자동 정산 메뉴만 남는 운영  <br>**VOID CARAVAN 적용:** 플레이어가 작업대에 재료를 넣어 장비를 만들고 진열하는 물리적 흐름  <br><sub>이미지: AIPT 리뷰에 게시된 Digital Sun 게임 화면. 이미지가 표시되지 않으면 [원본 열기](https://i0.wp.com/aiptcomics.com/wp-content/uploads/2018/06/Screen-Shot-2018-06-05-at-4.26.36-PM.png?fit=740%2C433&ssl=1)</sub> |

### Overcooked! 2

<img src="https://img-eshop.cdn.nintendo.net/i/43b02178d85638fee4982f5b286c3aae8b91f6034b39e34512ed9ae082ca4e20.jpg" width="420" alt="Overcooked! 2 — 이미지 출처: Nintendo 공식 판매 페이지 / Team17 게임 스크린샷" loading="lazy" />

**Overcooked! 2** · [공식 자료](https://www.team17.com/games/overcooked-2)  
참고할 것: 공간·설비·동료 작업의 읽기 쉬운 병목  
피할 것: 모바일 싱글플레이에 과한 동시 미션  
**VOID CARAVAN 적용:** 함선 제작/판매 공간의 사람·재료 동선을 한 화면에 표현  
<sub>이미지: Nintendo 공식 판매 페이지 / Team17 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://img-eshop.cdn.nintendo.net/i/43b02178d85638fee4982f5b286c3aae8b91f6034b39e34512ed9ae082ca4e20.jpg)</sub>


## 07 · 본거지·시설·방어

| <img src="https://xboxwire.thesourcemediaassets.com/sites/2/2025/12/Screenshot2_DK_XSX-03716d193c63d680218a.png" width="300" alt="Dome Keeper — 이미지 출처: Xbox Wire 공식 게임 소개 이미지 / Raw Fury" loading="lazy" /> | <img src="https://files.giga-video.de/81/ee/73/83afb144bc6ccd1cb553df1b5a_AzhlOGY0Y2NjNWY1.jpg" width="300" alt="Fallout 4 — 이미지 출처: GIGA에 게시된 Bethesda 게임 스크린샷" loading="lazy" /> |
| :--- | :--- |
| **Dome Keeper** · [공식 자료](https://rawfury.com/games/dome-keeper/)  <br>참고할 것: 더 탐사할지 방어로 귀환할지의 위험-보상  <br>피할 것: 원작 채굴·돔 기지를 그대로 복제  <br>**VOID CARAVAN 적용:** 전초기지 방어전과 원정 타이밍의 교환비용  <br><sub>이미지: Xbox Wire 공식 게임 소개 이미지 / Raw Fury. 이미지가 표시되지 않으면 [원본 열기](https://xboxwire.thesourcemediaassets.com/sites/2/2025/12/Screenshot2_DK_XSX-03716d193c63d680218a.png)</sub> | **Fallout 4** · [공식 자료](https://fallout.bethesda.net/en/games/fallout-4)  <br>참고할 것: 거점 증설·방어시설 배치·거주민 생산  <br>피할 것: FPS 및 포스트 아포칼립스 표현 복제  <br>**VOID CARAVAN 적용:** 상점·벽·터렛 설치가 게임 화면에 지속적으로 남도록  <br><sub>이미지: GIGA에 게시된 Bethesda 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://files.giga-video.de/81/ee/73/83afb144bc6ccd1cb553df1b5a_AzhlOGY0Y2NjNWY1.jpg)</sub> |


## 08 · 모바일 제로 매뉴얼 UX

### Cut the Rope

<img src="https://cdn.mobygames.com/screenshots/7040818-cut-the-rope-android-the-spiders-are-gonna-get-that-candy.png" width="420" alt="Cut the Rope — 이미지 출처: MobyGames의 ZeptoLab 원작 게임 스크린샷" loading="lazy" />

**Cut the Rope** · [공식 자료](https://www.paladinstudios.com/cut-the-rope/)  
참고할 것: 설명보다 장면·물리 반응으로 이해하는 터치  
피할 것: 복잡한 버튼·텍스트 튜토리얼로 시작  
**VOID CARAVAN 적용:** 7세 초견 사용성은 실제 테스트 전까지 미검증  
<sub>이미지: MobyGames의 ZeptoLab 원작 게임 스크린샷. 이미지가 표시되지 않으면 [원본 열기](https://cdn.mobygames.com/screenshots/7040818-cut-the-rope-android-the-spiders-are-gonna-get-that-candy.png)</sub>


## 10 · 화면 시점 및 아트 선택

시점은 최신 D07/D18 기준. 아래 구현 상태는 과거 관찰이며 최신 배포/코드 검증 아님.

| 화면 | 현재 권장 시점 | 사용자에게 보여야 할 것 | 상태 |
| --- | --- | --- | --- |
| 은하 항행·세력전 | 탑다운 성도 | 소유 영토/교역로/항행 위험/실제 함선 위치 | 기본 성도 Alpha 0.2, 시뮬레이션 심화 전 |
| 함선 간 포격 | 탑다운 전술 액션 | 방향·속도·엄폐·적 함선 피해·승무원 역할 | 미구현 |
| 행성 탐험·잠입 | 쿼터뷰 액션 승인(D18); 벨트스크롤은 비교 이력 | 갈림길·비밀·외계 생물·위험-보상·회피/반격 | 지상 전투 실험만 구현 |
| 우주선 내부 | 미결(쿼터뷰 등 비교 후보; 픽셀/도트 강제 금지) | 사람의 이동, 제작·수리·휴식 실물 행동 | 미구현 |
| 본거지·상점·방어 | 미결(쿼터뷰 등 후보) | 실제 시설 증가, 고객 방문, 터렛·방벽 반응 | 미구현 |

**아트 원칙:** (1) 모바일 세로에서 플레이어·동료·위험과 조작 가능한 사물이 한눈에 구분될 것. (2) 세력마다 고유 형태·색·재료 문화가 있을 것. (3) UI는 항해/전투/관리 세 장면에서 통일된 SF 시각 언어를 사용할 것. (4) 과도한 가짜 CRT/글리치와 알아보기 힘든 극소 아이콘 배제. (5) 타격감은 화면 흔들림 하나가 아니라 예고·탄착·경직·음향·후속 행동을 통해 검증.

## 11 · 과거 비전과 이미지 연결 (참고 후보, 구현 지시 아님)

| 개발 시스템 | 먼저 볼 레퍼런스 | 과거 수용 테스트 후보 (재승인 필요) |
| --- | --- | --- |
| 정부/민간/반란/종교/해적의 자율 행동, 네임드 | Bannerlord + EVE | 동일 시드에서 NPC끼리 세력 충돌이 재현되고 항로 위험에 반영 |
| 중립 선장 생성/함선 선택, 직업/하이브리드 | Langrisser + Uncharted Waters | 서로 다른 출신·함선 선택이 항행/전투/교섭의 결과를 변화 |
| 항해 도중 발견·조우, 함선 간 전투, 잠입 | Black Flag + EVE | 플레이어가 거리/위험을 보고 싸움/도주/탐험 중 선택 |
| 행성 탐험·전투·희귀 생물 동료 수집 | Absolum + Monster Sanctuary + Cassette Beasts | 두 갈래에서 실제 다른 위험/보상, 동료 1종 구조 |
| 승무원 생존·제작·장비 강화 | RimWorld + Monster Sanctuary | 같은 승무원이 함선과 행성에서 다른 행동 |
| 행성 본거지·상점·시설 확장·습격 방어 | Moonlighter + Dave + Overcooked + Dome Keeper + Fallout 4 | 선택 가능한 경제 활동 후보: 전리품 제작→NPC 판매→시설 건설; 강제 루프 아님 |
| 설명 없는 터치/입력 발견/반복 재미 | Cut the Rope + Vampire Survivors | 첫 90초 초견 행동 관찰, 자동 테스트만으로 인증하지 않음 |

## 12 · 사용 제한 및 이미지 출처 관리

- **모든 스크린샷, 포스터, 게임명·캐릭터의 저작권은 원 권리자에게 있다.** 문서의 원격 이미지는 레퍼런스 열람을 위한 임베드일 뿐, 라이선스가 부여된 게임 제작 에셋이 아니다. 상품 페이지/공식 Press Kit 또는 출처가 표시된 게시물로 링크한다.
- 게임·마케팅·상업용 랜딩의 완성 에셋으로 복제·재배포하지 않는다. 외부 공개용 문서에 게시할 때는 각 권리자의 Press Kit 이용 조건 확인 후 필요하면 이미지 대신 링크로 대체한다.
- 원격 URL은 저작권 권한을 의미하지 않으며, 깨진 이미지를 임의 수집/재호스팅하지 않는다. 각 이미지 아래 출처와 원본 링크를 둔다.
- 각 게임은 **레퍼런스**이며 사용자의 프로젝트와 제휴/공식 관계가 없다. 조작/작품 자산을 그대로 카피하지 않는다.
- 과거 참고작인 **Chainsaw Juice King**(절삭 타격감), **Where's My Water? / Swampy**(제로 매뉴얼 터치), **Probably Stolen**(상점 운영) 등은 이전 과일 게임 연구 이력이며, SF RPG의 핵심 비주얼 보드에는 넣지 않았다. 필요 시 별도 Legacy 비교 문서로 관리한다.

