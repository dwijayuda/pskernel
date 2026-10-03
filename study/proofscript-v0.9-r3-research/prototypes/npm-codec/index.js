export function parseUserId(text) {
  const isDigits = text.length > 0 && [...text].every(ch => ch >= "0" && ch <= "9");
  if (!isDigits) return { tag: "error", error: { message: "invalid user id" } };
  return { tag: "ok", value: { value: BigInt(text) } };
}
