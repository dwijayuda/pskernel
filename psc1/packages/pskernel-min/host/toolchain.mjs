// Research boundary. The production official provider set is unchanged.
import { createIndependentKernelToolchain } from '../../../host-tools/kernel-toolchain.mjs';

export const checkerModes = Object.freeze(['min', 'lean-wasm', 'lean-native', 'dual']);
export const defaultCheckerMode = 'lean-wasm';

/** Only the trusted host supplies options. Untrusted admission bytes cannot
 * select this mode or nominate an executable. The standalone typed fragment is
 * available through the PSC1-generated Check module. Its canonical PSC1 bridge
 * is not proved/qualified, so neither min nor dual can admit a canonical graph.
 */
export async function createResearchKernelToolchain({ mode = defaultCheckerMode, officialRoot } = {}) {
  if (!checkerModes.includes(mode)) throw new Error('PSC1_MIN_UNKNOWN_CHECKER_MODE');
  if (mode === 'min' || mode === 'dual') return Object.freeze({
    metadata: Object.freeze({ mode, profile: 'psc1-min-stlc/1', canonicalBridgeQualified: false }),
    async checkCanonicalAdmissions(source) {
      if (typeof source !== 'string') throw new TypeError('Expected canonical admission bytes');
      return Object.freeze({ accepted: false, mode, errorKind: 'unsupported-profile',
        code: 'PSC1_MIN_CANONICAL_BRIDGE_UNPROVED', delegated: false });
    },
  });
  const official = await createIndependentKernelToolchain({ root: officialRoot,
    provider: mode === 'lean-native' ? 'native' : 'wasm' });
  return Object.freeze({ metadata: Object.freeze({ ...official.metadata, mode }),
    checkCanonicalAdmissions: source => official.checkCanonicalAdmissions(source) });
}
