# Static canonical codec schemas

The current TypeScript actual G2 late profile reaches codec encoding, JSON quote
and text-builder/generator calls. Canonical Name/Level/Expr schemas have fixed
keys and tags. Replace their runtime key/tag quoting and temporary field-list
construction with direct immutable String.Internal.append expressions, retaining
the exact original association, field order, dynamic quoting and recursive
Except evaluation/refusal order. Keep declaration schemas and public APIs intact.
All-input equalities against retained original Name/Level/List/Expr encoders and
closed static-schema/quote reductions must pass with official Lean before source
audits or generated workloads. No new serializer protocol, host substitution,
verification shortcut, cache expansion or increased runtime/fuel/resource limits.
