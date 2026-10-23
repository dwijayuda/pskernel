# Test transport only; host effects are performed by the standalone Python adapter.
import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "host-tools"))
from typed_io import TypedIo


def reply(value):
    print(json.dumps(value), flush=True)


try:
    host = TypedIo(json.loads(sys.argv[1]))
except Exception as error:
    reply({"trap": str(error)})
    sys.exit(0)
reply({"ready": True})
for line in sys.stdin:
    command = json.loads(line)
    if command["action"] == "close":
        host.close()
        reply({"closed": True})
        break
    try:
        if command["action"] == "probeClosed":
            host.close()
        reply({"ok": host.execute(command.get("source", '{"op":"readLine"}'))})
    except Exception as error:
        reply({"trap": str(error)})
