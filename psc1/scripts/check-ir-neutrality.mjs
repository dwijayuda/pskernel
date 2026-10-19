import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptsDir, "..");
const irRoot = path.join(root, "packages", "compiler-ir", "src");

const files = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (entry.isFile() && entry.name.endsWith(".lean")) files.push(file);
  }
}

walk(irRoot);

const forbidden = [
  [/\bPs\.Backend/, "backend namespace dependency"],
  [/\bTypeScript\b|\bJavaScript\b/, "TypeScript/JavaScript target concept"],
  [/\bWebAssembly\b|\bWasm\b|\bWASI\b|\bWIT\b/, "WebAssembly target concept"],
  [/\bCargo\b|\brustc\b/, "Rust toolchain target concept"],
  [/\bnpm\b|\bNode(?:\.js)?\b/, "JS host/package target concept"],
  [/\bbigint\b/, "JavaScript bigint representation"],
  [/\b(?:u8|u16|u32|u64|i8|i16|i32|i64|f32|f64)\b/, "target machine spelling"],
  [/\bstruct\.new\b|\barray\.new\b|\bcall_ref\b/, "Wasm opcode"],
];

let failed = false;
for (const file of files) {
  const source = fs.readFileSync(file, "utf8");
  for (const [pattern, label] of forbidden) {
    if (pattern.test(source)) {
      console.error(
        `PSC_IR_NEUTRALITY_FAIL: ${path.relative(root, file)}: ${label}`,
      );
      failed = true;
    }
  }
}

if (files.length === 0) {
  console.error("PSC_IR_NEUTRALITY_FAIL: no compiler IR source files found");
  failed = true;
}

if (failed) process.exit(1);

console.log(
  `PSC_IR_NEUTRALITY_PASS: ${files.length} compiler IR source file(s)`,
);
