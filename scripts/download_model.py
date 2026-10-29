"""Download the pinned image model; never train or generate an image here."""

import json
import os
import re
import sys
from pathlib import Path

from huggingface_hub import snapshot_download

ROOT = Path(__file__).resolve().parents[1]


def main():
    os.environ["HF_HOME"] = str(ROOT / ".cache/huggingface")
    config = json.loads((ROOT / "setup/model.json").read_text())
    revision = config["revision"]
    if not re.fullmatch(r"[a-f0-9]{40}", revision):
        raise ValueError("setup/model.json의 revision은 실제 고정 커밋 SHA여야 합니다.")
    print(f"다운로드: {config['repo_id']} @ {revision}")
    print(
        "약 15GB 모델과 임시 저장 공간이 필요합니다. 이미지 생성은 실행하지 않습니다."
    )
    try:
        location = snapshot_download(
            repo_id=config["repo_id"],
            revision=revision,
            cache_dir=str(ROOT / ".cache/huggingface/hub"),
        )
    except Exception as error:
        print(
            f"모델 다운로드 실패({type(error).__name__}). 네트워크·저장 공간·"
            "해당 저장소의 접근 권한을 확인하고 pnpm run setup:model을 재실행하세요.",
            file=sys.stderr,
        )
        return 1
    report = ROOT / "reports/model.json"
    model_link = ROOT / ".cache/model"
    if model_link.is_symlink():
        model_link.unlink()
    elif model_link.exists():
        raise ValueError(
            ".cache/model이 심볼릭 링크가 아닙니다. 기존 파일을 확인한 뒤 경로 충돌을 해결하세요."
        )
    model_link.symlink_to(location, target_is_directory=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({**config, "local_path": location}, indent=2) + "\n")
    print(
        f"모델 다운로드 완료. 위치: {location}\n첫 편집 때 --model-path .cache/model을 사용하세요."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
