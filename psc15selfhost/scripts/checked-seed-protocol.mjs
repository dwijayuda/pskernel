export const defaultCheckedSeedLimits = Object.freeze({
  sourceBytes: 128 * 1024 * 1024, sourceCount: 4096, snapshotBytes: 256 * 1024 * 1024, frameBytes: 128 * 1024 * 1024,
  stdoutBytes: 256 * 1024 * 1024, stderrBytes: 4 * 1024 * 1024,
  admissionsBytes: 64 * 1024 * 1024, generatedBytes: 256 * 1024 * 1024,
  terminationGraceMs: 2000,
});

export function checkedSeedLimits(overrides = {}) {
  const limits = Object.freeze({ ...defaultCheckedSeedLimits, ...overrides });
  if (Object.keys(overrides).some(key => !Object.hasOwn(defaultCheckedSeedLimits, key)) ||
      Object.values(limits).some(value => !Number.isSafeInteger(value) || value < 0) ||
      limits.terminationGraceMs > 2147483647) throw new Error('PSC2_CHECKED_SEED_BUDGET_POLICY');
  return limits;
}

export function checkedSeedExhausted(resource, configured, observed) {
  return Object.assign(new Error('PSC2_CHECKED_SEED_RESOURCE_EXHAUSTED: ' + resource),
    { kind: 'resourceExhausted', resource, configured, ...(observed === undefined ? {} : { observed }) });
}

export function checkSeedBytes(value, resource, limits) {
  const size = Buffer.byteLength(value);
  if (size > limits[resource]) throw checkedSeedExhausted(resource, limits[resource], size);
  return size;
}

/** Bounded byte framing before decoding/parsing; no readline accumulation.
 * Legacy sessions permit two frames. An explicitly selected direct declaration
 * session permits one additional writer response; no unbounded frame mode.
 */
export async function* checkedSeedFrames(stream, limits, observation, maxFrames = 2) {
  if (maxFrames !== 2 && maxFrames !== 3) throw new Error('PSC2_CHECKED_SEED_FRAME_POLICY');
  let parts = [], size = 0;
  function append(chunk) {
    size += chunk.length;
    if (size > limits.frameBytes) throw checkedSeedExhausted('frameBytes', limits.frameBytes, size);
    if (chunk.length) parts.push(chunk);
  }
  function decode() {
    observation.frames++;
    if (observation.frames > maxFrames) throw new Error('PSC2_CHECKED_SEED_SESSION_EXTRA_FRAME');
    let bytes = Buffer.concat(parts, size);
    observation.largestFrameBytes = Math.max(observation.largestFrameBytes, size);
    parts = []; size = 0;
    if (bytes.at(-1) === 13) bytes = bytes.subarray(0, -1);
    try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
    catch (cause) { throw new Error('PSC2_CHECKED_SEED_SESSION_JSON', { cause }); }
  }
  for await (const chunk of stream) {
    if (!(chunk instanceof Uint8Array)) throw new Error('PSC2_CHECKED_SEED_SESSION_STREAM');
    observation.stdoutBytes += chunk.length;
    if (observation.stdoutBytes > limits.stdoutBytes)
      throw checkedSeedExhausted('stdoutBytes', limits.stdoutBytes, observation.stdoutBytes);
    let start = 0, end;
    while ((end = chunk.indexOf(10, start)) !== -1) {
      append(chunk.subarray(start, end));
      yield decode();
      start = end + 1;
    }
    append(chunk.subarray(start));
  }
  if (size) yield decode();
}
