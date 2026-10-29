# 우리 동네 AI 지도 핸즈온

이 저장소를 받은 뒤 셋업하고, 같은 폴더에서 자기 동네 1km × 1km의 OSM·Overture 수집부터 그림 웹 지도까지 AI와 직접 구현합니다. 지도 제작 완성 코드는 제공하지 않습니다.

**현재는 진행자와 함께 구현하는 실습 초안입니다.** 설치·삭제·재설치는 확인했지만, 지도 제작 전체와 MFLUX 이미지 편집은 아직 검증하지 않았습니다. 수업 시간과 기기별 완료 가능 여부는 실제 리허설 후 확정합니다.

## 1. 저장소 받기

공유받은 이 저장소를 clone하세요. Git이 없으면 저장소의 **Code → Download ZIP**으로 내려받아 압축을 푸세요. 편집기와 터미널에서 그 폴더를 여세요. README와 `scripts/`가 보이는 위치에서 아래 명령을 실행합니다. 시스템 Git이 없으면 ZIP 방식으로 시작할 수 있습니다.

## 2. 기본 셋업

대상은 **macOS Apple Silicon**입니다. 인터넷과 패키지·브라우저 저장 공간이 필요합니다. 모델까지 사용하려면 여유 공간 30GB 이상을 계획용으로 권장합니다.

```bash
bash scripts/setup.sh
source .tools/activate
pnpm run setup:check
```

호환되는 기존 Python 3.12와 arm64 Node.js 22~26은 재사용합니다. 고정 버전과 일치하는 uv도 재사용합니다. pnpm은 기존 Corepack의 전역 캐시 생성을 피하도록 저장소 내부에 따로 준비합니다. 없는 도구도 저장소 내부에 설치합니다. MFLUX·Python 패키지는 `.venv`, three.js·Playwright는 `node_modules`, Chromium·패키지 캐시는 `.cache`에 둡니다. sudo·Homebrew 설치나 셸 설정 변경은 하지 않습니다.

기본 설치는 MFLUX·three.js·Playwright·Chromium을 준비하며, Prettier·Ruff 등 개발용 도구는 설치하지 않습니다.

새 터미널을 열 때는 저장소로 이동하고 다시 실행하세요.

```bash
source .tools/activate
```

## 3. 이미지 모델 준비 — 약 15GB, 별도 실행

```bash
pnpm run setup:model
```

`setup/model.json`의 고정 리비전을 저장소의 `.cache`에 받습니다. 끊겼다면 같은 명령으로 재시도하세요. 다운로드 후 실습에서는 `--model-path .cache/model`을 사용합니다. 모델 다운로드 성공과 이미지 편집 성공은 별도로 확인합니다.

## 4. 이 저장소에서 핸즈온 시작

[참가자 가이드](docs/participant-guide.md)를 0단계부터 진행하세요. [HTML 가이드](docs/participant-guide.html)는 브라우저에서 열어 요청문 복사·목차·인쇄를 사용할 수 있습니다.

참가자는 좌표·화풍 선택, 명령 실행, 결과 확인을 맡습니다. AI는 단계별 코드를 작성하고 오류를 수정합니다. 가이드의 AI 요청문 앞에서 무엇을 만들기 위한 요청인지 확인하고, 실제 코드가 준비된 뒤 실행하세요.

기본 흐름은 **OSM·Overture 수집 → bin → three.js·시험 촬영 3장 → MFLUX 화풍 시험·전체 처리 → 필요한 보정 → 타일 생성 → 로컬 웹 지도**입니다. 실제 지형·불빛·공개 배포는 선택입니다. 학습·GPU 서버·유료 이미지 API는 사용하지 않습니다.

폴더를 새로 만들거나 `uv init`, `npm init`을 다시 실행하지 마세요. 기본 패키지·잠금 파일·셋업/삭제 스크립트는 유지하고, 수집·bin·엔진·촬영·후처리·뷰어 코드를 이 저장소에 추가합니다.

## 5. 종료 후 쉽게 삭제

설치 항목을 먼저 확인합니다. 이 명령은 지우지 않습니다.

```bash
bash scripts/uninstall.sh
```

확인 후 실제로 삭제합니다.

```bash
bash scripts/uninstall.sh --yes
```

| 삭제                                                 | 보존                                        |
| ---------------------------------------------------- | ------------------------------------------- |
| 셋업이 만든 `.tools`·`.venv`·`node_modules`·`.cache` | 기존 전역 Python·Node·pnpm·uv               |
| MFLUX·실습 패키지·모델 가중치·Chromium·캐시          | 작성한 코드·문서·잠금 파일                  |
| 저장소 안에 추가한 런타임                            | 지도 원본·촬영·변환 이미지·완성 지도·보고서 |

`.workshop-owned`에 있는 허용 폴더만 지우며, 소유 기록이 없으면 기존 환경을 삭제하지 않습니다. 삭제 후 터미널을 닫으세요. 다시 설치하려면 같은 저장소에서 셋업 명령을 실행하면 됩니다. 모든 과제 파일까지 없애려면 필요한 결과를 별도 보관한 뒤 저장소 폴더를 직접 정리하세요.

## 저장소 구성

- `docs/`: 참가자 가이드, 셋업·삭제 안내, 도구 출처
- `scripts/`: 설치·삭제·모델 다운로드·설치 확인
- `setup/`: 설치 도구의 고정 버전·해시와 모델 정보
- `package.json`, `pnpm-lock.yaml`: three.js·Playwright 의존성
- `pyproject.toml`, `uv.lock`: MFLUX 의존성
- `AGENTS.md`: 실습 중 코딩 AI가 지킬 작업 규칙

수집·가공·렌더·뷰어 코드는 실습하면서 이 저장소에 추가합니다. 설치된 환경과 생성 데이터·이미지는 Git에서 제외합니다.

## 관련 문서

- [자세한 셋업·문제 해결](docs/setup.md)
- [패키지·모델 출처](docs/third-party.md)

현재 이 저장소는 공유용 로컬 초안입니다. 원격 저장소 생성·push·공개 배포는 아직 수행하지 않았습니다.
