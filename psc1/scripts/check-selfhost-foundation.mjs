import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

const preludePath = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
  "SelfHostPrelude.lean",
);
const prodPath = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
  "SelfHostProd.lean",
);
const testsPath = path.join(root, "test", "MinimalSelfHostTests.lean");

const prelude = await readFile(preludePath, "utf8");
const prod = await readFile(prodPath, "utf8");
const tests = await readFile(testsPath, "utf8");

for (const symbol of [
  "psSelfHostListNilName",
  "psSelfHostListConsName",
  "psSelfHostListRecName",
  "psSelfHostOptionNoneName",
  "psSelfHostOptionSomeName",
  "psSelfHostOptionRecName",
  "psSelfHostExceptName",
  "psSelfHostExceptErrorName",
  "psSelfHostExceptOkName",
  "psSelfHostExceptRecName",
  "psSelfHostRuntimePreludeDeclarations",
]) {
  if (!prelude.includes(symbol)) {
    throw new Error(`PSC2_SELFHOST_FOUNDATION_MISSING: ${symbol}`);
  }
}

for (const symbol of [
  "psSelfHostProdPreludeEnvironment",
  "psProdMkName",
  "psSelfHostRuntimePreludeDeclarationsWithProd",
  "true))",
]) {
  if (!prod.includes(symbol)) {
    throw new Error(`PSC2_SELFHOST_FOUNDATION_MISSING: ${symbol}`);
  }
}

for (const marker of [
  "foundational List -> TypeScript",
  "foundational Option preparation",
  "foundational Option -> VerifiedIR",
  "foundational Option -> TypeScript",
  "foundational Except preparation",
  "foundational Except -> VerifiedIR",
  "foundational Except -> TypeScript",
  "foundational Prod preparation",
  "foundational Prod -> VerifiedIR",
  "foundational Prod -> TypeScript",
]) {
  if (!tests.includes(marker)) {
    throw new Error(`PSC2_SELFHOST_FOUNDATION_TEST_MISSING: ${marker}`);
  }
}

process.stdout.write("PSC2_SELFHOST_FOUNDATION_CONTRACT: PASS (List, Option, Except, Prod)\n");
