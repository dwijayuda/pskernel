import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const kernelCoreRoot = path.join(root, "packages", "pskernel-core", "src");
const referenceRoot = path.join(root, "packages", "pskernel", "PSC1Kernel");

function walkLean(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...walkLean(absolute));
    else if (entry.isFile() && entry.name.endsWith(".lean")) files.push(absolute);
  }
  return files.sort();
}

function stripLeanComments(source) {
  let output = "";
  let index = 0;
  let blockDepth = 0;
  let inString = false;
  let escaped = false;

  while (index < source.length) {
    const char = source[index];
    const next = index + 1 < source.length ? source[index + 1] : "";

    if (blockDepth > 0) {
      if (char === "/" && next === "-") {
        blockDepth += 1;
        output += "  ";
        index += 2;
      } else if (char === "-" && next === "/") {
        blockDepth -= 1;
        output += "  ";
        index += 2;
      } else {
        output += char === "\n" ? "\n" : " ";
        index += 1;
      }
      continue;
    }

    if (inString) {
      output += char;
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === "\"") {
        inString = false;
      }
      index += 1;
      continue;
    }

    if (char === "\"") {
      inString = true;
      output += char;
      index += 1;
      continue;
    }

    if (char === "-" && next === "-") {
      output += "  ";
      index += 2;
      while (index < source.length && source[index] !== "\n") {
        output += " ";
        index += 1;
      }
      continue;
    }

    if (char === "/" && next === "-") {
      blockDepth = 1;
      output += "  ";
      index += 2;
      continue;
    }

    output += char;
    index += 1;
  }

  return output;
}

function metrics(files) {
  let bytes = 0;
  let loc = 0;
  for (const file of files) {
    const source = fs.readFileSync(file, "utf8");
    bytes += Buffer.byteLength(source, "utf8");
    const withoutComments = stripLeanComments(source);
    loc += withoutComments
      .split(/\r?\n/u)
      .filter((line) => line.trim().length > 0).length;
  }
  return { files: files.length, bytes, loc };
}

const referenceExcludedBasenames = new Set([
  "Replay.lean",
  "ReplayJson.lean",
  "NativeMap.lean",
]);

const kernelCoreFiles = walkLean(kernelCoreRoot);
const referenceFiles = walkLean(referenceRoot).filter((file) => {
  const relative = path.relative(referenceRoot, file).split(path.sep).join("/");
  if (relative.startsWith("Test/")) return false;
  if (referenceExcludedBasenames.has(path.basename(file))) return false;
  return true;
});

if (kernelCoreFiles.length === 0) {
  throw new Error("KERNEL_CORE_SIZE_REPORT: no KernelCore Lean files found");
}
if (referenceFiles.length === 0) {
  throw new Error("KERNEL_CORE_SIZE_REPORT: no PSC1Kernel baseline Lean files found");
}

const kernelCore = metrics(kernelCoreFiles);
const reference = metrics(referenceFiles);
const byteRatio = kernelCore.bytes / reference.bytes;
const locRatio = kernelCore.loc / reference.loc;

console.log("KERNEL_CORE_SIZE_REPORT: PASS");
console.log(`KernelCore trusted .lean file count: ${kernelCore.files}`);
console.log(`KernelCore trusted source bytes: ${kernelCore.bytes}`);
console.log(`KernelCore trusted nonblank/noncomment LOC: ${kernelCore.loc}`);
console.log(`PSC1Kernel comparable .lean file count: ${reference.files}`);
console.log(`PSC1Kernel comparable semantic-source bytes: ${reference.bytes}`);
console.log(`PSC1Kernel comparable nonblank/noncomment LOC: ${reference.loc}`);
console.log(`KernelCore/reference byte ratio: ${byteRatio.toFixed(4)}`);
console.log(`KernelCore/reference LOC ratio: ${locRatio.toFixed(4)}`);
console.log(
  "Reference exclusions: Test/**, Replay.lean, ReplayJson.lean, NativeMap.lean",
);
console.log(
  "LOC rule: count lines with non-whitespace after removing Lean -- comments and nested /- -/ comments; preserve string contents",
);
console.log("KernelCore trusted files:");
for (const file of kernelCoreFiles) {
  console.log(`  - ${path.relative(root, file).split(path.sep).join("/")}`);
}
console.log("PSC1Kernel comparable baseline files:");
for (const file of referenceFiles) {
  console.log(`  - ${path.relative(root, file).split(path.sep).join("/")}`);
}
