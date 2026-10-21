"""Explicit Linux capability host for checked PSC1 String dispatchers.

No Node process, guest evaluation, admission authority, or exception swallowing.
The embedding host constructs this object before importing the checked guest.
"""
import errno
import json
import os
import secrets
import stat
import sys

OPERATIONS = ("readLine", "writeLine", "readUtf8", "writeUtf8")


class PolicyError(Exception):
    pass


def deny(code):
    raise PolicyError(code)


def scalar_bytes(text, limit):
    if not isinstance(text, str):
        deny("protocolError")
    try:
        value = text.encode("utf-8", "strict")
    except UnicodeEncodeError:
        deny("invalidUtf8")
    if len(value) > limit:
        deny("tooLarge")
    return value


def decode(value):
    try:
        return value.decode("utf-8", "strict")
    except UnicodeDecodeError:
        deny("invalidUtf8")


def syscall_error(error):
    if isinstance(error, PolicyError):
        return str(error)
    if not isinstance(error, OSError):
        raise error
    codes = {
        errno.ENOENT: "notFound",
        **dict.fromkeys((errno.ELOOP, errno.ENOTDIR, errno.ENAMETOOLONG), "pathDenied"),
        **dict.fromkeys((errno.EISDIR, errno.ENXIO, errno.ENODEV), "wrongType"),
        **dict.fromkeys((errno.EACCES, errno.EPERM, errno.ENOSPC, errno.EDQUOT,
                        errno.EROFS, errno.EIO, errno.EMFILE, errno.ENFILE,
                        errno.EFBIG, errno.EPIPE, errno.EAGAIN), "ioFailure"),
    }
    if error.errno not in codes:
        raise error
    return codes[error.errno]


def write_all(fd, value):
    offset = 0
    while offset < len(value):
        count = os.write(fd, value[offset:])
        if count == 0:
            raise RuntimeError("PSC1_IO_HOST_WRITE_STALLED")
        offset += count


