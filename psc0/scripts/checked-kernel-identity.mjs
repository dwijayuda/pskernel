export const coreCheckedIdentity = Object.freeze({
  protocol: 'pskernel-core/1', provider: 'pskernel-core-native', leanVersion: '4.34.0',
  leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b', profile: 'lean4.34-core',
});

export const leanCheckedIdentity = Object.freeze({
  protocol: 'pskernel-lean/1', provider: 'lean4-cpp', leanVersion: '4.34.0',
  leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b', profile: 'lean4.34-core',
});

export function checkedKernelIdentity(selector) {
  if (selector === 'pskernel-core') return coreCheckedIdentity;
  if (selector === 'lean434-wasm' || selector === 'lean434') return leanCheckedIdentity;
  throw new Error('PSC2_CHECKED_KERNEL_UNSUPPORTED: ' + selector);
}
