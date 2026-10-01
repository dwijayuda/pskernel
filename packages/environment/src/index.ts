import {
  Environment,
  Lean4ExportReplay,
  type ReplayStats,
} from 'lean-ts-kernel';

export const PROOFSCRIPT_LEAN_VERSION='4.34.0';

export interface ReplayedLeanEnvironment {
  readonly environment:Environment;
  readonly stats:ReplayStats;
}

function addReplayStats(a:ReplayStats,b:ReplayStats):ReplayStats {
  return {
    lines:a.lines+b.lines,
    names:a.names+b.names,
    levels:a.levels+b.levels,
    expressions:a.expressions+b.expressions,
    declarations:a.declarations+b.declarations,
  };
}

const emptyReplayStats:ReplayStats={
  lines:0,
  names:0,
  levels:0,
  expressions:0,
  declarations:0,
};

function isReplayContainerMarker(line:string):boolean {
  return line.startsWith('{"environment":')
    ||line.startsWith('{"batch":');
}

export function replayLeanEnvironmentInto(
  baseEnvironment:Environment,
  text:string,
  expectedLeanVersion=PROOFSCRIPT_LEAN_VERSION,
):ReplayedLeanEnvironment {
  const environment=baseEnvironment.clone();
  let replay:Lean4ExportReplay|undefined;
  let stats=emptyReplayStats;

  const finishSegment=():void=>{
    if(replay===undefined)return;
    stats=addReplayStats(stats,replay.finish());
    replay=undefined;
  };

  let start=0;
  while(start<=text.length){
    const end=text.indexOf('\n',start);
    const line=end<0?text.slice(start):text.slice(start,end);
    const trimmed=line.trim();
    if(trimmed!==''){
      if(trimmed.startsWith('{"segment":')){
        finishSegment();
        replay=new Lean4ExportReplay(
          environment,
          {expectedLeanVersion},
        );
      }else if(!isReplayContainerMarker(trimmed)){
        replay??=new Lean4ExportReplay(
          environment,
          {expectedLeanVersion},
        );
        replay.replayLine(line);
      }
    }
    if(end<0)break;
    start=end+1;
  }
  finishSegment();
  return {environment,stats};
}

export function replayLeanEnvironment(
  text:string,
  expectedLeanVersion=PROOFSCRIPT_LEAN_VERSION,
):ReplayedLeanEnvironment {
  return replayLeanEnvironmentInto(
    new Environment(),
    text,
    expectedLeanVersion,
  );
}
