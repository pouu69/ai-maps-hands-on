#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:---dry-run}"
case "$MODE" in
  --dry-run|--yes) ;;
  --help) printf '사용법: bash scripts/uninstall.sh [--dry-run | --yes]\n설치 소유 기록의 도구·환경·캐시·모델만 삭제하며 지도 데이터·코드는 보존합니다.\n'; exit 0 ;;
  *) printf '알 수 없는 인자: %s. --help를 확인하세요.\n' "$MODE" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then printf '인자는 하나만 지정하세요.\n' >&2; exit 2; fi
if [ ! -f "$ROOT/.workshop-owned" ] || [ -L "$ROOT/.workshop-owned" ]; then
  printf '이번 셋업의 유효한 소유 기록이 없습니다. 아무것도 삭제하지 않았습니다.\n'
  exit 0
fi
# Validate the whole deletion set before changing anything; never accept a path.
while IFS= read -r directory; do
  case "$directory" in
    .tools|.cache|.venv|node_modules) ;;
    *) printf '소유 기록의 허용되지 않은 값: %s. 아무것도 삭제하지 않았습니다.\n' "$directory" >&2; exit 1 ;;
  esac
done < "$ROOT/.workshop-owned"
printf '삭제 대상(저장소 안):\n'
while IFS= read -r directory; do printf '  %s/%s\n' "$ROOT" "$directory"; done < "$ROOT/.workshop-owned"
printf '보존: 기존 전역 도구, data/, captures/, stylized/, corrected/, output/, reports/, config/, web/, 소스·문서·잠금 파일\n'
if [ "$MODE" != --yes ]; then
  printf '실제 삭제: bash scripts/uninstall.sh --yes\n'
  exit 0
fi
if ! mkdir "$ROOT/.setup.lock" 2>/dev/null; then
  printf '설치/삭제 작업의 .setup.lock이 있습니다. 실행 중인 작업이 끝난 뒤 재시도하세요.\n' >&2
  exit 1
fi
trap 'rmdir "$ROOT/.setup.lock"' EXIT
while IFS= read -r directory; do
  # A final-component symlink is removed itself; rm does not follow its target.
  rm -rf "$ROOT/$directory"
done < "$ROOT/.workshop-owned"
rm "$ROOT/.workshop-owned"
printf '실습 도구·환경·모델 삭제 완료. 사용 중인 터미널을 닫고 새로 열면 기존 PATH를 사용합니다.\n'
