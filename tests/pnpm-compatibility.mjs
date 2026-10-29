import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, writeFile, copyFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { test } from "node:test";

// Regression: setup:check rejected local pnpm 10.32.1 despite a compatible lockfile.
test("local pnpm 10.x works without the former exact-version pin", { timeout: 10000 }, async () => {
  const root = new URL("../", import.meta.url);
  const npmrc = await readFile(new URL(".npmrc", root), "utf8");
  const pkg = JSON.parse(await readFile(new URL("package.json", root), "utf8"));
  assert.match(npmrc, /^package-manager-strict-version=false$/m);
  assert.equal(pkg.packageManager, undefined, "Corepack must not force an exact pnpm version");
  const fixture = await mkdtemp(path.join(tmpdir(), "workshop-pnpm-"));
  try {
    const playwright = path.join(fixture, "node_modules/playwright");
    await mkdir(playwright, { recursive: true });
    await copyFile(new URL("scripts/check-environment.mjs", root), path.join(fixture, "check.mjs"));
    await writeFile(path.join(playwright, "package.json"), JSON.stringify({ type: "module", exports: "./index.js" }));
    await writeFile(path.join(playwright, "index.js"), `
      export const chromium = {
        executablePath: () => process.execPath,
        launch: async () => ({
          newPage: async () => ({ setContent: async () => {}, title: async () => "Workshop setup check" }),
          close: async () => {}
        })
      };
    `);
    const pnpm = path.join(fixture, "pnpm");
    for (const [version, accepted] of [["10.32.1", true], ["10.34.9", true], ["9.15.0", false]]) {
      await writeFile(pnpm, `#!/bin/sh\nprintf '%s\\n' '${version}'\n`, { mode: 0o755 });
      const result = spawnSync(process.execPath, [path.join(fixture, "check.mjs")], {
        env: { ...process.env, WORKSHOP_PNPM_PATH: pnpm }, encoding: "utf8", timeout: 3000
      });
      assert.equal(result.status, accepted ? 0 : 1, `pnpm ${version}: ${result.stderr}`);
      assert.match(accepted ? result.stdout : result.stderr, accepted ? new RegExp(`pnpm ${version.replaceAll(".", "\\.")}`) : /pnpm 10.x가 필요합니다/);
    }
  } finally {
    await rm(fixture, { recursive: true, force: true });
  }
});
