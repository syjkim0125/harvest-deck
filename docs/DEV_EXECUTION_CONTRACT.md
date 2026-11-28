# VOID CARAVAN — 개발 재개·통합 실행 계약
2026-11-28 사용자 지시. D01–D88 승인, D89 미결. 기획과 병렬로 매시간 개발+디자인+QA 통합 실행 재개. 이전 중지/일괄 백로그 소진/기존 구현 연장 지시를 대체한다. **승인된 방향에 한정한 단계적 개발 권한이며 전체 GDD·최종 아트·미결 수치/UX의 일괄 승인 아님.** 기획 세션만 결정 이력의 승인 상태를 변경한다.

## 기준 및 충돌 정리 (읽기 순서)
1. 이 문서와 최신 [SESSION_RESUME](planning/SESSION_RESUME.md), [GDD](LIVING_GALAXY_VISION.md), [DECISION_HISTORY](planning/DECISION_HISTORY.md). 승인된 결정만 구현 근거. 새 결정은 매 실행 최신 main에서 동기화. 예시/참고/가설/미결을 확정 기능으로 취급하지 않는다.
2. [ROADMAP](ROADMAP.md) → [ART_DIRECTION](ART_DIRECTION.md) → 해당 D번호 [결정별 시각 색인](planning/DECISION_VISUAL_INDEX.md) / [갤러리](planning/REFERENCE_GALLERY.md) / [예시](planning/EXAMPLE_ARCHIVE.md) → [THEORY_APPLICATION](planning/THEORY_APPLICATION.md), [GAME_DESIGN_THEORY](GAME_DESIGN_THEORY.md), [REFERENCE_ROUTER](REFERENCE_ROUTER.md), [VIDEO_RESEARCH_INBOX](VIDEO_RESEARCH_INBOX.md), [REFERENCE_EVIDENCE](planning/REFERENCE_EVIDENCE.md). 최신 근거와 원래 채택/제외 요소를 적용.
3. 과거 지시: 과일/체인소/주스 상점, Vampire Survivors식 강제 루프, 강제 낮밤, 벨트스크롤 시점, 목적지 선택 즉시 지상전, 고정 턴제 지도, 모든 공격 카드 클릭, 버튼 과다, 픽셀아트 일괄 강제는 폐기 또는 비채택. 기존 코드는 기술 비교용; 게임 방향을 기존 코드/테스트에 끼워 맞추지 말 것. Git 이력/사용자 선호 아트/검증된 기술 자산을 보존.
4. 실제 main 1738261b85cfcdc40217a05c016e5d0fbc34995b: project.godot의 시작 씬 sf_combat.tscn, scripts/sf_belt_scroll.gd의 고정 FIELD/STRIKE_POS/DODGE_POS 및 mode/wave, sf_galaxy_sim.gd의 turns/travel_to/advance_factions는 이전 구조를 드러낸다. 기존 방향 불합격 기록을 유지. 새 수직 슬라이스는 구 코드에서 분리된 씬/상태 모델 또는 명확히 분리된 모듈로 구현. 파일명·함수 이름만 바꾸지 말 것. 실제 동작을 매 실행 검증. 기존 테스트는 회귀 참고, 새 게임의 수용 기준은 별도.
5. 열린 PR #4 Veilwood/Nooli, #5 Amber Mantis, #6 impact experiment, #13 viewport/audio, #15 user-liked creature concepts는 일괄 병합 금지. 최신 기획/실제 코드/라이선스와 비교하여 REUSE/ADAPT/ARCHIVE/BLOCKED 분류, 필요한 기술·자체 에셋만 선별 적용. #15 사용자 선호와 최종 생산 아트 승인 구분. 현 상태는 정적 감사, 실행/병합/시각 검증 미실시.
6. manifest 현재 원본 미확보 chatExamples 142건(검색 문구/재구성), 외부 이미지 개별 렌더링/권리 확인 제한. 원본 없는 검색 문구는 원본으로 간주 금지. 접근 가능한 실제 참고 장면을 열어 확인하고 출처·D번호·채택/제외 원리 기록. 대체 이미지 명시, 원작 IP 복제/무단 재배포 금지. 원본 없는 항목은 대체 자체 콘셉트로 검증, 시각 미확정 사항은 임시안 표시. 영상 U-009/P35fOgNdx_k 미검증, vidIQ 크레딧 부족 시 반복 유료 조회 금지.

