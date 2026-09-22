import {readFileSync} from 'node:fs';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
const file=process.argv[2];
const every=Number(process.argv[3]??25000);
if(!file){console.error('usage: node scripts/replay-progress.mjs <file> [every]');process.exit(2);}
const replay=new Lean4ExportReplay();
try{
  const stats=replay.replay(readFileSync(file,'utf8'),{every,onProgress:s=>console.log(`progress line=${s.lines} decls=${s.declarations} exprs=${s.expressions} constants=${replay.env.entries().length}`)});
  console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
}catch(e){console.error(e instanceof Error?(e.stack??e.message):String(e));process.exit(1);}
