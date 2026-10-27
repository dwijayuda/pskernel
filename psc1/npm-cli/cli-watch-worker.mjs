// Private checked attempt. A live-input guard may veto, never authorize, publication.
import fs from 'node:fs';
import {readInput, parseCompilation, captureProject, checkedOptions, captureIdentity, refuse} from './cli-project.mjs';
import {compile, build} from './universal.mjs';
import crypto from 'node:crypto';
const [file, expected] = process.argv.slice(2);
const bytes = readInput(file).text;
if (crypto.createHash('sha256').update(bytes).digest('hex') !== expected)
  refuse('WATCH_JOB_CHANGED', 'Private watch request changed.');
const job = JSON.parse(bytes), parsed = parseCompilation(job.args);
if (!['check', 'compile', 'build'].includes(job.command) || parsed.watch || parsed.showConfig)
  refuse('WATCH_JOB', 'Invalid private watch request.');
const captured = captureProject(parsed, job.cwd), identity = captureIdentity(captured);
if (identity !== job.captureIdentity)
  refuse('WATCH_SUPERSEDED', 'Inputs changed before compilation; waiting for the latest snapshot.');
const assertCurrent = () => {
  if (captureIdentity(captureProject(parsed, job.cwd)) !== identity)
    refuse('WATCH_SUPERSEDED', 'Inputs changed during compilation; this result was not published.');
};
const options = checkedOptions(parsed, captured);
const result = job.command === 'build' ? build(options, {beforePublish: assertCurrent}) : compile(options);
if (job.command !== 'build') assertCurrent();
console.log(JSON.stringify(job.command === 'check' ? {...result, source: undefined} : result));
