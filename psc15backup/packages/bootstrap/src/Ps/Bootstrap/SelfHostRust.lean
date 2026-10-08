import Ps.DriverRust.Compiler

-- Direct-Rust self-host composition root.
-- Host filesystem/process orchestration and rustc/Cargo remain outside the
-- semantic compiler closure; this root owns source-to-Rust compiler semantics.
