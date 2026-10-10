// Internal trusted-host transport, NOT a plugin ABI or a proof receipt format.
// Count bytes before decoding JSON, including unterminated/fragmented frames.
export const FRONTEND_PROTOCOL = 'psc0-owned-frontend/1';
export const MAX_FRAME_BYTES = 64 * 1024 * 1024;
export function receiveFrames(stream, onFrame, onFailure, maximum = MAX_FRAME_BYTES) {
  let parts = [], size = 0, failed = false;
  const fail = error => { if (!failed) { failed = true; parts = []; onFailure(error); } };
  stream.on('data', chunk => {
    if (failed) return;
    try {
      if (!Buffer.isBuffer(chunk)) throw new Error('PSC_FRONTEND_BINARY_TRANSPORT_REQUIRED');
      let offset = 0;
      while (offset < chunk.length) {
        const newline = chunk.indexOf(10, offset);
        const end = newline < 0 ? chunk.length : newline;
        const piece = chunk.subarray(offset, end);
        size += piece.length;
        if (size > maximum) throw new Error('PSC_FRONTEND_FRAME_LIMIT');
        parts.push(piece);
        if (newline < 0) break;
        if (size === 0) throw new Error('PSC_FRONTEND_EMPTY_FRAME');
        const text = new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(parts, size));
        parts = []; size = 0;
        const value = JSON.parse(text);
        if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('PSC_FRONTEND_FRAME_SHAPE');
        onFrame(value);
        if (failed) return;
        offset = newline + 1;
      }
    } catch (error) { fail(error); }
  });
  stream.on('end', () => { if (size) fail(new Error('PSC_FRONTEND_TRUNCATED_FRAME')); });
  stream.on('error', fail);
}
export function sendFrame(stream, value, onFailure, maximum = MAX_FRAME_BYTES) {
  try {
    const text = JSON.stringify(value);
    if (Buffer.byteLength(text) > maximum) throw new Error('PSC_FRONTEND_FRAME_LIMIT');
    stream.write(text + '\n', error => { if (error) onFailure(error); });
  } catch (error) { onFailure(error); }
}
