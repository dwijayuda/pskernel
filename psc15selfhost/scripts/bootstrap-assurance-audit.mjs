import { readFile } from "node:fs/promises";

const data=JSON.parse(await readFile(
  new URL("../contracts/bootstrap/BOOTSTRAP_ASSURANCE_V1.json",import.meta.url),
  "utf8",
));
if(data.contract!=="psc-bootstrap-assurance/1") throw new Error("PSC_BOOTSTRAP_ASSURANCE_CONTRACT");
const byId=new Map((data.levels??[]).map(item=>[item.id,item]));
for(let index=0;index<=10;index+=1){
  const id="B"+String(index);
  if(!byId.has(id)) throw new Error("PSC_BOOTSTRAP_ASSURANCE_LEVEL: "+id);
}
if(byId.get("B9").status==="complete"||byId.get("B10").status==="complete"){
  throw new Error("PSC_BOOTSTRAP_ASSURANCE_OVERCLAIM");
}
for(const rule of ["fixed-point-is-not-compiler-correctness","reproducibility-is-not-ddc","verified-source-is-not-verified-executable"]){
  if(!data.antiConflation.includes(rule)) throw new Error("PSC_BOOTSTRAP_ASSURANCE_RULE: "+rule);
}
process.stdout.write("PSCV_BOOTSTRAP_ASSURANCE: PASS (B0-B10 claims separated; B9/B10 not overclaimed)\n");
