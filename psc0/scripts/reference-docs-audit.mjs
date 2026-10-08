import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

// Read-only research tooling. Never import documentary content into the compiler.
// A shallow snapshot of every branch tip is used, not every historical revision.
export async function auditReferenceDocs() {
  const directory = await mkdtemp(path.join(tmpdir(), "psc2-reference-docs-"));
  const repository = path.join(directory, "repo.git");
  function git(args, input) {
    const result = spawnSync("git", args, {
      encoding: "utf8", input, timeout: 180000,
      maxBuffer: 64 * 1024 * 1024,
      env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
    });
    if (result.error) throw result.error;
    if (result.status !== 0) throw new Error(`REFERENCE_GIT_FAILED: ${result.stderr}`);
    return result.stdout;
  }
  try {
    // Fetch complete shallow snapshots. Explicit blob wants in a partial clone
    // failed connectivity checks on this repository; avoid incomplete object sets.
    git(["clone", "--quiet", "--bare", "--depth=1", "--no-single-branch",
      "https://github.com/dwijayuda/pskernel.git", repository]);
    const tips = git(["--git-dir", repository, "for-each-ref",
      "--format=%(refname:strip=2)\t%(objectname)", "refs/heads/"])
      .trim().split("\n").filter(Boolean).map((line) => {
        const [branch, head] = line.split("\t");
        return { branch, head };
      });
    const documents = new Map();
    let occurrences = 0;
    const binary = [];
    for (const tip of tips) {
      const entries = git(["--git-dir", repository, "ls-tree", "-rz", tip.head]);
      let count = 0;
      for (const entry of entries.split("\0")) {
        if (!entry) continue;
        const tab = entry.indexOf("\t");
        const [mode, type, sha] = entry.slice(0, tab).split(" ");
        const name = entry.slice(tab + 1);
        if (type !== "blob" || mode === "120000") continue;
        if (/\.(pdf|docx|odt)$/iu.test(name)) {
          binary.push({ ...tip, path: name, sha });
          continue;
        }
        if (!/\.(md|markdown|rst|adoc|txt|org)$/iu.test(name) &&
            !/^(README|CHANGELOG|CONTRIBUTING|LICENSE|COPYING|NOTICE)$/iu.test(path.posix.basename(name))) continue;
        count += 1;
        occurrences += 1;
        const record = documents.get(sha) ?? { sha, references: [] };
        record.references.push({ ...tip, path: name });
        documents.set(sha, record);
      }
      console.log(`PSC2_REFERENCE_BRANCH ${JSON.stringify({ ...tip, documents: count })}`);
    }
    const shas = [...documents.keys()].sort();
    let textBytes = 0;
    let fullDocuments = 0;
    for (const sha of shas) {
      const record = documents.get(sha);
      const content = git(["--git-dir", repository, "cat-file", "blob", sha]);
      textBytes += Buffer.byteLength(content, "utf8");
      const references = record.references;
      const primary = references.find((ref) => ref.branch === "psc2/minimal-selfhost-psc15") ?? references[0];
      const lines = content.split(/\r?\n/u);
      const headings = lines.flatMap((text, index) => /^#{1,4} /.test(text) ? [{ line: index + 1, text }] : []);
      console.log(`PSC2_REFERENCE_DOCUMENT ${JSON.stringify({ sha, ...primary,
        occurrences: references.length, lines: lines.length, bytes: Buffer.byteLength(content), headings })}`);
      // Retain complete self-host/compiler design documents; other documents are
      // inventoried and scanned, not represented as having received a close review.
      const relevant = references.some((ref) => /selfhost|self-host|PSC[12] Lang|bootstrap|proofscript.*(?:architecture|roadmap)/iu.test(ref.path));
      if (relevant && !content.includes("\u0000")) {
        fullDocuments += 1;
        console.log(`PSC2_REFERENCE_TEXT_BEGIN ${sha} ${primary.branch}:${primary.path}`);
        for (let index = 0; index < lines.length; index += 1) {
          console.log(`PSC2_REFERENCE_TEXT ${sha}:${index + 1} ${lines[index]}`);
        }
        console.log(`PSC2_REFERENCE_TEXT_END ${sha}`);
      }
    }
    console.log(`PSC2_REFERENCE_AUDIT_SUMMARY ${JSON.stringify({
      branches: tips.length, documentOccurrences: occurrences,
      uniqueTextDocuments: shas.length, textBytes, fullDocuments,
      binaryDocumentsNotRead: binary.length,
    })}`);
    for (const record of binary) console.log(`PSC2_REFERENCE_BINARY_NOT_READ ${JSON.stringify(record)}`);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!process.argv.includes("--fetch")) throw new Error("usage: node scripts/reference-docs-audit.mjs --fetch");
  await auditReferenceDocs();
}
