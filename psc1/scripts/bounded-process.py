# Compatibility command; canonical bounded supervisor lives with host runtime policy.
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parent.parent / "host-tools/process/bounded-process.py"), run_name="__main__")
