// Shared acceptance consumers; no compiler or IO implementation.
import assert from 'node:assert/strict';
import path from 'node:path';
import { buildTarget, observeArtifact } from '../host-tools/generated-target-tools.mjs';
const js = "const value=m.run('λ🙂',input=>'ok:'+input);let trapped=false;const token=new Error('trap');try{m.run('x',()=>{throw token;});}catch(error){trapped=error===token;}if(value!=='ok:λ🙂'||!trapped)throw Error('IO callback');console.log(JSON.stringify({value,trapped}));\n";
const rust = 'let value=run(String::from("λ🙂"),std::rc::Rc::new(|input:String|format!("ok:{}",input)));' +
  'let trapped=std::panic::catch_unwind(std::panic::AssertUnwindSafe(||run(String::from("x"),std::rc::Rc::new(|_:String|panic!("explicit host trap"))))).is_err();' +
  'assert_eq!(value,"ok:λ🙂");assert!(trapped);println!("{{\\"value\\":\\"{}\\",\\"trapped\\":true}}",value);';
export function consumeIoCandidates(rows, destination, retain = () => {}) {
  const records = [];
  for (const row of rows) {
    if (row.refused) { records.push(row); retain(row); continue; }
    const grammar = row.grammar || row.kind;
    const directory = path.join(destination, row.engine, grammar, row.target);
    const artifact = buildTarget({ target: row.target, source: row.source, directory,
      publicNames: row.publicNames, consumer: row.target === 'rust' ? rust : js });
    const actual = observeArtifact(artifact);
    assert.deepEqual(actual.observation, { value: 'ok:λ🙂', trapped: true });
    records.push({ engine: row.engine, grammar, target: row.target,
      admissionsSha256: row.admissionsSha256, kernels: row.kernels, runtime: 'executed',
      observation: actual.observation, execution: actual.event });
    retain(records.at(-1));
    console.log('PSC1_IO_CANDIDATE_CONSUMER: ' + JSON.stringify(records.at(-1)));
  }
  return records;
}
