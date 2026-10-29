#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MODE=install
STEP="인자 확인"
TEMP_DIR=""
HAS_LOCK=0

fail() {
  printf '셋업 오류: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  # Only remove the temporary directory this invocation owns.
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
  if [ "$HAS_LOCK" = 1 ]; then rmdir "$ROOT/.setup.lock"; fi
}

on_error() {
  printf '셋업 실패 [%s]. 위 오류를 해결한 뒤 bash scripts/setup.sh를 다시 실행하세요.\n' "$STEP" >&2
}

trap cleanup EXIT
trap on_error ERR
trap 'printf "셋업 중단 [%s]. 같은 명령으로 재실행하세요.\n" "$STEP" >&2; exit 130' INT
trap 'printf "셋업 종료 [%s]. 같은 명령으로 재실행하세요.\n" "$STEP" >&2; exit 143' TERM

case "${1:-}" in
  "") ;;
  --help)
    printf '사용법: bash scripts/setup.sh [--check | --dry-run | --help]\n'
    printf '기본: 저장소 내부에 도구·패키지·Chromium 설치. 모델 가중치는 별도 다운로드.\n'
    exit 0 ;;
  --check) MODE=check ;;
  --dry-run) MODE=dry-run ;;
  *) printf '알 수 없는 인자: %s. --help를 확인하세요.\n' "$1" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  printf '인자는 하나만 지정하세요. --help를 확인하세요.\n' >&2
  exit 2
fi

STEP="지원 환경 확인"
OS="$(uname -s)"
ARCH="$(uname -m)"
if [ "$OS" != Darwin ] || [ "$ARCH" != arm64 ]; then
  printf '지원하지 않는 환경: %s/%s. macOS Apple Silicon의 기본 터미널에서 실행하세요. Intel/Rosetta·Windows·Linux는 대상이 아닙니다.\n' "$OS" "$ARCH" >&2
  exit 2
fi
case "$ROOT" in
  *$'\n'*|*$'\r'*) fail '저장소 경로에 줄바꿈이 있습니다. 일반 폴더명으로 옮긴 뒤 실행하세요.' ;;
esac

# Versions live in the package manifests and the two runtime version files.
source "$ROOT/setup/bootstrap.env"
PYTHON_VERSION="$(tr -d '\r\n' < "$ROOT/.python-version")"
NODE_VERSION="$(tr -d '\r\n' < "$ROOT/.node-version")"
if [ "$MODE" = dry-run ]; then
  printf '대상: %s\nuv %s → Python %s → Node.js %s → 기존 pnpm 10.x 또는 고정 대체 pnpm → uv sync --locked --no-default-groups → pnpm install --prod --frozen-lockfile → Chromium\n' "$ROOT" "$UV_VERSION" "$PYTHON_VERSION" "$NODE_VERSION"
  printf '호환되는 기존 Python·Node.js·pnpm·고정 uv 우선 사용. 없는 도구는 저장소 안에 설치. 시스템·셸 설정 변경 없음. 모델 가중치 다운로드 없음.\n'
  exit 0
fi

export UV_CACHE_DIR="$ROOT/.cache/uv"
export UV_PYTHON_INSTALL_DIR="$ROOT/.tools/python"
export UV_PYTHON_BIN_DIR="$ROOT/.tools/bin"
export UV_PYTHON_PREFERENCE=managed
export UV_PROJECT_ENVIRONMENT="$ROOT/.venv"
export UV_SYSTEM_CERTS=true
export HF_HOME="$ROOT/.cache/huggingface"
export MFLUX_CACHE_DIR="$ROOT/.cache/mflux"
export TORCH_HOME="$ROOT/.cache/torch"
export MPLCONFIGDIR="$ROOT/.cache/matplotlib"
export XDG_CACHE_HOME="$ROOT/.cache/xdg"
export PYTHONPYCACHEPREFIX="$ROOT/.cache/pycache"
export COREPACK_HOME="$ROOT/.cache/corepack"
export COREPACK_ENABLE_AUTO_PIN=0
export PLAYWRIGHT_BROWSERS_PATH="$ROOT/.cache/playwright"
export PATH="$ROOT/.tools/node/bin:$ROOT/.tools/pnpm/bin:$ROOT/.tools/uv:$ROOT/.tools/bin:$PATH"
UV="$ROOT/.tools/uv/uv"
NODE="$ROOT/.tools/node/bin/node"

