// Deliberately narrow test corpus, not a production declaration adapter.
export const workloads = ['beta_whnf_16', 'beta_defeq_16', 'checked_application_8'];
export const iterations = 1000;
export const warmup = 100;
export const requestCases = [
  { count: 1, bad: false }, { count: 128, bad: false }, { count: 4, bad: true },
];
export function admissionRequest(count, bad) {
  if (![1, 4, 128].includes(count) || typeof bad !== 'boolean') throw Error('Invalid corpus request');
  const name = text => ({ k: 's', p: { k: 'a' }, v: text });
  return JSON.stringify({
    protocol: 'pskernel-lean/1', format: 'proofscript-checked-admissions', version: 2,
    admissions: Array.from({ length: count }, (_, i) => ({
      kind: 'constant', declaration: {
        k: 'definition', n: { k: 'n', p: name('CrossAdmission'), v: String(i) },
        lp: [], s: 'safe', h: { k: 'regular', h: '1' },
        t: { k: 'const', n: name('Nat'), ls: [] },
        v: bad && i === count - 1 ? { k: 'sort', l: { k: 'z' } }
          : { k: 'nat', v: String(9007199254740993n + BigInt(i)) },
      },
    })),
  });
}
