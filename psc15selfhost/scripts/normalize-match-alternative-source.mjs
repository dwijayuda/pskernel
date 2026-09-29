import fs from "node:fs";

const path = new URL("../packages/elab/src/Ps/Elab/Term.lean", import.meta.url);
const source = fs.readFileSync(path, "utf8");
const before = `def psElabMatchAlternativeFind
    (name : PsName) :
    List PsElabMatchAlternative -> Option PsElabMatchAlternative
  | [] => Option.none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        Option.some alternative
      else
        psElabMatchAlternativeFind name rest`;
const after = `def psElabMatchAlternativeFind
    (name : PsName)
    (alternatives : List PsElabMatchAlternative) :
    Option PsElabMatchAlternative :=
  match alternatives with
  | [] => Option.none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        Option.some alternative
      else
        psElabMatchAlternativeFind name rest`;
if (!source.includes(before)) throw new Error("expected psElabMatchAlternativeFind source shape not found");
const next = source.replace(before, after);
if (next === source) throw new Error("normalization made no change");
fs.writeFileSync(path, next);
console.log("PSC2_MATCH_ALTERNATIVE_SOURCE_NORMALIZED");
