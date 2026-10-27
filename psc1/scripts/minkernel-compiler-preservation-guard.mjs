import fs from 'node:fs';
import assert from 'node:assert/strict';
assert.equal(process.platform,'linux');
assert.equal(process.env.GITHUB_ACTIONS,'true');
const text=fs.readFileSync('dist/pskernel-min/compiler-preservation/proof.log','utf8');
const names=["wrap_preserves","wrap_reflects","wrap_iff","two_captures_order","shadowing","curry_iff","curry_result_type_nil","curry_result_type_cons","capture_curry_preservation","mapped_binary","erase_binary","erase_binary_empty_refuses","erase_binary_overapplied_refuses","primitive_stage_preserves","emit_binary_template","emit_binary_empty_refuses","emit_binary_overapplied_refuses","emit_nat_abi","emit_bool_abi","emit_unit_abi"];
const reports=[];
for(const name of names){
 const full='Ps.MinKernel.CompilerPreservation.'+name;
 const lines=text.split('\n').filter(line=>line.includes("'"+full+"'"));
 assert.equal(lines.length,1,'missing or duplicate R5 theorem report '+full);
 assert.ok(lines[0].includes('does not depend on any axioms')||lines[0].includes('depends on axioms: [propext]'),lines[0]);
 reports.push({name:full,report:lines[0]});
}
assert.doesNotMatch(text,/sorryAx|declaration uses.*sorry/);
fs.writeFileSync('dist/pskernel-min/compiler-preservation/proof-reports.json',JSON.stringify({schema:'psc1-r5-trust-reports/1',reports},null,2)+'\n');
console.log('PSC1_R5_TRUST_REPORTS_PASS '+reports.length);
