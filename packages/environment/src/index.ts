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

export function replayLeanEnvironment(
  text:string,
  expectedLeanVersion=PROOFSCRIPT_LEAN_VERSION,
):ReplayedLeanEnvironment {
  const replay=new Lean4ExportReplay(
    new Environment(),
    {expectedLeanVersion},
  );
  const stats=replay.replay(text);
  return {environment:replay.env,stats};
}
