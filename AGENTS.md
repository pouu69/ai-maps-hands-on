# Hands-on workspace

- 이 저장소의 README와 docs/participant-guide.md를 기준으로 현재 요청한 단계만 구현한다.
- 기본 셋업·삭제 스크립트, 패키지 버전·잠금 파일을 임의로 초기화하지 않는다.
- 코드 작성·실행은 이 저장소 안에서 진행하며 다른 완성 프로젝트를 복사하지 않는다.
- Python은 uv, JavaScript는 pnpm을 사용한다. 새 패키지는 필요한 것만 정확한 버전으로 추가하고 출처·라이선스를 기록한다.
- 원본과 파생 결과를 분리한다. 각자 고른 1km 구역의 OSM·Overture를 수집하며 지명·좌표를 특정 도시에 고정하지 않는다.
- 0단계에서 AI가 `scripts/run.sh`를 만든다. 이후 실습 명령은 `bash scripts/run.sh <명령과 인자>`로 실행해 저장소 환경을 적용한다. 참가자에게 `source .tools/activate`를 직접 요구하지 않는다.
- MFLUX·모델·캐시는 저장소 환경을 사용한다. 셋업의 소유 기록을 임의로 확대하지 않는다.
- 실제 실행 결과와 미확인 항목을 구분한다. 설치 확인은 `bash scripts/run.sh pnpm run setup:check`로 한다. 포맷·린트 도구는 기본 설치 대상이 아니다. 현재 단계에 필요한 실제 결과 확인을 우선한다.
