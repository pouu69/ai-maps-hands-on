# 셋업과 삭제 가이드

설치되는 실습 환경은 이 저장소 안에 두며, 기존에 설치한 호환 도구를 재사용합니다. 셋업이 만든 항목은 삭제 스크립트로 정리할 수 있습니다.

## 설치 흐름

1. macOS·arm64 여부와 기존 설치 소유 기록을 확인합니다.
2. 고정 uv를 준비하고 기존 Python 3.12를 찾습니다. 없으면 `.python-version`의 버전을 `.tools/python`에 설치합니다.
3. 기존 arm64 Node.js 22~26을 찾습니다. 없으면 `.node-version`의 버전을 `.tools/node`에 설치합니다.
4. `package.json`의 `packageManager` 버전의 pnpm을 `.tools/pnpm`에 설치합니다. 기존 pnpm/Corepack은 실행하거나 변경하지 않습니다.
5. `uv.lock`과 `pnpm-lock.yaml`을 바꾸지 않고 실습 패키지만 설치합니다. `uv sync --no-default-groups`와 `pnpm install --prod`로 실습용 의존성만 설치합니다.
6. Chromium을 `.cache/playwright`에 설치하고 MFLUX 도움말·Chromium 실행을 확인합니다.
7. `.tools/activate`를 제공해 현재 셸에서 저장소 전용 경로·캐시를 사용하게 합니다.

실제 선택한 런타임 경로는 `.tools/runtime.env`에 있습니다. 활성화 파일의 `UV_PYTHON`은 이 Python을 지정하므로 기존 Python을 재사용해도 `uv run`이 대체 설치 버전을 다시 요구하지 않습니다. Python 바이트코드 캐시도 `.cache`로 모읍니다. 원격 설치 스크립트를 내려받아 바로 실행하지 않고 공식 파일의 SHA-256을 검증합니다. 고정 정보는 `setup/bootstrap.env`, 출처는 `setup/provenance.json`에 있습니다. Python 관리 설치의 배포 검증은 uv가 담당합니다.

## 먼저 무엇이 일어나는지 보기

```bash
bash scripts/setup.sh --dry-run
```

파일과 네트워크를 변경하지 않는 계획 확인입니다. 호환 도구의 실제 선택·설치 검증은 기본 셋업과 `--check`에서 수행합니다.

## 실제 설치

```bash
bash scripts/setup.sh
source .tools/activate
pnpm run setup:check
```

모델은 이 명령에 포함되지 않습니다. 수업 전에 별도로 받을 수 있습니다.

```bash
pnpm run setup:model
```

다운로드한 고정 모델은 `.cache/model` 경로로 사용할 수 있습니다. 이 경로는 저장소 안 캐시의 snapshot을 가리킵니다. 모델 캐시·해시 식별 정보는 `reports/model.json`에도 기록합니다.

## 실습 중 규칙

- 터미널·코딩 AI에서 이 저장소를 작업 폴더로 사용합니다.
- 새 터미널은 `source .tools/activate` 후 사용합니다.
- Python 명령은 `uv run --locked ...`, JavaScript 작업은 `pnpm run ...`을 사용합니다.
- 단계 중 새 패키지가 필요하면 이유·라이선스를 확인해 정확한 버전으로 추가하고 잠금 파일을 갱신합니다. 별도의 전역 `pip install`·`npm install -g`·`brew install`은 기본 셋업에 필요하지 않습니다.
- MFLUX에 `--model-path .cache/model`을 지정하고, 도구별 캐시는 활성화된 저장소 환경을 사용합니다. 저장소 밖에서 별도로 설치·다운로드한 것은 삭제 스크립트가 관리하지 않습니다.

## 삭제·복구

```bash
bash scripts/uninstall.sh
bash scripts/uninstall.sh --yes
```

첫 명령은 계획 확인, 두 번째는 실제 삭제입니다. 삭제 대상은 소유 기록에 있는 `.tools`·`.cache`·`.venv`·`node_modules` 네 폴더입니다. 지도 데이터와 결과물은 남습니다. 실습 프로그램과 서버를 먼저 종료한 뒤 삭제하세요. 모델을 사용 중인 프로세스가 있으면 먼저 끝냅니다.

다시 설치하려면 `bash scripts/setup.sh`를 실행합니다. 셋업과 삭제는 동시에 실행하지 마세요.

## 문제 해결

| 상황                                    | 확인·대응                                                                                                                       |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Intel·Rosetta·Windows·Linux             | 이번 자동 셋업 대상은 macOS arm64입니다. Apple Silicon 기본 터미널인지 확인                                                     |
| 기존 `.venv` 등을 덮어쓸 수 없다는 오류 | 다른 용도의 환경이 있는 폴더입니다. 새로 받은 저장소 폴더에서 시작. 기존 환경을 자동 삭제하지 않음                              |
| 다운로드·인증서 오류                    | 인터넷·방화벽·프록시·조직 인증서 설정 확인 후 같은 셋업 재실행. TLS 검증을 끄지 않음                                            |
| SHA-256 불일치                          | 받은 파일을 실행하지 않습니다. 공식 출처·고정 해시 확인. 임의로 검사를 끄지 않음                                                |
| `.setup.lock`이 남음                    | 실행 중인 작업 확인. 모두 종료됐고 강제 종료로 남은 것이면 `rmdir .setup.lock` 후 재실행                                        |
| `pnpm`·`uv`를 못 찾음                   | 저장소에서 `source .tools/activate`를 실행. 도구를 지웠다면 셋업 재실행                                                         |
| MFLUX import·Chromium 실행 실패         | 오류 전문과 macOS 버전을 기록. `bash scripts/setup.sh` 재실행 후 `--check`. 도구 설치 통과를 이미지 편집 성공으로 간주하지 않음 |
| 모델 다운로드 실패                      | 네트워크·저장 공간·해당 모델 저장소 권한 확인 후 `pnpm run setup:model` 재실행                                                  |
| 이미지 편집 메모리 부족                 | 설치 실패와 다른 문제입니다. 참가자 가이드의 저메모리·기기 대안 판단을 따름                                                     |
| 설치 소유 기록이 없음                   | 삭제 스크립트는 지우지 않습니다. `.workshop-owned`를 임의로 만들어 기존 환경을 삭제하지 마세요                                  |

기존 도구를 재사용한 경우 그 도구를 별도로 삭제·업그레이드하면 저장소도 영향을 받을 수 있습니다. 다음 셋업에서 다시 확인합니다. 실습 삭제 스크립트는 해당 전역 도구를 제거하지 않습니다.
