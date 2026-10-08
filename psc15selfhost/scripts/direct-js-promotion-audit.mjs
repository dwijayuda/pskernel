import { readFile } from "node:fs/promises";

const promotion=JSON.parse(await readFile(
  new URL("../contracts/promotion/DIRECT_JS_PROMOTION_V1.json",import.meta.url),
  "utf8",
));
const erasure=JSON.parse(await readFile(
  new URL("../contracts/ir/ERASURE_PRESERVATION_V0.json",import.meta.url),
  "utf8",
));
const specialization=JSON.parse(await readFile(
  new URL("../contracts/ir/SPECIALIZATION_PASS_V1.json",import.meta.url),
  "utf8",
));

if(promotion.contract!=="psc-direct-js-promotion/1") throw new Error("PSC_JS_PROMOTION_CONTRACT");
const erasureClosed=erasure.globalPreservation?.status==="proved"||erasure.globalPreservation?.status==="validated";
const specializationClosed=specialization.globalPreservation?.status==="proved"||specialization.globalPreservation?.status==="validated";
if((!erasureClosed||!specializationClosed)&&promotion.currentStatus!=="gated-not-promoted"){
  throw new Error("PSC_JS_PROMOTION_PREMATURE");
}
if(promotion.policy?.fixedPointAloneInsufficient!==true||promotion.policy?.noAutomaticPromotion!==true){
  throw new Error("PSC_JS_PROMOTION_POLICY");
}
process.stdout.write(
  "PSCV_DIRECT_JS_PROMOTION: PASS (status="+promotion.currentStatus+
  "; erasure="+String(erasure.globalPreservation?.status)+
  "; specialization="+String(specialization.globalPreservation?.status)+")\n",
);
