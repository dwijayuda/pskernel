import { lstat, open } from 'node:fs/promises';
import { constants } from 'node:fs';

/** Bounded regular-file read. Callers own path selection and trust policy. */
export async function readObservedFileBytes(file, limit) {
  const fail = code => { throw new Error('PSC_OBSERVED_INPUT_' + code); };
  if (!Number.isSafeInteger(limit) || limit < 0) fail('BUDGET');
  const before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink()) fail('FILE_SHAPE');
  if (before.size > limit) fail('RESOURCE_EXHAUSTED');
  const handle = await open(file, constants.O_RDONLY | (process.platform === 'win32' ? 0 : constants.O_NOFOLLOW));
  try {
    const info = await handle.stat();
    if (!info.isFile() || info.size > limit) fail('RESOURCE_EXHAUSTED');
    const bytes = Buffer.alloc(info.size);
    let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (!result.bytesRead) fail('CHANGED_DURING_READ');
      offset += result.bytesRead;
    }
    if ((await handle.read(Buffer.alloc(1), 0, 1, offset)).bytesRead) fail('CHANGED_DURING_READ');
    return bytes;
  } finally { await handle.close(); }
}
