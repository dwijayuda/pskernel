import { parseUserId } from "@proofscript/r3-codec-prototype";

const ok = parseUserId("42");
const bad = parseUserId("x");

if (ok.tag !== "ok" || ok.value.value !== 42n) {
  throw new Error("ok case failed");
}
if (bad.tag !== "error") {
  throw new Error("bad case failed");
}

console.log(JSON.stringify({
  status: "passed",
  ok: String(ok.value.value),
  bad: bad.tag
}));