## 통합 사이클 (단일 개발 작업이 책임)
- 최신 main, PR/CI/배포, 진행 중 작업과 기획 변경, [DEV_PROGRESS](DEV_PROGRESS.md)를 먼저 읽고 실제 장애 재확인. 첫 실행은 GitHub 읽기/쓰기 접근과 실행 가능한 환경을 실제 확인. 중복 작성 금지. 같은 실행에서 backlog의 기획 부합 여부를 분류하고 첫 마일스톤의 플레이 가능한 묶음을 가능한 만큼 진전.
- 각 묶음: 사용자 승인 D번호/플레이 의도→참고 장면과 이론→원본 아트/씬/조작 설계→실제 Godot 코드·에셋·애니메이션·사운드/피드백 통합→회귀 및 새 수용 테스트→실제 모바일 세로 화면 캡처/가능한 직접 플레이→자체 리뷰와 수정→PR, CI, 검증된 변경 병합 및 기존 Pages 배포 SHA 확인. CI가 불합격/실행 불가/충돌하면 병합 금지. 프로토타입은 명시적으로 구분하고 기존 사용자 검증 빌드를 조용히 대체하지 않음; 메인 공개 전 최소 정상 실행·새 수용 조건 및 눈에 보이는 개선 증거, 기존 설정/배포 경로 확인. 실행 시간/도구가 부족하면 안전한 단위로 커밋·PR, 장애·다음 단계 기록하고 다음 실행 우선 재개. force push/이력 삭제/미승인 설정 변경 금지.
- 디자인은 별도 나중 작업이 아님. 원본 2D 회화적 깊이/조명/실루엣, 귀여운 외계 동료(Kindchenschema), 색/일관성, 터치 가독성, 작은 화면, 타격감/음향/동작을 각 기능과 함께 적용. 임시 도형은 내부 디버그 용도이며 플레이 제출물로 인정하지 않는다. 최종 팔레트/해상도/표현 방식 등 미결은 가역적 프로토타입으로 유지. 디자인 선택지와 사용자 선호 근거 연결.
- 게임 이론: Koster 학습·판단·변주·결과; Zelda/Tunic 호기심·가림·연쇄 발견; Absolum/GDC juice 명중/빗나감 구별·예고/접촉/회복·입력 응답; Bannerlord 인과적 세계; 대항해시대/Black Flag 실제 항해; RimWorld/Space Haven 자율 일과·물류; Vanillaware 회화적 레이어; Cut the Rope/Where's My Water 직관 터치. 각 실행 관련 근거 하나 이상을 실제 변경과 수용 가설에 연결. 새 연구가 필요할 때 공식 자료/영상 검증, 무의미한 반복 검색·기능 추가 금지.
- 테스트: 실제 엔진 임포트, 대상 회귀, 새 시나리오, 세로 화면/터치/안전 영역/프레임 시간 관찰, 저장 복구, 웹 export/CI. 사람의 재미·아트 승인·실기기 성능은 자동 테스트와 별도 상태. 수행하지 못한 항목 NOT_RUN 명시. 새 GDD와 충돌하는 테스트는 구 테스트를 삭제하거나 무조건 통과시키지 말고 신규 수용 테스트 분리.
- 매 실행 DEV_PROGRESS에 최신 SHA, D번호, 플레이어가 체감할 변화, 에셋/레퍼런스 출처, 실제 수행 테스트/캡처/PR/CI/배포 SHA, 미확정/장애 및 다음 작업 기록. 사용자에게 한국어로 요약. 같은 기능의 미완료 구현·디자인·리뷰 먼저 닫고 문서만 추가하거나 사소한 수치만 고치고 완료 선언하지 말 것.
- 사용자 통합 검토 전에도 승인된 핵심 구조의 가역적 수직 슬라이스 개발 가능(이번 지시). 전체 기능 완성·최종 디자인 승인은 별개. D89 이후 미승인 결정 및 되돌리기 어려운 전면 확장 금지. 이 문서와 최신 사용자 지시 우선.
