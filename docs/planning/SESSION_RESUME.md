# VOID CARAVAN — 현재 기획 위치 및 자료 안내
2026-11-27 · 현재 위치 STEP 7-2 / D47 미결. 승인 여부는 결정 이력 표 기준.

## 새 세션 필수 읽기 (3개)
1. 이 페이지 — 다음 선택·승인 게이트.
2. [통합 GDD](../LIVING_GALAXY_VISION.md) — 승인된 규칙·미결 세부사항.
3. [결정 이력](DECISION_HISTORY.md) — 선택·대안·이유. 해당 결정의 시각 자료 링크만 필요에 따라 연다.

## 재개할 대화
STEP 1–6 핵심 방향 승인 완료(D01–D45). STEP 7 D46 실제 생활·탐험 함선 내부+간편한 관리 화면 승인. **D47 함선 내부 시점과 공간 표현 미결:** A 탑다운 평면형 내부 / B 측면 단면형 내부 / C 지상과 연결되는 쿼터뷰 내부 + 필요 시 지붕·벽 가림 해제 및 전체 배치도(추천). D18 지상 쿼터뷰, D15 승선·탈취, D46 내부 이동·생활·간편 관리 연결. 카메라 각도/줌/벽 가림·층 이동·전체 배치도와 입력·아트 미결. [상세 예시](EXAMPLE_ARCHIVE.md#example-d47) · [시각 자료](DECISION_VISUAL_INDEX.md#d47). 사용자 승인 대기.

## 필요한 경우만 열기
| 필요한 정보 | 기준 문서 |
|---|---|
| 결정별 시각 자료·예시 | [결정별 색인](DECISION_VISUAL_INDEX.md) · [갤러리](REFERENCE_GALLERY.md) · [상세 예시](EXAMPLE_ARCHIVE.md) |
| 이미지 출처·원본 상태 | [manifest](reference-images/manifest.json) · [복구 대기](VISUAL_RECOVERY_QUEUE.md) |
| 사용자 발언 | [대화 기록](CONVERSATION_LOG.md) (전체 원문 아님) |
| 디자인·연구 | [아트 방향](../ART_DIRECTION.md) · [레퍼런스](REFERENCES.md) · [이론 적용](THEORY_APPLICATION.md) · [원본 연구](../GAME_DESIGN_THEORY.md) · [영상 연구](../VIDEO_RESEARCH_INBOX.md) |
| 출처 증거·도식 | [외부 출처](REFERENCE_EVIDENCE.md) · [자체 SVG 아틀라스](VISUAL_ATLAS.md) |
| 감사·과거 기술 | [최신 구조 감사](AUDIT_20261127_STRUCTURE.md) · [이전 감사](AUDIT_20261127_CLEANUP.md) · [기술 연구](../RESEARCH_LOG.md) · [이슈 #10](https://github.com/syjkim0125/harvest-deck/issues/10) |

## 변경 관리 계약
- 승인마다 GDD(규칙), 결정 이력(승인 여부·이유), 대화 기록(사용자 원문), 상세 예시(시나리오·UI·표), manifest(이미지 ID·결정·출처·참고 목적·제외 범위·원본 상태)를 갱신. 필요한 자체 이미지/인터랙션 원본, 연구 근거, 검증 가설도 함께 보존. 현재 위치는 이 페이지 기준; 역사적 미결 문장은 현재 상태로 사용하지 않는다.
- 시각 색인·갤러리·검색 기록·복구 대기는 manifest와 결정 이력 표에서 생성. `node docs/planning/tools/render-visual-views.mjs`, 확인은 `--check`. 도구 실행 불가 시 동일 함수로 생성 후 재조회. 원본 미확보와 권리 미확인을 숨기지 않음. 사용자 선호/기획 승인/아트 승인 구분. 이미지 원본 또는 실제 출처 링크·예시 연결이 필수이며 검색 문구만으로 원본 확보 완료 처리 금지.
- GDD 승인 규칙 우선. 예시·연구는 구현 승인 아님. 구 과일/강제 지상 전투/턴제 항해 방향 폐기; 기존 코드와 에셋은 기술 참고. 개발/디자인/리뷰 자동화 중지, 게임 코드/PR 수정·병합 금지.
- 사용자 지정 영상 P35fOgNdx_k 및 U-009 원본 검증 대기, vidIQ 크레딧 부족 반복 조회 금지. 선호 이미지 원본 복구 또는 명시적 대체 시안 사용자 확인→인게임 콘셉트→첫 10분 스토리보드/조작 프로토타입→통합 사용자 승인 후 개발. 실제 플레이 검증 전 재미/성능 달성 단정 금지.
- main 커밋 및 재조회로 결정·미결·시각 파일·링크를 검증.

## 새 채팅에 붙여 넣을 문장
`VOID CARAVAN 기획 세션을 이어서 진행해. GitHub syjkim0125/harvest-deck main의 docs/planning/SESSION_RESUME.md부터 읽고 현재 미결 결정부터 이어가. 개발/디자인/리뷰 자동화 중지 유지, 승인·예시·시각 자료·출처를 함께 갱신하고 검증해.`