if [ "$MODE" = check ]; then
  STEP="설치 검사"
  [ -f "$ROOT/.tools/runtime.env" ] || fail '설치 기록이 없습니다. bash scripts/setup.sh를 실행하세요.'
  source "$ROOT/.tools/runtime.env"
  [ -x "$UV" ] || fail 'uv가 없습니다. bash scripts/setup.sh를 실행하세요.'
  [ "$("$UV" --version | cut -d ' ' -f 2)" = "$UV_VERSION" ] || fail 'uv 버전이 다릅니다. 셋업을 다시 실행하세요.'
  [ -x "$NODE" ] || fail 'Node.js가 없습니다. 셋업을 실행하세요.'
  "$NODE" -e 'const n=Number(process.versions.node.split(".")[0]); if(n<20||n>26||(n===20&&Number(process.versions.node.split(".")[1])<19)||process.arch!=="arm64")process.exit(1)' || fail 'Node.js는 arm64 20.19 이상~26 계열이어야 합니다. 셋업을 다시 실행하세요.'
  [ -x "$ROOT/.venv/bin/python" ] || fail 'Python 가상환경이 없습니다. 셋업을 실행하세요.'
  "$ROOT/.venv/bin/python" -c 'import sys; assert sys.version_info[:2] == (3, 12), "Python 3.12 환경이 필요합니다"'
  "$ROOT/.venv/bin/python" -c 'from importlib.metadata import version; import mlx.core; import tomllib; from pathlib import Path; expected=next(d.split("==")[1] for d in tomllib.loads(Path("pyproject.toml").read_text())["project"]["dependencies"] if d.startswith("mflux==")); assert version("mflux")==expected; print("MFLUX", expected)'
  "$ROOT/.venv/bin/mflux-generate-flux2-edit" --help > /dev/null
  WORKSHOP_PNPM_PATH="$PNPM" "$NODE" "$ROOT/scripts/check-environment.mjs"
  printf '도구·MFLUX 명령·Chromium 설치 검사 통과. 실제 이미지 편집은 4단계에서 확인합니다.\n'
  exit 0
fi

for tool in curl shasum unzip tar; do
  command -v "$tool" > /dev/null || fail "$tool 명령이 없습니다. macOS 기본 도구를 복구한 뒤 재실행하세요."
done
if ! mkdir "$ROOT/.setup.lock" 2>/dev/null; then
  fail '다른 셋업/삭제 작업의 .setup.lock이 있습니다. 실행 중인 작업을 확인하세요. 중단된 작업이면 rmdir .setup.lock 후 재실행하세요.'
fi
HAS_LOCK=1
if [ -L "$ROOT/.workshop-owned" ]; then fail '.workshop-owned가 심볼릭 링크입니다. 새로 받은 저장소에서 실행하세요.'; fi
for directory in .tools .cache .venv node_modules; do
  if [ -e "$ROOT/$directory" ] || [ -L "$ROOT/$directory" ]; then
    if [ ! -f "$ROOT/.workshop-owned" ] || ! /usr/bin/grep -Fxq "$directory" "$ROOT/.workshop-owned"; then
      fail "$directory 폴더가 이미 있으며 이번 셋업 소유가 아닙니다. 덮어쓰지 않았습니다. 별도의 새 저장소 폴더에서 시작하세요."
    fi
    [ ! -L "$ROOT/$directory" ] || fail "$directory 폴더가 심볼릭 링크입니다. 새 저장소 폴더를 사용하세요."
  fi
done
if [ ! -f "$ROOT/.workshop-owned" ]; then
  printf '.tools\n.cache\n.venv\nnode_modules\n' > "$ROOT/.workshop-owned"
fi
mkdir -p "$ROOT/.tools" "$ROOT/.cache/downloads"
TEMP_DIR="$(mktemp -d "$ROOT/.tools/setup.XXXXXX")"

download() {
  local url="$1" expected="$2" destination="$3"
  if [ -f "$destination" ] && [ "$(shasum -a 256 "$destination" | cut -d ' ' -f 1)" = "$expected" ]; then
    return
  fi
  if ! curl --fail --location --silent --show-error --connect-timeout 20 --max-time 600 --retry 2 "$url" -o "$TEMP_DIR/download"; then
    fail "$url 다운로드 실패. 인터넷·방화벽·프록시를 확인하고 재실행하세요."
  fi
  local actual
  actual="$(shasum -a 256 "$TEMP_DIR/download" | cut -d ' ' -f 1)"
  [ "$actual" = "$expected" ] || fail "$url SHA-256 불일치(expected=$expected, actual=$actual). 설치하지 않았습니다. 제공자의 고정 해시와 다운로드 경로를 확인하세요."
  mv "$TEMP_DIR/download" "$destination"
}

