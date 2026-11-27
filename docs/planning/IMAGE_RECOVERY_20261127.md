# 기획 이미지 원본 재확보 — 2026-11-27
사용자는 기획 레퍼런스용 원본 보존 요청. GitHub API에서 `syjkim0125/harvest-deck` visibility=public, private=false 확인. 공개 설정 변경 없음. 공개 저장소와 별도 로컬 연구용 보존을 구분.

- 기존 정확 URL 26개: 20개 고유 호스트 DNS 조회 전부 실패(temporary failure in name resolution).
- REF-26 HTTPS requests 실제 시도: DNS 실패. 별도 다운로드 도구도 실패.
- 새 외부 원본 파일 0개. 전체 26 URL의 HTTP 요청을 개별 실행했다고 표현하지 않음: 공통 호스트 DNS 수준에서 차단됨.
- 대화 검색 기록 59건: 정확한 원본 URL/이미지 바이트 미확보, 재검색 유사 이미지는 원본 아님. 사용자 D31 캡처 및 D36 선호 이미지 복구 대기.
- 공식 미디어: 기존 키트 링크 유지, Space Haven Press 안내 추가. ZIP 직접 다운로드 미확보.
- 로컬 수동 복구: 저장소 루트에서 `python3 docs/planning/tools/recover-reference-images.py`. 기본 출력은 홈 아래 VOID-CARAVAN-reference-images 폴더(저장소 외부). URL별 SHA256, 바이트 수, MIME, 성공/실패 report.json 저장. 외부 파일 공개 업로드 자동 수행하지 않음. 네트워크 정상 환경 필요. 실제 다운로드 성공 여부는 결과 보고서로 확인.
- 기존 자체 SVG 48개(D48 미승인 포함), 원격 URL 26개, 검색 기록 59개 유지. 전체 원본 파일을 확보했다는 주장 금지.
