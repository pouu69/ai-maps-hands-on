# 도구·모델 출처

실제 설치 버전은 각 도구의 기준 파일과 잠금 파일을 따른다. 지도 데이터는 이후 참가자가 직접 수집하고 출처를 추가한다.

| 대상                     | 기준 파일                        | 공식 출처·이용 조건                                                                                                   |
| ------------------------ | -------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| uv                       | `setup/bootstrap.env`            | [공식 저장소](https://github.com/astral-sh/uv), [PyPI](https://pypi.org/project/uv/), MIT/Apache-2.0                  |
| 관리 Python              | `.python-version`                | uv가 제공하는 관리 Python, Python과 배포물의 라이선스·NOTICE 포함                                                     |
| 대체 설치 Node.js        | `.node-version`                  | [Node 공식 배포](https://nodejs.org/dist/), MIT 및 번들 구성요소 조건                                                 |
| pnpm                     | `package.json`                   | [공식 저장소](https://github.com/pnpm/pnpm), npm 배포, MIT                                                            |
| MFLUX·Python 전체 의존성 | `pyproject.toml`, `uv.lock`      | [MFLUX](https://github.com/mflux-community/mflux), 설치 배포물의 라이선스. 각 의존성 조건도 적용                      |
| three.js                 | `package.json`, `pnpm-lock.yaml` | [three.js](https://github.com/mrdoob/three.js), MIT                                                                   |
| Playwright·Chromium      | 같은 잠금 파일·브라우저 배포물   | [Playwright](https://github.com/microsoft/playwright), Apache-2.0, Chromium의 별도 구성요소 조건                      |
| FLUX.2 klein 4B          | `setup/model.json`               | [공식 모델 카드](https://huggingface.co/black-forest-labs/FLUX.2-klein-4B), Apache-2.0. 고정 리비전으로 별도 다운로드 |

uv·Node·pnpm bootstrap 파일의 공식 URL·무결성 값은 `setup/provenance.json`에 기록했다. Python·JavaScript 패키지 파일은 각각 uv·pnpm 잠금 파일로 고정한다. 라이선스 파일이 포함된 배포물의 고지는 삭제하지 않는다.

셋업은 OSM·Overture·국토부 원본, 원작의 그림·학습 데이터, 모델 가중치를 저장소에 묶어 배포하지 않는다. 이후 실제로 사용한 지도 자료의 출처·라이선스를 `sources.md`에 기록하고 화면과 내보낸 결과에도 적용한다.
