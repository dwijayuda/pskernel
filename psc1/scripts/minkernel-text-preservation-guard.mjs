import fs from 'node:fs';
import assert from 'node:assert/strict';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const text=fs.readFileSync('dist/pskernel-min/text-preservation/proof.log','utf8');
const names=['append_utf8','empty_utf8'];
const reports=names.map(name=>{
 const full='Ps.MinKernel.TextComposition.'+name;
 const rows=text.split('\n').filter(line=>line.includes("'"+full+"'"));
 assert.equal(rows.length,1,'missing/duplicate report '+full);
 assert.ok(rows[0].includes('does not depend on any axioms')||rows[0].endsWith('depends on axioms: [propext]'),rows[0]);
 return {name:full,report:rows[0]};
});
assert.doesNotMatch(text,/sorryAx|declaration uses.*sorry/);
fs.writeFileSync('dist/pskernel-min/text-preservation/proof-reports.json',JSON.stringify({schema:'psc1-r6-text-trust/1',reports},null,2)+'\n');
console.log('PSC1_R6_TEXT_TRUST_PASS '+reports.length);
