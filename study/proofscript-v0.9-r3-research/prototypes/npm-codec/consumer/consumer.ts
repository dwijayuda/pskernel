import { parseUserId } from "@proofscript/r3-codec-prototype";

const result = parseUserId("42");
if (result.tag === "ok") {
  const id: bigint = result.value.value;
  console.log(id);
} else {
  console.log(result.error.message);
}
