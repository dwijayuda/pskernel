import Ps.DriverWasm.Compiler
import Ps.DriverWasm.SelfHostProgress

-- Direct-WebAssembly self-host composition root.
-- Host filesystem/process orchestration and the eventual byte/string ABI adapter
-- remain outside the semantic compiler closure.
