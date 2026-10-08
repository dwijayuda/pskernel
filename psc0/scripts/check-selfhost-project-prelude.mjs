import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const driverPath = path.join(root, "host", "src", "Ps", "Host", "CompilerDriver.lean");
const source = await readFile(driverPath, "utf8");

const elaborateProjectStart = source.indexOf("def psHostCompilerElaborateProject");
const checkStart = source.indexOf("def psHostCompilerCheck");
if (elaborateProjectStart < 0 || checkStart <= elaborateProjectStart) {
  throw new Error("PSC2_SELFHOST_PROJECT_PRELUDE: compiler project entry missing");
}

const elaborateProject = source.slice(elaborateProjectStart, checkStart);
if (!elaborateProject.includes("psSelfHostProdPreludeEnvironment")) {
  throw new Error("PSC2_SELFHOST_PROJECT_PRELUDE: project elaboration must use current selfhost foundation");
}
if (elaborateProject.includes("psBootstrapPreludeEnvironment")) {
  throw new Error("PSC2_SELFHOST_PROJECT_PRELUDE: project elaboration regressed to bootstrap prelude");
}
if (elaborateProject.includes("psSelfHostPreludeEnvironment")) {
  throw new Error("PSC2_SELFHOST_PROJECT_PRELUDE: project elaboration regressed to pre-Prod selfhost prelude");
}

process.stdout.write("PSC2_SELFHOST_PROJECT_PRELUDE: PASS (Prod foundation)\n");