STEP="uv 설치"
EXISTING_UV="$(command -v uv || true)"
if [ ! -x "$UV" ] && [ -n "$EXISTING_UV" ] && [ "$("$EXISTING_UV" --version | cut -d ' ' -f 2)" = "$UV_VERSION" ]; then
  UV="$EXISTING_UV"
fi
if [ ! -x "$UV" ] || [ "$("$UV" --version | cut -d ' ' -f 2)" != "$UV_VERSION" ]; then
  download "$UV_URL" "$UV_SHA256" "$ROOT/.cache/downloads/uv.whl"
  unzip -q "$ROOT/.cache/downloads/uv.whl" -d "$TEMP_DIR/uv"
  UV_BINARY="$TEMP_DIR/uv/uv-$UV_VERSION.data/scripts/uv"
  [ -f "$UV_BINARY" ] || fail 'uv 배포 파일에 실행 파일이 없습니다. bootstrap.env와 공식 배포 구조를 확인하세요.'
  chmod +x "$UV_BINARY"
  [ "$("$UV_BINARY" --version | cut -d ' ' -f 2)" = "$UV_VERSION" ] || fail '받은 uv 버전이 고정 버전과 다릅니다.'
  mkdir -p "$ROOT/.tools/uv"
  mv "$UV_BINARY" "$UV"
fi

STEP="Python 설치"
PYTHON=""
for candidate in python3.12 python3; do
  CANDIDATE_PATH="$(command -v "$candidate" || true)"
  if [ -n "$CANDIDATE_PATH" ] && "$CANDIDATE_PATH" -c 'import platform,sys; sys.exit(0 if sys.version_info[:2]==(3,12) and platform.machine()=="arm64" else 1)' 2>/dev/null; then
    PYTHON="$CANDIDATE_PATH"
    break
  fi
done
if [ -z "$PYTHON" ]; then
  "$UV" python install "$PYTHON_VERSION"
  PYTHON="$("$UV" python find "$PYTHON_VERSION")"
fi

STEP="Node.js 설치"
EXISTING_NODE="$(command -v node || true)"
if [ ! -x "$NODE" ] && [ -n "$EXISTING_NODE" ] && "$EXISTING_NODE" -e 'const n=Number(process.versions.node.split(".")[0]);process.exit(n>=20&&n<=26&&(n!==20||Number(process.versions.node.split(".")[1])>=19)&&process.arch==="arm64"?0:1)' 2>/dev/null; then
  NODE="$EXISTING_NODE"
fi
if [ ! -x "$NODE" ]; then
  NODE_ARCHIVE="node-v$NODE_VERSION-darwin-arm64.tar.gz"
  download "https://nodejs.org/dist/v$NODE_VERSION/$NODE_ARCHIVE" "$NODE_SHA256" "$ROOT/.cache/downloads/$NODE_ARCHIVE"
  mkdir "$TEMP_DIR/node"
  tar -xzf "$ROOT/.cache/downloads/$NODE_ARCHIVE" -C "$TEMP_DIR/node" --strip-components=1
  [ "$("$TEMP_DIR/node/bin/node" --version)" = "v$NODE_VERSION" ] || fail '받은 Node.js 버전이 고정 버전과 다릅니다.'
  # Keep a failed/previous install recoverable until a valid replacement exists.
  if [ -d "$ROOT/.tools/node" ]; then mv "$ROOT/.tools/node" "$TEMP_DIR/previous-node"; fi
  mv "$TEMP_DIR/node" "$ROOT/.tools/node"
fi
export PATH="$(dirname "$NODE"):$PATH"

STEP="pnpm 확인·설치"
PNPM=""
EXISTING_PNPM="$(command -v pnpm || true)"
# Probe Corepack without downloading a different pnpm; fallback stays repository-local.
if [ -n "$EXISTING_PNPM" ]; then
  if ACTUAL_PNPM_VERSION="$(COREPACK_ENABLE_NETWORK=0 "$EXISTING_PNPM" --version 2>/dev/null)"; then
    case "$ACTUAL_PNPM_VERSION" in
      10.*) PNPM="$EXISTING_PNPM" ;;
      *) printf '기존 pnpm %s: pnpm 10.x가 필요해 저장소 전용 버전을 준비합니다.\n' "$ACTUAL_PNPM_VERSION" ;;
    esac
  else
    printf '기존 pnpm을 실행할 수 없어 저장소 전용 버전을 준비합니다.\n'
  fi
