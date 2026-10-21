"""Same actual Linux policy matrix for each standalone adapter process."""
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
COMMAND = json.loads(os.environ.get("PSC1_STANDALONE_IO_COMMAND",
    json.dumps([sys.executable, str(ROOT / "scripts/standalone-io-server.py")])))
ABI = os.environ.get("PSC1_STANDALONE_IO_ABI", "psc1-python-linux-string-io/1")
checks = []


class Host:
    def __init__(self, config):
        self.process = subprocess.Popen(COMMAND + [json.dumps(config)], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            pass_fds=(config["inputFd"], config["outputFd"]))
        result = self.receive()
        if "trap" in result:
            self.process.wait(timeout=5)
            raise RuntimeError(result["trap"])
        assert result == {"ready": True}, result

    def receive(self):
        assert select.select([self.process.stdout], [], [], 10)[0], "adapter timed out"
        text = self.process.stdout.readline()
        assert text, self.process.stderr.read()
        return json.loads(text)

    def command(self, value):
        self.process.stdin.write(json.dumps(value) + "\n")
        self.process.stdin.flush()
        return self.receive()

    def request(self, op, **fields):
        result = self.command({"action": "execute", "source": json.dumps({"op": op, **fields})})
        assert "ok" in result, result
        return json.loads(result["ok"])

    def close(self):
        result = self.command({"action": "close"})
        assert result == {"closed": True}, result
        self.process.stdin.close()
        assert self.process.wait(timeout=5) == 0, self.process.stderr.read()


def expect_error(value, code):
    assert value == {"kind": "error", "error": code}, value


def reject(config, message):
    try:
        unexpected = Host(config)
    except RuntimeError as error:
        assert message in str(error), str(error)
    else:
        unexpected.close()
        raise AssertionError("configuration unexpectedly accepted")


def check(name):
    checks.append(name)


