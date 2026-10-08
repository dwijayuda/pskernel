import { rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptsDir, "..");

await rm(path.join(root, "dist"), { recursive: true, force: true });
process.stdout.write("PSC1_CLEAN: dist removed\n");
