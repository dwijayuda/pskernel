import { readSources } from "../packages/pskernel-core.old3/scripts/source.mjs";
const { manifest } = readSources();
console.log("PSKERNEL_CORE_SOURCE: PASS (" + manifest.files.length + " pinned owned modules)");
