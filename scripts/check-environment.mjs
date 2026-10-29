import { access } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { chromium } from "playwright";

const actual = execFileSync(process.env.WORKSHOP_PNPM_PATH, ["--version"], {
  encoding: "utf8",
}).trim();
if (!/^10\.\d+\.\d+$/.test(actual)) {
  throw new Error(
    `pnpm ${actual}: pnpm 10.x가 필요합니다. bash scripts/setup.sh를 다시 실행하세요.`,
  );
}
await access(chromium.executablePath());
let browser;
try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent("<title>Workshop setup check</title>");
  if ((await page.title()) !== "Workshop setup check") {
    throw new Error("Chromium 실행 확인에 실패했습니다. 셋업을 재실행하세요.");
  }
} finally {
  if (browser) await browser.close();
}
console.log(`Node.js ${process.version}, pnpm ${actual}, Chromium 실행 확인`);
