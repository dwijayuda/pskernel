export interface CheckResult {
 readonly schema: 'pskernel-min/check/1';
 readonly profile: 'psc1-min-core-regular/1';
 readonly accepted: boolean;
 readonly code: string;
 readonly delegated: false;
 readonly byteLength?: number;
 readonly declarationCount?: number;
}
export declare function checkBytes(bytes: Uint8Array): Readonly<CheckResult>;
export declare const metadata: Readonly<{
 name: string; version: string; sourceCommit: string; profile: 'psc1-min-core-regular/1';
 fullCompilerSupported: false; productionDefault: false;
 generatedCodePreservation: 'not-proved';
 limits: Readonly<Record<string,number>>;
}>;
