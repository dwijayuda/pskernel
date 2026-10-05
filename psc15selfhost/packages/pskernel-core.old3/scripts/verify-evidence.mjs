// Evidence identity checks, not a proof that the implementation is sound.
import fs from 'node:fs';import path from 'node:path';
import {root,json,sha256} from './source.mjs';
import './verify-build.mjs';
const sourceDigest=sha256(fs.readFileSync(path.join(root,'manifests/SOURCE.json')));
for(const name of ['ORACLE','SEMANTIC_ORACLE','CHECKER_ORACLE','LEVEL_DIFFERENTIAL','CHECKER_DIFFERENTIAL','POLYMORPHIC_DIFFERENTIAL','UNIT_DIFFERENTIAL','NAT_DIFFERENTIAL','LITERAL_DIFFERENTIAL','RECORD_DIFFERENTIAL','RECORD_ELIMINATION_DIFFERENTIAL','ENUM_DIFFERENTIAL','SUM_DIFFERENTIAL','TEXT_DIFFERENTIAL','ALGEBRAIC_DIFFERENTIAL']){
 const report=json(path.join(root,'manifests',name+'.json'));
 if(report.sourceManifestSha256!==sourceDigest)throw Error('STALE_EVIDENCE:'+name);
 if(report.recordsPath){
  const expected={CHECKER_DIFFERENTIAL:'dist/evidence/checker-differential-records.json',LEVEL_DIFFERENTIAL:'dist/evidence/level-differential-records.json',POLYMORPHIC_DIFFERENTIAL:'dist/evidence/polymorphic-differential-records.json',UNIT_DIFFERENTIAL:'dist/evidence/unit-differential-records.json',NAT_DIFFERENTIAL:'dist/evidence/nat-differential-records.json',LITERAL_DIFFERENTIAL:'dist/evidence/literal-differential-records.json',RECORD_DIFFERENTIAL:'dist/evidence/record-differential-records.json',RECORD_ELIMINATION_DIFFERENTIAL:'dist/evidence/record-elimination-differential-records.json',ENUM_DIFFERENTIAL:'dist/evidence/enum-differential-records.json',SUM_DIFFERENTIAL:'dist/evidence/sum-differential-records.json',TEXT_DIFFERENTIAL:'dist/evidence/text-differential-records.json',ALGEBRAIC_DIFFERENTIAL:'dist/evidence/algebraic-differential-records.json'}[name];
  if(report.recordsPath!==expected)throw Error('UNEXPECTED_RECORDS_PATH:'+name);
  const bytes=fs.readFileSync(path.join(root,expected));
  if(sha256(bytes)!==report.recordsSha256)throw Error('RECORDS_HASH_MISMATCH:'+name);
  const records=JSON.parse(bytes);
  const count=name==='CHECKER_DIFFERENTIAL'?report.comparableCases+report.knownCompletenessGaps.length:report.cases;
  if(!Array.isArray(records)||records.length!==count)throw Error('RECORDS_COUNT_MISMATCH:'+name);
 }
}
console.log('PSKERNEL_CORE_EVIDENCE_IDENTITY: PASS (bounded evidence, not soundness)');
