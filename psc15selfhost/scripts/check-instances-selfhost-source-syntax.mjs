import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/environment/src/Ps/Environment/Instances.lean"),
  "utf8",
);

const required = [
  "List.cons entry (psInstanceListAppend rest right)",
  "psInstanceListAppend index.entries (List.cons entry [])",
  "| .binding id _ type binder =>",
  "match binder with",
  "| .instanceImplicit =>",
  "let instanceEntry : PsInstanceEntry := {",
  "List.cons instanceEntry (psLocalInstanceEntriesFromList rest)",
];

for (const marker of required) {
  if (!source.includes(marker)) {
    throw new Error(`PSC2_INSTANCES_SELFHOST_SOURCE_SYNTAX_MISSING: ${marker}`);
  }
}

const forbidden = [
  "=> entry :: psInstanceListAppend rest right",
  "index.entries [entry]",
  "| .binding id _ type .instanceImplicit =>",
  "} :: psLocalInstanceEntriesFromList rest",
];

for (const marker of forbidden) {
  if (source.includes(marker)) {
    throw new Error(`PSC2_INSTANCES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_INSTANCES_SELFHOST_SOURCE_SYNTAX: PASS (explicit List.cons terms and unary binder matching)\n",
);
