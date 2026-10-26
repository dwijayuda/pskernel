# Package assembly

cli.mjs assembles the host-only candidate from an exact qualified artifact,
retains frozen compiler/kernel/provider payloads, applies finite reviewed host
relocations, and records new inventories. scripts/cli-package.mjs is a compatibility
command. The complete source assembler remains scripts/slim-universal-package.mjs.