class TypedIo:
    def __init__(self, config):
        if sys.platform != "linux" or config.get("abi") != "psc1-python-linux-string-io/1":
            raise RuntimeError("PSC1_IO_UNSUPPORTED_ABI")
        if set(config) != {"abi", "capabilities", "required", "root",
                           "maxFileBytes", "maxLineBytes", "inputFd", "outputFd"}:
            raise RuntimeError("PSC1_IO_CONFIGURATION")
        for key in ("capabilities", "required"):
            value = config[key]
            if (not isinstance(value, list) or
                    any(not isinstance(x, str) or x not in OPERATIONS for x in value) or
                    len(set(value)) != len(value)):
                raise RuntimeError("PSC1_IO_CONFIGURATION")
        if not set(config["required"]).issubset(config["capabilities"]):
            raise RuntimeError("PSC1_IO_REQUIRED_CAPABILITY_DENIED")
        for key in ("maxFileBytes", "maxLineBytes"):
            value = config[key]
            if type(value) is not int or not 1 <= value <= 16777216:
                raise RuntimeError("PSC1_IO_CONFIGURATION")
        for key in ("inputFd", "outputFd"):
            if type(config[key]) is not int or config[key] < 0:
                raise RuntimeError("PSC1_IO_CONFIGURATION")
        if not isinstance(config["root"], str) or not os.path.isabs(config["root"]):
            raise RuntimeError("PSC1_IO_CONFIGURATION")
        self.allowed = frozenset(config["capabilities"])
        self.file_limit, self.line_limit = config["maxFileBytes"], config["maxLineBytes"]
        self.input_fd, self.output_fd = config["inputFd"], config["outputFd"]
        self.root = os.open(config["root"], os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        self.closed = False
        self.pending, self.offset, self.ended, self.overflow = b"", 0, False, False

    def close(self):
        if not self.closed:
            self.closed = True
            os.close(self.root)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

    def parent(self, relative, action):
        if (not isinstance(relative, str) or not relative or
                "\\" in relative or "\0" in relative or os.path.isabs(relative)):
            deny("pathDenied")
        try:
            if len(relative.encode("utf-8", "strict")) > 4096:
                deny("pathDenied")
        except UnicodeEncodeError:
            deny("pathDenied")
        parts = relative.split("/")
        if any(x in ("", ".", "..") for x in parts):
            deny("pathDenied")
        held, directory = [], self.root
        try:
            for part in parts[:-1]:
                directory = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                                    dir_fd=directory)
                held.append(directory)
            return action(directory, parts[-1])
        finally:
            for fd in reversed(held):
                os.close(fd)

    def read_text(self, relative):
        def read(directory, name):
            fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory)
            try:
                info = os.fstat(fd)
                if not stat.S_ISREG(info.st_mode):
                    deny("wrongType")
                if info.st_size > self.file_limit:
                    deny("tooLarge")
                value = bytearray()
                while len(value) <= self.file_limit:
                    chunk = os.read(fd, min(65536, self.file_limit + 1 - len(value)))
                    if not chunk:
                        break
                    value.extend(chunk)
                if len(value) > self.file_limit:
                    deny("tooLarge")
                return decode(value)
            finally:
                os.close(fd)
        return self.parent(relative, read)

    def write_text(self, relative, text):
        value = scalar_bytes(text, self.file_limit)
        def write(directory, name):
            try:
                info = os.stat(name, dir_fd=directory, follow_symlinks=False)
                if stat.S_ISLNK(info.st_mode):
                    deny("pathDenied")
                if not stat.S_ISREG(info.st_mode):
                    deny("wrongType")
            except FileNotFoundError:
                pass
            temporary = ".psc1-io-" + secrets.token_hex(16)
            fd, renamed = None, False
            try:
                fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                             0o600, dir_fd=directory)
                write_all(fd, value)
                os.fsync(fd)
                os.close(fd)
                fd = None
                os.replace(temporary, name, src_dir_fd=directory, dst_dir_fd=directory)
                renamed = True
            finally:
                if fd is not None:
                    os.close(fd)
                if not renamed:
                    try:
                        os.unlink(temporary, dir_fd=directory)
                    except FileNotFoundError:
                        pass
        return self.parent(relative, write)

    def read_line(self):
        if self.overflow:
            deny("tooLarge")
        value = bytearray()
        while True:
            if self.offset == len(self.pending) and not self.ended:
                self.pending = os.read(self.input_fd, 4096)
                self.offset = 0
                self.ended = not self.pending
            if self.ended:
                if len(value) > self.line_limit:
                    self.overflow = True
                    deny("tooLarge")
                return decode(value) if value else None
            byte = self.pending[self.offset]
            self.offset += 1
            if byte == 10:
                if value and value[-1] == 13:
                    value.pop()
                return decode(value)
            if len(value) == self.line_limit + 1:
                self.overflow = True
                deny("tooLarge")
            value.append(byte)
            if len(value) > self.line_limit and byte != 13:
                self.overflow = True
                deny("tooLarge")

    def execute(self, source):
        if self.closed:
            raise RuntimeError("PSC1_IO_CLOSED")
        def reply(kind, **fields):
            return json.dumps({"kind": kind, **fields}, ensure_ascii=False, separators=(",", ":"))
        if (not isinstance(source, str) or
                len(source.encode("utf-8", "replace")) > 6 * max(self.file_limit, self.line_limit) + 4096):
            return reply("error", error="tooLarge")
        try:
            request = json.loads(source, parse_constant=lambda _: deny("protocolError"))
        except (json.JSONDecodeError, PolicyError):
            return reply("error", error="protocolError")
        keys = {"readLine": {"op"}, "writeLine": {"op", "text"},
                "readUtf8": {"op", "path"}, "writeUtf8": {"op", "path", "text"}}
        if (not isinstance(request, dict) or not isinstance(request.get("op"), str) or
                request["op"] not in keys or set(request) != keys[request["op"]]):
            return reply("error", error="protocolError")
        op = request["op"]
        if op not in self.allowed:
            return reply("error", error="capabilityDenied")
        try:
            if op == "readLine":
                return reply("line", text=self.read_line())
            if op == "writeLine":
                text = request["text"]
                if not isinstance(text, str) or "\r" in text or "\n" in text:
                    deny("protocolError")
                write_all(self.output_fd, scalar_bytes(text, self.line_limit) + b"\n")
                return reply("unit")
            if op == "readUtf8":
                return reply("text", text=self.read_text(request["path"]))
            self.write_text(request["path"], request["text"])
            return reply("unit")
        except (PolicyError, OSError) as error:
            return reply("error", error=syscall_error(error))
