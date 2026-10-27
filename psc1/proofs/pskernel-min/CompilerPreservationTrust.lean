import CompilerPreservation

-- Reprint on every run even when the separately built proof library is cached.
#print axioms Ps.MinKernel.CompilerPreservation.wrap_preserves
#print axioms Ps.MinKernel.CompilerPreservation.wrap_reflects
#print axioms Ps.MinKernel.CompilerPreservation.wrap_iff
#print axioms Ps.MinKernel.CompilerPreservation.two_captures_order
#print axioms Ps.MinKernel.CompilerPreservation.shadowing
#print axioms Ps.MinKernel.CompilerPreservation.curry_iff
#print axioms Ps.MinKernel.CompilerPreservation.curry_result_type_nil
#print axioms Ps.MinKernel.CompilerPreservation.curry_result_type_cons
#print axioms Ps.MinKernel.CompilerPreservation.wrap_invocation_preserves
#print axioms Ps.MinKernel.CompilerPreservation.capture_curry_preservation
#print axioms Ps.MinKernel.CompilerPreservation.mapped_binary
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary_empty_refuses
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary_overapplied_refuses
#print axioms Ps.MinKernel.CompilerPreservation.primitive_stage_preserves
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_template
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_empty_refuses
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_overapplied_refuses
#print axioms Ps.MinKernel.CompilerPreservation.emit_nat_abi
#print axioms Ps.MinKernel.CompilerPreservation.emit_bool_abi
#print axioms Ps.MinKernel.CompilerPreservation.emit_unit_abi
