// Private sequential worker; no network listener, plugin loading or acceptance cache.
import { runWatchJob } from './cli-watch-job.mjs';
let busy = false;
process.on('message', async (packet) => {
  if (
    busy ||
    !packet ||
    Object.keys(packet).sort().join(',') !== 'args,id' ||
    !Number.isSafeInteger(packet.id) ||
    !Array.isArray(packet.args) ||
    packet.args.length !== 2 ||
    packet.args.some((x) => typeof x !== 'string') ||
    Buffer.byteLength(JSON.stringify(packet)) > 8192
  ) {
    process.exitCode = 1;
    process.disconnect();
    return;
  }
  busy = true;
  try {
    const result = await runWatchJob(...packet.args, { warm: true });
    process.stdout.write(JSON.stringify(result) + '\n', () => {
      busy = false;
      process.send({ id: packet.id, code: 0 });
    });
  } catch (error) {
    process.stderr.write(
      (error.cliCode ? error.cliCode + ': ' : '') + String(error?.message || error) + '\n',
      () => {
        busy = false;
        process.send({ id: packet.id, code: 1 });
      },
    );
  }
});
process.on('disconnect', () => process.exit());
