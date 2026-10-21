<?php
declare(strict_types=1);

/** Explicit opt-in Linux CLI/glibc FFI profile. No FFI is exposed to source code. */
final class Psc1IoPolicy extends RuntimeException {}
final class Psc1TypedIo {
    private const OPS = ['readLine','writeLine','readUtf8','writeUtf8'];
    private const DIRECTORY = 00200000, NOFOLLOW = 00400000, NONBLOCK = 00004000;
    private FFI $lib;
    private int $root;
    private array $allowed;
    private int $fileLimit, $lineLimit, $input, $output;
    private bool $closed = false, $ended = false, $overflow = false;
    private string $pending = '';
    private int $offset = 0;

    private static function deny(string $code): never { throw new Psc1IoPolicy($code); }
    private static function scalar(mixed $text, int $limit): string {
        if (!is_string($text)) self::deny('protocolError');
        if (preg_match('//u', $text) !== 1) self::deny('invalidUtf8');
        if (strlen($text) > $limit) self::deny('tooLarge');
        return $text;
    }
    private static function decode(string $bytes): string {
        if (preg_match('//u', $bytes) !== 1) self::deny('invalidUtf8');
        return $bytes;
    }
    private static function exact(array $value, array $keys): bool {
        $actual = array_keys($value); sort($actual); sort($keys);
        return $actual === $keys;
    }
    public function __construct(array $config) {
        if (PHP_OS_FAMILY !== 'Linux' || PHP_SAPI !== 'cli' || PHP_INT_SIZE !== 8 ||
            php_uname('m') !== 'x86_64' ||
            ($config['abi'] ?? null) !== 'psc1-php-linux-ffi-string-io/1' ||
            !extension_loaded('FFI')) throw new RuntimeException('PSC1_IO_UNSUPPORTED_ABI');
        if (!self::exact($config, ['abi','capabilities','required','root','maxFileBytes','maxLineBytes','inputFd','outputFd']))
            throw new RuntimeException('PSC1_IO_CONFIGURATION');
        foreach (['capabilities','required'] as $key) {
            if (!is_array($config[$key]) || !array_is_list($config[$key]) ||
                count(array_unique($config[$key], SORT_REGULAR)) !== count($config[$key]))
                throw new RuntimeException('PSC1_IO_CONFIGURATION');
            foreach ($config[$key] as $op) if (!is_string($op) || !in_array($op, self::OPS, true))
                throw new RuntimeException('PSC1_IO_CONFIGURATION');
        }
        if (array_diff($config['required'], $config['capabilities']))
            throw new RuntimeException('PSC1_IO_REQUIRED_CAPABILITY_DENIED');
        foreach (['maxFileBytes','maxLineBytes'] as $key) if (!is_int($config[$key]) ||
            $config[$key] < 1 || $config[$key] > 16777216) throw new RuntimeException('PSC1_IO_CONFIGURATION');
        foreach (['inputFd','outputFd'] as $key) if (!is_int($config[$key]) || $config[$key] < 0)
            throw new RuntimeException('PSC1_IO_CONFIGURATION');
        if (!is_string($config['root']) || !str_starts_with($config['root'], '/'))
            throw new RuntimeException('PSC1_IO_CONFIGURATION');
        // Only the trusted embedding host opts into FFI. Disabled/missing FFI
        // refuses before any guest load or root access.
        try {
            $this->lib = FFI::cdef(
                'int openat(int, const char *, int, ...); int close(int); int fsync(int); ' .
                'long read(int, void *, unsigned long); long write(int, const void *, unsigned long); ' .
                'int renameat(int, const char *, int, const char *); int unlinkat(int, const char *, int); ' .
                'int *__errno_location(void);', 'libc.so.6');
        } catch (Throwable $error) { throw new RuntimeException('PSC1_IO_UNSUPPORTED_ABI', 0, $error); }
        $this->root = $this->open(-100, $config['root'], self::DIRECTORY | self::NOFOLLOW);
        $this->allowed = $config['capabilities'];
        $this->fileLimit = $config['maxFileBytes']; $this->lineLimit = $config['maxLineBytes'];
        $this->input = $config['inputFd']; $this->output = $config['outputFd'];
    }
    private function syscallFailure(): never {
        $errno = $this->lib->__errno_location()[0];
        $code = match ($errno) {
            2 => 'notFound', 20,40,36 => 'pathDenied', 21,6,19 => 'wrongType',
            13,1,28,122,30,5,24,23,27,32,11 => 'ioFailure',
            default => throw new RuntimeException('PSC1_IO_HOST_ERRNO: ' . $errno)
        };
        self::deny($code);
    }
    private function open(int $directory, string $name, int $flags, int $mode = 0): int {
        $fd = $this->lib->openat($directory, $name, $flags | 02000000, $mode);
        if ($fd < 0) $this->syscallFailure();
        return $fd;
    }
    private function closeFd(int $fd): void {
        if ($this->lib->close($fd) !== 0) $this->syscallFailure();
    }
    private function info(int $fd): array {
        // php://fd duplicates the already securely opened descriptor. fstat
        // avoids architecture-dependent struct stat definitions in FFI.
        $stream = fopen('php://fd/' . $fd, 'rb');
        if ($stream === false) throw new RuntimeException('PSC1_IO_HOST_FD_DUP_FAILED');
        try {
            $info = fstat($stream);
            if ($info === false) throw new RuntimeException('PSC1_IO_HOST_FSTAT_FAILED');
            return $info;
        } finally { fclose($stream); }
    }
    private function parent(mixed $relative, Closure $action): mixed {
        if (!is_string($relative) || $relative === '' || strlen($relative) > 4096 ||
            str_contains($relative, "\\") || str_contains($relative, "\0") ||
            str_starts_with($relative, '/') || preg_match('//u', $relative) !== 1) self::deny('pathDenied');
        $parts = explode('/', $relative);
        foreach ($parts as $part) if (in_array($part, ['', '.', '..'], true)) self::deny('pathDenied');
        $directory = $this->root; $held = [];
        try {
            foreach (array_slice($parts, 0, -1) as $part) {
                $directory = $this->open($directory, $part, self::DIRECTORY | self::NOFOLLOW);
                $held[] = $directory;
            }
            return $action($directory, $parts[count($parts)-1]);
        } finally { foreach (array_reverse($held) as $fd) $this->closeFd($fd); }
    }
    private function readBytes(int $fd, int $count): string {
        $buffer = FFI::new('char[' . $count . ']');
        $size = $this->lib->read($fd, $buffer, $count);
        if ($size < 0) $this->syscallFailure();
        return FFI::string($buffer, $size);
    }
    private function writeAll(int $fd, string $bytes): void {
        $offset = 0;
        while ($offset < strlen($bytes)) {
            $chunk = substr($bytes, $offset);
            $count = $this->lib->write($fd, $chunk, strlen($chunk));
            if ($count < 0) $this->syscallFailure();
            if ($count === 0) throw new RuntimeException('PSC1_IO_HOST_WRITE_STALLED');
            $offset += $count;
        }
    }
    private function readText(mixed $relative): string {
        return $this->parent($relative, function(int $directory, string $name): string {
            $fd = $this->open($directory, $name, self::NOFOLLOW | self::NONBLOCK);
            try {
                $info = $this->info($fd);
                if (($info['mode'] & 0170000) !== 0100000) self::deny('wrongType');
                if ($info['size'] > $this->fileLimit) self::deny('tooLarge');
                $bytes = '';
                while (strlen($bytes) <= $this->fileLimit) {
                    $chunk = $this->readBytes($fd, min(65536, $this->fileLimit+1-strlen($bytes)));
                    if ($chunk === '') break;
                    $bytes .= $chunk;
                }
                if (strlen($bytes) > $this->fileLimit) self::deny('tooLarge');
                return self::decode($bytes);
            } finally { $this->closeFd($fd); }
        });
    }
    private function writeText(mixed $relative, mixed $text): void {
        $bytes = self::scalar($text, $this->fileLimit);
        $this->parent($relative, function(int $directory, string $name) use ($bytes): void {
            // O_PATH|O_NOFOLLOW opens a leaf symlink itself for fstat.
            try {
                $probe = $this->open($directory, $name, 010000000 | self::NOFOLLOW);
                try { $info = $this->info($probe); } finally { $this->closeFd($probe); }
                if (($info['mode'] & 0170000) === 0120000) self::deny('pathDenied');
                if (($info['mode'] & 0170000) !== 0100000) self::deny('wrongType');
            } catch (Psc1IoPolicy $error) { if ($error->getMessage() !== 'notFound') throw $error; }
            $temporary = '.psc1-io-' . bin2hex(random_bytes(16));
            $fd = null; $renamed = false;
            try {
                $fd = $this->open($directory, $temporary, 1 | 0100 | 0200 | self::NOFOLLOW, 0600);
                $this->writeAll($fd, $bytes);
                if ($this->lib->fsync($fd) !== 0) $this->syscallFailure();
                $this->closeFd($fd); $fd = null;
                if ($this->lib->renameat($directory, $temporary, $directory, $name) !== 0) $this->syscallFailure();
                $renamed = true;
            } finally {
                if ($fd !== null) $this->closeFd($fd);
                if (!$renamed && $this->lib->unlinkat($directory, $temporary, 0) !== 0 &&
                    $this->lib->__errno_location()[0] !== 2) $this->syscallFailure();
            }
        });
    }
    private function readLine(): ?string {
        if ($this->overflow) self::deny('tooLarge');
        $bytes = '';
        while (true) {
            if ($this->offset === strlen($this->pending) && !$this->ended) {
                $this->pending = $this->readBytes($this->input, 4096);
                $this->offset = 0; $this->ended = $this->pending === '';
            }
            if ($this->ended) {
                if (strlen($bytes) > $this->lineLimit) { $this->overflow = true; self::deny('tooLarge'); }
                return $bytes === '' ? null : self::decode($bytes);
            }
            $byte = $this->pending[$this->offset++];
            if ($byte === "\n") {
                if (str_ends_with($bytes, "\r")) $bytes = substr($bytes, 0, -1);
                return self::decode($bytes);
            }
            if (strlen($bytes) === $this->lineLimit+1) { $this->overflow = true; self::deny('tooLarge'); }
            $bytes .= $byte;
            if (strlen($bytes) > $this->lineLimit && $byte !== "\r") {
                $this->overflow = true; self::deny('tooLarge');
            }
        }
    }
    /** Retain escaped lone surrogates only to select a typed field refusal.
     * Normal valid JSON always uses PHP's parser; malformed JSON is never repaired. */
    private static function request(string $source): array {
        try { return [json_decode($source, true, 512, JSON_THROW_ON_ERROR), []]; }
        catch (JsonException $error) {
            if ($error->getCode() !== JSON_ERROR_UTF16) self::deny('protocolError');
        }
        $offset = 0; $result = []; $invalid = [];
        if (!preg_match('/\G\s*\{/A', $source, $start, 0, $offset)) self::deny('protocolError');
        $offset += strlen($start[0]);
        $token = '"(?:[^"\\\\]++|\\\\.)*+"';
        $pattern = '/\G\s*(' . $token . ')\s*:\s*(' . $token . ')\s*([,}])/As';
        while (preg_match($pattern, $source, $pair, 0, $offset)) {
            $offset += strlen($pair[0]);
            try { $key = json_decode($pair[1], true, 512, JSON_THROW_ON_ERROR); }
            catch (JsonException) { self::deny('protocolError'); }
            try { $result[$key] = json_decode($pair[2], true, 512, JSON_THROW_ON_ERROR); unset($invalid[$key]); }
            catch (JsonException $error) {
                if ($error->getCode() !== JSON_ERROR_UTF16) self::deny('protocolError');
                $result[$key] = ''; $invalid[$key] = true;
            }
            if ($pair[3] === '}') {
                if (trim(substr($source, $offset)) !== '') self::deny('protocolError');
                return [$result, $invalid];
            }
        }
        self::deny('protocolError');
    }
    public function execute(string $source): string {
        if ($this->closed) throw new RuntimeException('PSC1_IO_CLOSED');
        $reply = static fn(array $value): string => json_encode($value, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
        if (strlen($source) > 6*max($this->fileLimit, $this->lineLimit)+4096)
            return $reply(['kind'=>'error','error'=>'tooLarge']);
        try {
            [$request, $invalid] = self::request($source);
            $keys = ['readLine'=>['op'], 'writeLine'=>['op','text'],
                     'readUtf8'=>['op','path'], 'writeUtf8'=>['op','path','text']];
            if (!is_array($request) || !is_string($request['op'] ?? null) ||
                !isset($keys[$request['op']]) || isset($invalid['op']) ||
                !self::exact($request, $keys[$request['op']])) self::deny('protocolError');
            $op = $request['op'];
            if (!in_array($op, $this->allowed, true)) self::deny('capabilityDenied');
            if (isset($invalid['text'])) self::deny('invalidUtf8');
            if (isset($invalid['path'])) self::deny('pathDenied');
            if ($op === 'readLine') return $reply(['kind'=>'line','text'=>$this->readLine()]);
            if ($op === 'writeLine') {
                if (!is_string($request['text']) || str_contains($request['text'], "\r") ||
                    str_contains($request['text'], "\n")) self::deny('protocolError');
                $this->writeAll($this->output, self::scalar($request['text'], $this->lineLimit)."\n");
                return $reply(['kind'=>'unit']);
            }
            if ($op === 'readUtf8') return $reply(['kind'=>'text','text'=>$this->readText($request['path'])]);
            $this->writeText($request['path'], $request['text']);
            return $reply(['kind'=>'unit']);
        } catch (Psc1IoPolicy $error) { return $reply(['kind'=>'error','error'=>$error->getMessage()]); }
    }
    public function close(): void {
        if (!$this->closed) { $this->closed = true; $this->closeFd($this->root); }
    }
}
