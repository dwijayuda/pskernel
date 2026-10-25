export type KernelProvider = 'wasm' | 'native' | 'both';
export interface KernelAdmissionResult {
 readonly protocol: 'pskernel-lean/1'; readonly provider: 'lean4-cpp';
 readonly leanVersion: '4.35.0'; readonly leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
 readonly profile: 'lean4.35-core'; readonly accepted: boolean; readonly errorKind?: string;
}
export interface KernelToolchainResult {
 readonly schema: 'psc1-independent-kernel-toolchain-result/1'; readonly provider: KernelProvider;
 readonly accepted: boolean; readonly agreement: boolean; readonly admissionsSha256: string;
 readonly leanVersion: '4.35.0'; readonly leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
 readonly results: Readonly<Partial<Record<'wasm'|'native', KernelAdmissionResult>>>;
 readonly scope: string;
}
export interface KernelToolchain {
 readonly metadata: Readonly<{schema:'psc1-independent-kernel-toolchain/1';provider:KernelProvider;leanVersion:'4.35.0';leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';canonicalAdmissionsVersion:2;wasmMemoryModel:'linear'}>;
 checkCanonicalAdmissions(source: string): Promise<KernelToolchainResult>;
}
export interface KernelFilePin { readonly path: string; readonly bytes: number; readonly sha256: string; }
export interface KernelDistribution {
 readonly schema: 'psc1-installed-independent-kernels/1'; readonly leanVersion: '4.35.0';
 readonly leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'; readonly canonicalAdmissionsVersion: 2;
 readonly defaultProvider: 'wasm'; readonly sourceClosureDigest: string;
 readonly hostFiles: readonly KernelFilePin[];
 readonly providers: Readonly<Record<'native'|'wasm',{readonly package:string;readonly version:'4.35.0';readonly entry:string;readonly files:readonly KernelFilePin[]}>>;
}
export function loadKernelDistribution(root: string): KernelDistribution;
export function createIndependentKernelToolchain(options:{root:string;provider?:KernelProvider}):Promise<KernelToolchain>;
