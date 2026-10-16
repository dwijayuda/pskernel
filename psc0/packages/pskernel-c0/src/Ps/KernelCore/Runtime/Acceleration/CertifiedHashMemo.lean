import Ps.KernelCore.Runtime.Acceleration.Cache

/-!
Compatibility module retaining the public import path for source-verified
exact hash memo definitions. The complete memo, the independent original
hash, and the Lean-checked csimp rewrite now live in Cache.lean so every
native checker cache consumer receives the same qualified replacement.
-/
