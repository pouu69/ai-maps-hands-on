import { readFile, access } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { chromium } from "playwright";

const root = fileURLToPath(new URL("../", import.meta.url));
const pkg = JSON.parse(await readFile(path.join(root, "package.json"), "utf8"));
const actual = execFileSync(process.env.WORKSHOP_PNPM_PATH, ["--version"], {
  encoding: "utf8",
}).trim();
if (`pnpm@${actual}` !== pkg.packageManager) {
  throw new Error(
    `pnpm ${actual}: packageManager와 다릅니다. 셋업을 재실행하세요.`,
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
