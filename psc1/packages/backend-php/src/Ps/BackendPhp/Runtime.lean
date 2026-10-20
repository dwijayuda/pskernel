/- Backend-owned selected runtime; no compiler or proof checker. -/
def psPhpRuntimeVersion : String := "psc1-php-runtime/1"

def psPhpRuntimeOrder : List String :=
  ["gmp", "calls", "unicodeChars", "charOfNat", "charToNat", "stringGet", "stringNext", "stringExtract"]

def psPhpRuntimeClosure (requested : List String) : List String :=
  let requested := if requested.contains "stringNext" then "stringGet" :: requested else requested
  let requested := if requested.any (fun x => ["stringGet", "stringExtract"].contains x)
    then "unicodeChars" :: requested else requested
  let requested := if requested.any (fun x =>
      ["charOfNat", "charToNat", "stringGet", "stringNext", "stringExtract"].contains x)
    then "gmp" :: requested else requested
  psPhpRuntimeOrder.filter requested.contains

def psPhpRuntimeVariables (requirements : List String) : List String :=
  requirements.filterMap fun name =>
    if name == "gmp" then none
    else if name == "calls" then some "$__ps_wrap"
    else some ("$__ps_" ++ name)

def psPhpRuntimePart : String → String
  | "gmp" => r#"    if (!extension_loaded('gmp')) {
        throw new \RuntimeException('PSC1_PHP_GMP_REQUIRED: install ext-gmp');
    }
"#
  | "calls" => r#"    // Suspended source calls use a heap stack and no execution fuel.
    $__ps_implementations = new \WeakMap();
    $__ps_run = static function (\Generator $root) use ($__ps_implementations): mixed {
        $pending = [$root];
        while (true) {
            $task = $pending[count($pending) - 1];
            if (!$task->valid()) {
                $result = $task->getReturn();
                array_pop($pending);
                if ($pending === []) {
                    return $result;
                }
                $pending[count($pending) - 1]->send($result);
                continue;
            }
            [$fn, $arguments] = $task->current();
            if (!$fn instanceof \Closure) {
                throw new \TypeError('PSC1_PHP_CALLABLE_REQUIRED');
            }
            if (isset($__ps_implementations[$fn])) {
                $pending[] = ($__ps_implementations[$fn])(...$arguments);
            } else {
                $task->send($fn(...$arguments));
            }
        }
    };
    $__ps_wrap = static function (\Closure $implementation) use ($__ps_run, $__ps_implementations): \Closure {
        $fn = static fn (...$arguments): mixed => $__ps_run($implementation(...$arguments));
        $__ps_implementations[$fn] = $implementation;
        return $fn;
    };
"#
  | "unicodeChars" => r#"    $__ps_unicodeChars = static function (string $source): array {
        $characters = preg_split('//u', $source, -1, PREG_SPLIT_NO_EMPTY);
        if ($characters === false) {
            throw new \TypeError('PSC1_PHP_INVALID_UTF8');
        }
        return $characters;
    };
"#
  | "charOfNat" => r#"    $__ps_charOfNat = static function (\GMP $number): string {
        if (gmp_cmp($number, 0) < 0 || gmp_cmp($number, 0x110000) >= 0 ||
            (gmp_cmp($number, 0xd800) >= 0 && gmp_cmp($number, 0xdfff) <= 0)) {
            return "\0";
        }
        $value = gmp_intval($number);
        if ($value <= 0x7f) {
            return chr($value);
        }
        if ($value <= 0x7ff) {
            return chr(0xc0 | ($value >> 6)) . chr(0x80 | ($value & 0x3f));
        }
        if ($value <= 0xffff) {
            return chr(0xe0 | ($value >> 12)) . chr(0x80 | (($value >> 6) & 0x3f)) . chr(0x80 | ($value & 0x3f));
        }
        return chr(0xf0 | ($value >> 18)) . chr(0x80 | (($value >> 12) & 0x3f)) .
            chr(0x80 | (($value >> 6) & 0x3f)) . chr(0x80 | ($value & 0x3f));
    };
"#
  | "charToNat" => r#"    $__ps_charToNat = static function (string $character): \GMP {
        $first = ord($character[0]);
        if ($first < 0x80) {
            return gmp_init($first);
        }
        $size = strlen($character);
        $value = $first & (0x7f >> $size);
        for ($index = 1; $index < $size; $index++) {
            $value = ($value << 6) | (ord($character[$index]) & 0x3f);
        }
        return gmp_init($value);
    };
"#
  | "stringGet" => r#"    $__ps_stringGet = static function (string $source, \GMP $position) use ($__ps_unicodeChars): string {
        $offset = 0;
        foreach ($__ps_unicodeChars($source) as $character) {
            if (gmp_cmp($position, $offset) === 0) {
                return $character;
            }
            $offset += strlen($character);
        }
        return 'A';
    };
"#
  | "stringNext" => r#"    $__ps_stringNext = static function (string $source, \GMP $position) use ($__ps_stringGet): \GMP {
        return gmp_add($position, strlen($__ps_stringGet($source, $position)));
    };
"#
  | "stringExtract" => r#"    $__ps_stringExtract = static function (string $source, \GMP $start, \GMP $stop) use ($__ps_unicodeChars): string {
        if (gmp_cmp($start, $stop) >= 0) {
            return '';
        }
        $offset = 0;
        $started = false;
        $result = '';
        foreach ($__ps_unicodeChars($source) as $character) {
            if (!$started) {
                $started = gmp_cmp($start, $offset) === 0;
            }
            if ($started) {
                if (gmp_cmp($stop, $offset) === 0) {
                    return $result;
                }
                $result .= $character;
            }
            $offset += strlen($character);
        }
        return $result;
    };
"#
  | _ => ""

def psPhpSelectedRuntimeSource (requirements : List String) : String :=
  String.join (requirements.map psPhpRuntimePart)