with tempfile.TemporaryDirectory(prefix="psc1-standalone-io-") as temporary:
    work = Path(temporary)
    root = work / "root"
    root.mkdir()
    (work / "input").write_bytes("😀\r\n\nlast".encode())
    with (work / "input").open("rb") as incoming, (work / "output").open("wb") as outgoing:
        config = dict(abi=ABI, capabilities=["readLine", "writeLine", "readUtf8", "writeUtf8"],
            required=[], root=str(root), maxFileBytes=32, maxLineBytes=16,
            inputFd=incoming.fileno(), outputFd=outgoing.fileno())
        reject({**config, "abi": "bad", "root": "/missing"}, "UNSUPPORTED_ABI")
        if ABI == "psc1-php-linux-ffi-string-io/1":
            disabled = [arg.replace("ffi.enable=1", "ffi.enable=0") for arg in COMMAND]
            result = subprocess.run(disabled + [json.dumps({**config, "root": "/missing"})],
                capture_output=True, text=True, timeout=10,
                pass_fds=(config["inputFd"], config["outputFd"]))
            assert result.returncode == 0, result.stderr
            assert "UNSUPPORTED_ABI" in json.loads(result.stdout)["trap"], result.stdout
        check("unsupported ABI refuses before root access")
        reject({**config, "capabilities": [], "required": ["writeUtf8"], "root": "/missing"},
               "REQUIRED_CAPABILITY_DENIED")
        check("required capability preflight")
        for limit in (0, -1, 1.5, 16777217):
            reject({**config, "maxFileBytes": limit}, "CONFIGURATION")
        reject({**config, "unexpected": True}, "CONFIGURATION")
        check("finite exact configuration")
        host = Host(config)
        for text in ("😀", "", "last", None, None):
            assert host.request("readLine") == {"kind": "line", "text": text}
        check("Unicode CRLF empty unterminated EOF")
        for text in ("😀", ""):
            assert host.request("writeLine", text=text) == {"kind": "unit"}
        assert (work / "output").read_bytes() == "😀\n\n".encode()
        for text in ("bad\rline", "bad\nline"):
            expect_error(host.request("writeLine", text=text), "protocolError")
        check("writeLine exactly one LF")
        assert host.request("writeUtf8", path="data", text="\ufeff😀\n") == {"kind": "unit"}
        assert host.request("readUtf8", path="data") == {"kind": "text", "text": "\ufeff😀\n"}
        (root / "nested").mkdir()
        assert host.request("writeUtf8", path="nested/empty", text="") == {"kind": "unit"}
        assert host.request("readUtf8", path="nested/empty") == {"kind": "text", "text": ""}
        check("bounded UTF8 file BOM and empty nested file")
        (root / "data").write_text("previous")
        expect_error(host.request("writeUtf8", path="data", text="😀"*9), "tooLarge")
        assert (root / "data").read_text() == "previous"
        assert host.request("writeUtf8", path="data", text="😀"*8) == {"kind": "unit"}
        (root / "large").write_bytes(b"x"*33)
        expect_error(host.request("readUtf8", path="large"), "tooLarge")
        check("Unicode byte bounds preserve previous file")
        (root / "invalid").write_bytes(b"\xc0\xaf")
        expect_error(host.request("readUtf8", path="invalid"), "invalidUtf8")
        expect_error(host.request("writeUtf8", path="data", text="\ud800"), "invalidUtf8")
        check("invalid UTF8 and surrogate refusal")
        assert os.getuid() != 0
        (root / "protected").mkdir()
        (root / "protected/value").write_text("previous")
        (root / "protected").chmod(0o500)
        try:
            expect_error(host.request("writeUtf8", path="protected/value", text="changed"), "ioFailure")
            assert (root / "protected/value").read_text() == "previous"
        finally:
            (root / "protected").chmod(0o700)
        check("actual permission refusal preserves file")
        expect_error(host.request("readUtf8", path="missing"), "notFound")
        expect_error(host.request("readUtf8", path="nested"), "wrongType")
        expect_error(host.request("writeUtf8", path="nested", text="x"), "wrongType")
        check("missing and nonregular files")
        for relative in ("", "../escape", "nested/../escape", "/tmp/escape",
                         "./data", "nested//x", "data/", "a\\b", "bad\0name"):
            expect_error(host.request("readUtf8", path=relative), "pathDenied")
            expect_error(host.request("writeUtf8", path=relative, text="x"), "pathDenied")
        check("traversal absolute empty and NUL paths")
        (work / "outside").write_text("secret")
        (root / "link").symlink_to(work / "outside")
        (root / "parent").symlink_to(work, target_is_directory=True)
        for relative in ("link", "parent/outside"):
            expect_error(host.request("readUtf8", path=relative), "pathDenied")
            expect_error(host.request("writeUtf8", path=relative, text="changed"), "pathDenied")
        assert (work / "outside").read_text() == "secret"
        check("leaf and parent symlinks preserve outside content")
        os.mkfifo(root / "fifo")
        expect_error(host.request("readUtf8", path="fifo"), "wrongType")
        expect_error(host.request("writeUtf8", path="fifo", text="x"), "wrongType")
        check("FIFO refusal without blocking")
        for source in ("{", "null", "[]", '{"op":"unknown"}', '{"op":"readLine","extra":1}'):
            result = host.command({"action": "execute", "source": source})
            expect_error(json.loads(result["ok"]), "protocolError")
        for value in (None, False, 42, [], {}):
            expect_error(host.request("readUtf8", path=value), "pathDenied")
            expect_error(host.request("writeUtf8", path=value, text="x"), "pathDenied")
            expect_error(host.request("writeLine", text=value), "protocolError")
            expect_error(host.request("writeUtf8", path="data", text=value), "protocolError")
        expect_error(host.request("readUtf8", path="\ud800"), "pathDenied")
        check("malformed extra and unknown requests")
        denied = Host({**config, "capabilities": []})
        expect_error(denied.request("readUtf8", path="data"), "capabilityDenied")
        denied.close()
        check("optional capability denial is typed")
        result = host.command({"action": "probeClosed"})
        assert "PSC1_IO_CLOSED" in result["trap"], result
        host.close()
        check("closed host error escapes")
        for label, value, limit, error in (
                ("invalid line", b"\xff\n", 2, "invalidUtf8"),
                ("oversize CR EOF", b"ab\r", 2, "tooLarge"),
                ("oversize line", b"abc\n", 2, "tooLarge")):
            (work / "line").write_bytes(value)
            with (work / "line").open("rb") as stream:
                scoped = Host({**config, "inputFd": stream.fileno(), "maxLineBytes": limit})
                expect_error(scoped.request("readLine"), error)
                if error == "tooLarge":
                    expect_error(scoped.request("readLine"), error)
                scoped.close()
            check(label)
        assert not list(root.rglob(".psc1-io-*"))
        check("atomic temporary cleanup")
receipt = dict(schema="psc1-standalone-io-policy/1", abi=ABI, passed=True, checks=checks,
    testedCommit=os.environ.get("GITHUB_SHA"), branchHeadCommit=os.environ.get("PSC1_HEAD_SHA"))
evidence = ROOT / "dist/scoped-correctness/typed-io-standalone"
evidence.mkdir(parents=True, exist_ok=True)
(evidence / (ABI.split("-")[1] + "-policy.json")).write_text(json.dumps(receipt, indent=2) + "\n")
print("PSC1_STANDALONE_IO_POLICY: " + json.dumps(receipt))
