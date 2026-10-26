# Development automation

New controllers are grouped by responsibility:
- ci/: tracked-source navigation, structure/correspondence and dependency selection.
- packaging/: assembly of installable candidates; cli.mjs is the host-only assembler.
- qualification/: manual/release navigation and existing exact-evidence controllers.
- diagnostics/: profiling/investigation navigation.
Production process policy/validators/runners live in host-tools, not here.
Existing top-level paths remain compatibility commands or retained historical
controllers; do not duplicate their implementations.

New CLI behavioral tests live in test/host and test/installed. Existing tests and
historical source-shape guards remain in place with all assertions retained.
Migration is by responsibility, not a mass rename of every historical controller.
Use the generated map to distinguish commands, reusable runtime and evidence.