fi
if [ -z "$PNPM" ]; then
  PNPM="$ROOT/.tools/pnpm/bin/pnpm"
  if [ ! -x "$PNPM" ] || [ "$("$PNPM" --version)" != "$PNPM_VERSION" ]; then
    download "https://registry.npmjs.org/pnpm/-/pnpm-$PNPM_VERSION.tgz" "$PNPM_SHA256" "$ROOT/.cache/downloads/pnpm.tgz"
    mkdir "$TEMP_DIR/pnpm"
    tar -xzf "$ROOT/.cache/downloads/pnpm.tgz" -C "$TEMP_DIR/pnpm" --strip-components=1
    [ "$("$NODE" "$TEMP_DIR/pnpm/bin/pnpm.cjs" --version)" = "$PNPM_VERSION" ] || fail '받은 pnpm 버전이 고정 버전과 다릅니다.'
    ln -s pnpm.cjs "$TEMP_DIR/pnpm/bin/pnpm"
    if [ -d "$ROOT/.tools/pnpm" ]; then mv "$ROOT/.tools/pnpm" "$TEMP_DIR/previous-pnpm"; fi
    mv "$TEMP_DIR/pnpm" "$ROOT/.tools/pnpm"
  fi
fi
export PATH="$(dirname "$PNPM"):$(dirname "$UV"):$PATH"

STEP="셸 활성화 파일 생성"
{
  for name in UV NODE PNPM PYTHON; do printf '%s=%q\n' "$name" "${!name}"; done
} > "$ROOT/.tools/runtime.env"
{
  printf '# 이 저장소 안의 도구와 캐시를 사용합니다. 셸 설정 파일은 수정하지 않습니다.\n'
  for name in UV_CACHE_DIR UV_PYTHON_INSTALL_DIR UV_PYTHON_BIN_DIR UV_PYTHON_PREFERENCE UV_PROJECT_ENVIRONMENT UV_SYSTEM_CERTS HF_HOME MFLUX_CACHE_DIR TORCH_HOME MPLCONFIGDIR XDG_CACHE_HOME PYTHONPYCACHEPREFIX PLAYWRIGHT_BROWSERS_PATH COREPACK_HOME COREPACK_ENABLE_AUTO_PIN; do
    printf 'export %s=%q\n' "$name" "${!name}"
  done
  # Override the fallback .python-version when an existing Python was selected.
  printf 'export UV_PYTHON=%q\n' "$PYTHON"
  printf 'export PATH=%q:%q:%q:"$PATH"\n' "$(dirname "$NODE")" "$(dirname "$PNPM")" "$(dirname "$UV")"
} > "$ROOT/.tools/activate"

STEP="Python 패키지 설치"
cd "$ROOT"
"$UV" sync --locked --no-default-groups --python "$PYTHON"
STEP="JavaScript 패키지 설치"
"$PNPM" install --prod --frozen-lockfile --store-dir "$ROOT/.cache/pnpm"
STEP="Chromium 설치"
"$PNPM" exec playwright install chromium
mkdir -p config data/raw data/processed captures stylized corrected output reports web
STEP="설치 검사"
bash "$ROOT/scripts/setup.sh" --check
MODEL_READY=0
if [ -L "$ROOT/.cache/model" ] && [ -d "$ROOT/.cache/model" ] && [ -f "$ROOT/reports/model.json" ]; then
  if "$PYTHON" -c 'import json,os,sys; from pathlib import Path; config=json.loads(Path(sys.argv[1]).read_text()); report=json.loads(Path(sys.argv[2]).read_text()); link=Path(sys.argv[3]).resolve(strict=True); expected=Path(report["local_path"]).resolve(strict=True); sys.exit(0 if config["repo_id"] == report["repo_id"] and config["revision"] == report["revision"] and link == expected and link.is_dir() else 1)' \
    "$ROOT/setup/model.json" "$ROOT/reports/model.json" "$ROOT/.cache/model"; then
    MODEL_READY=1
  fi
fi
printf '\n도구 설치·검사 완료.\n'
if [ "$MODEL_READY" = 1 ]; then
  printf '이미지 모델도 준비되어 있습니다. 다시 다운로드할 필요가 없습니다.\n'
else
  printf '이미지 모델은 아직 확인되지 않았습니다. 0단계 AI 요청문에서 준비하세요(약 15GB).\n'
fi
printf '다음: 참가자 가이드 0단계의 AI 요청문으로 실행 도우미와 프로젝트 맥락을 준비하세요.\n'
