# T05 local production replay metadata proof slice

## Unqualified isolated source

This isolated preflight extends the existing paged proofs with four native statements in test/PsKernelExprV2ReplayMetadataProofs.lean. Production and the retained metadata/paged proofs must be byte-identical to qualified baseline 20224a295359abb201f56c72395690bf0bfac9fa. Integration remains that baseline. This proof source has not yet passed Lean and is not a qualified milestone.

The proof draft is12032 characters/12159 UTF-8 bytes, SHA256 bcf3abfdb5d2cee6513ff7db81000fcf8dd6accb16bf9b4761280f08acd20e46. The preflight workflow is10155 bytes, SHA256 fc03e67636ce07180d55307ffcc57f1212fe6036e9803e1eb4aab5e10ad245e5.

## Statements and assumptions

ReplayInputs connects all12 actual production node branches with a recursive expression. Compound branches require the actual child lookups and the retained five-field Corresponds relation for those child entries. The six leaf branches have no child premise. It does not assume metadata for the new result.

The first theorem constructs a corresponding new entry and proves that actual psKernelExprV2PagedReplayNode returns actual PagedPush of that entry. The second theorem additionally assumes Layout of the internal accumulator and proves the actual successful result has a fresh ID, incremented size, unchanged page capacity, valid physical layout, unchanged prior lookups and correct metadata at the new ID. A Boolean equality lemma supports the fourth theorem: an actual successful five-field metadata guard transfers correspondence from the rebuilt entry to the source entry.

Metadata correspondence alone does not imply node or decoder equality; a hash equality does not identify an expression. The first theorem separately preserves all syntactic node fields. These local assumptions and conclusions are not a public-input validation theorem.

## Qualification and continuation

Use the single push-triggered run on work/psc1-pskernel-replay-metadata-20261025. The focused gate requires29 distinct actual native reports: retained metadata8, retained paged17, new replay4, with three exact successful command statuses,12 archived source inputs and only standard permitted axioms. Pinned Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc and the25-minute budget remain unchanged. Build only on GitHub Actions Linux. Do not launch a duplicate matching-source run.

Inspect actual Lean errors first and repair proof bodies without weakening these statements or importing axioms, sorry, admit or unsafe. Verify source-bound receipts and artifact contents before recording a qualified local milestone. A later complete qualification must include these four new obligations before integration; the existing497-report source cannot qualify them by inheritance.

Whole-validator canonical metadata correspondence, executable decoder correspondence and replay-to-ArenaModel remain open. The next global bridge needs a consistent prefix semantic-witness relation, canonical size aligned with the replay index, and preservation through actual ValidateFuel. The separate empty-cache candidate and its incomplete microbenchmark do not belong to this proof source. A is historically scoped qualified; B OPEN, C FAIL, D OPEN.
