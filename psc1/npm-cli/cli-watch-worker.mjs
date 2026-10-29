// One-shot fallback keeps its bounded compiler subprocess on other hosts/runtimes.
import { runWatchJob } from './cli-watch-job.mjs';
try {
  console.log(JSON.stringify(await runWatchJob(...process.argv.slice(2))));
} catch (error) {
  console.error((error.cliCode ? error.cliCode + ': ' : '') + String(error?.message || error));
  process.exitCode = 1;
}
