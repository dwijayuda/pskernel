# CLI and public API ownership

| Role | Canonical source | Stable compatibility entry |
| --- | --- | --- |
| Installed developer command | proofscript-cli.mjs + cli-project.mjs | proofscript / psc / psc1 bins |
| Checked command transport | checked-command-cli.mjs | universal-cli.mjs |
| Public installed API | compiler-api.mjs | universal.mjs and existing package exports |
| Native workspace transport | native-workspace-cli.mjs | psc.js |
| Historical generated flavor | generated-entry.mjs / generated.mjs | retained explicit generated flavor |

The developer adapter owns help/init/file capture/diagnostic presentation. Checked
execution still belongs to the existing private compiler session. It cannot choose
a checker, arbitrary tools or publication authority from source metadata.
Compatibility modules only delegate; no second implementation exists.
Engine, output target and independent checker are separate selections.

Read [the CLI guide](../docs/guides/cli.md), [host invariants](../host-tools/README.md)
and [the source walkthrough](../docs/guides/compilation-walkthrough.md).
