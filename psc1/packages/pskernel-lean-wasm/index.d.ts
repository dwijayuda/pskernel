export interface KernelIdentity {
 readonly protocol: 'pskernel-lean/1';
 readonly provider: 'lean4-cpp';
 readonly leanVersion: '4.35.0';
 readonly leanCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
 readonly profile: 'lean4.35-core';
}
export interface KernelMetadata extends KernelIdentity { readonly status: 'ok'; }
export interface KernelResult extends KernelIdentity {
 readonly accepted: boolean;
 readonly errorKind?: string;
 readonly declarationIndex?: number;
 readonly message?: string;
}
export interface KernelOptions {
 timeoutMs?: number;
 maxBuffer?: number;
}
export interface KernelHandle {
 readonly metadata: Readonly<KernelMetadata>;
 checkCanonicalAdmissions(source: string): Promise<KernelResult>;
}
export const leanKernelProviderProtocol: 'pskernel-lean/1';
export const leanKernelProviderName: 'lean4-cpp';
export const leanKernelProviderVersion: '4.35.0';
export const leanKernelProviderCommit: 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export const leanKernelProviderProfile: 'lean4.35-core';
export interface WasmKernelOptions extends KernelOptions { launcherPath?: string; nodePath?: string; }
export function checkCanonicalAdmissions(source: string, options?: WasmKernelOptions): Promise<KernelResult>;
export function createKernel(options?: WasmKernelOptions): Promise<KernelHandle>;
