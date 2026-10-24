import Ps.BackendCommon.Plan

-- Backend-owned selected runtime; raw runtime text is exact data.
def psPhpRuntimeVersion : String := "psc1-php-runtime/1"

def psPhpRuntimeOrder : List String :=
  ["gmp", "calls", "nodes", "unicodeChars", "utf8Valid", "charOfNat", "charToNat", "stringGet", "stringNext", "stringExtract"]

def psPhpRuntimeSelectAcc (requested : List String) (order : List String)
    (selectedRev : List String) : List String :=
  match order with
  | List.nil => psListReverse selectedRev
  | List.cons helper rest =>
      if psBackendNameSeen helper requested then
        psPhpRuntimeSelectAcc requested rest (List.cons helper selectedRev)
      else psPhpRuntimeSelectAcc requested rest selectedRev

def psPhpRuntimeClosure (requested : List String) : List String :=
  let withGet : List String :=
    if psBackendNameSeen "stringNext" requested then List.cons "stringGet" requested else requested;
  let withValid : List String :=
    if psBackendNameSeen "stringGet" withGet then List.cons "utf8Valid" withGet else withGet;
  let withChars : List String :=
    if psBackendNameSeen "stringExtract" withValid then List.cons "unicodeChars" withValid else withValid;
  let withGmp : List String :=
    if psListAny (fun (helper : String) =>
        psBackendNameSeen helper ["charOfNat", "charToNat", "stringGet", "stringNext", "stringExtract"]) withChars
    then List.cons "gmp" withChars else withChars;
  psPhpRuntimeSelectAcc withGmp psPhpRuntimeOrder List.nil

def psPhpRuntimeVariablesAcc (requirements : List String) (variablesRev : List String) : List String :=
  match requirements with
  | List.nil => psListReverse variablesRev
  | List.cons helper rest =>
      if psStringEq helper "gmp" then psPhpRuntimeVariablesAcc rest variablesRev
      else if psStringEq helper "calls" then
        psPhpRuntimeVariablesAcc rest (List.cons "$__ps_wrap" variablesRev)
      else psPhpRuntimeVariablesAcc rest
        (List.cons (String.Internal.append "$__ps_" helper) variablesRev)

def psPhpRuntimeVariables (requirements : List String) : List String :=
  psPhpRuntimeVariablesAcc requirements List.nil

def psPhpRuntimePart (helper : String) : String :=
  if psStringEq helper "gmp" then "    if (!extension_loaded('gmp')) {\n        throw new \\RuntimeException('PSC1_PHP_GMP_REQUIRED: install ext-gmp');\n    }\n"
  else if psStringEq helper "calls" then "    // Suspended source calls use a heap stack and no execution fuel.\n    $__ps_implementations = new \\WeakMap();\n    $__ps_run = static function (\\Generator $root) use ($__ps_implementations): mixed {\n        $pending = [$root];\n        while (true) {\n            $task = $pending[count($pending) - 1];\n            if (!$task->valid()) {\n                $result = $task->getReturn();\n                array_pop($pending);\n                if ($pending === []) {\n                    return $result;\n                }\n                $pending[count($pending) - 1]->send($result);\n                continue;\n            }\n            [$fn, $arguments] = $task->current();\n            if (!$fn instanceof \\Closure) {\n                throw new \\TypeError('PSC1_PHP_CALLABLE_REQUIRED');\n            }\n            if (isset($__ps_implementations[$fn])) {\n                $pending[] = ($__ps_implementations[$fn])(...$arguments);\n            } else {\n                $task->send($fn(...$arguments));\n            }\n        }\n    };\n    $__ps_wrap = static function (\\Closure $implementation) use ($__ps_run, $__ps_implementations): \\Closure {\n        $fn = static fn (...$arguments): mixed => $__ps_run($implementation(...$arguments));\n        $__ps_implementations[$fn] = $implementation;\n        return $fn;\n    };\n"
  else if psStringEq helper "nodes" then "    // Compact immutable inductives; reclaim dead descendants without recursive Zend array destruction.\n    $__ps_nodes = static function (string $tag, mixed ...$fields): \\ArrayAccess {\n        return new class($tag, $fields) implements \\ArrayAccess {\n            private string $tag;\n            private int $count;\n            private mixed $first;\n            private mixed $second;\n            private array $rest;\n            public function __construct(string $tag, array $fields) {\n                $this->tag = $tag;\n                $this->count = count($fields);\n                $this->first = $fields[0] ?? null;\n                $this->second = $fields[1] ?? null;\n                $this->rest = count($fields) > 2 ? array_slice($fields, 2) : [];\n            }\n            public function offsetExists(mixed $offset): bool {\n                return is_int($offset) && $offset >= 0 && $offset <= $this->count;\n            }\n            public function offsetGet(mixed $offset): mixed {\n                if (!$this->offsetExists($offset)) {\n                    throw new \\UnexpectedValueException('PSC1_PHP_CONSTRUCTOR_FIELD');\n                }\n                if ($offset === 0) return $this->tag;\n                if ($offset === 1) return $this->first;\n                if ($offset === 2) return $this->second;\n                return $this->rest[$offset - 3];\n            }\n            public function offsetSet(mixed $offset, mixed $value): void {\n                throw new \\LogicException('PSC1_PHP_IMMUTABLE_CONSTRUCTOR');\n            }\n            public function offsetUnset(mixed $offset): void {\n                throw new \\LogicException('PSC1_PHP_IMMUTABLE_CONSTRUCTOR');\n            }\n            public function __destruct() {\n                static $draining = false;\n                static $pending = [];\n                // Only this already-dead node is cleared. A queued child that\n                // still has other owners remains live and is never modified.\n                foreach ([$this->first, $this->second, $this->rest] as $value) {\n                    if (is_object($value) || (is_array($value) && $value !== [])) {\n                        $pending[] = $value;\n                    }\n                }\n                unset($value);\n                $this->first = null;\n                $this->second = null;\n                $this->rest = [];\n                if ($draining) return;\n                $draining = true;\n                try {\n                    while ($pending !== []) {\n                        $value = array_pop($pending);\n                        unset($value);\n                    }\n                } finally {\n                    $draining = false;\n                }\n            }\n        };\n    };\n"
  else if psStringEq helper "utf8Valid" then "    // PHP memoizes immutable String-key hashes; retain at most two valid keys.\n    $__ps_utf8Valid = static function (string $source): bool {\n        static $checked = [];\n        if (isset($checked[$source])) {\n            return true;\n        }\n        if (preg_match('//u', $source) !== 1) {\n            return false;\n        }\n        if (count($checked) === 2) {\n            unset($checked[array_key_first($checked)]);\n        }\n        $checked[$source] = true;\n        return true;\n    };\n"
  else if psStringEq helper "unicodeChars" then "    $__ps_unicodeChars = static function (string $source): array {\n        $characters = preg_split('//u', $source, -1, PREG_SPLIT_NO_EMPTY);\n        if ($characters === false) {\n            throw new \\TypeError('PSC1_PHP_INVALID_UTF8');\n        }\n        return $characters;\n    };\n"
  else if psStringEq helper "charOfNat" then "    $__ps_charOfNat = static function (\\GMP $number): string {\n        if (gmp_cmp($number, 0) < 0 || gmp_cmp($number, 0x110000) >= 0 ||\n            (gmp_cmp($number, 0xd800) >= 0 && gmp_cmp($number, 0xdfff) <= 0)) {\n            return \"\\0\";\n        }\n        $value = gmp_intval($number);\n        if ($value <= 0x7f) {\n            return chr($value);\n        }\n        if ($value <= 0x7ff) {\n            return chr(0xc0 | ($value >> 6)) . chr(0x80 | ($value & 0x3f));\n        }\n        if ($value <= 0xffff) {\n            return chr(0xe0 | ($value >> 12)) . chr(0x80 | (($value >> 6) & 0x3f)) . chr(0x80 | ($value & 0x3f));\n        }\n        return chr(0xf0 | ($value >> 18)) . chr(0x80 | (($value >> 12) & 0x3f)) .\n            chr(0x80 | (($value >> 6) & 0x3f)) . chr(0x80 | ($value & 0x3f));\n    };\n"
  else if psStringEq helper "charToNat" then "    $__ps_charToNat = static function (string $character): \\GMP {\n        $first = ord($character[0]);\n        if ($first < 0x80) {\n            return gmp_init($first);\n        }\n        $size = strlen($character);\n        $value = $first & (0x7f >> $size);\n        for ($index = 1; $index < $size; $index++) {\n            $value = ($value << 6) | (ord($character[$index]) & 0x3f);\n        }\n        return gmp_init($value);\n    };\n"
  else if psStringEq helper "stringGet" then "    $__ps_stringGet = static function (string $source, \\GMP $position) use ($__ps_utf8Valid): string {\n        // Validate the entire String even when the requested position is outside it.\n        if (!$__ps_utf8Valid($source)) {\n            throw new \\TypeError('PSC1_PHP_INVALID_UTF8');\n        }\n        if (gmp_cmp($position, 0) < 0 || gmp_cmp($position, strlen($source)) >= 0) {\n            return 'A';\n        }\n        // Conversion is safe only after comparison with the native String size.\n        $offset = gmp_intval($position);\n        $first = ord($source[$offset]);\n        if ($first < 0x80) {\n            return $source[$offset];\n        }\n        if ($first < 0xc0) {\n            return 'A';\n        }\n        $width = $first <= 0xdf ? 2 : ($first <= 0xef ? 3 : 4);\n        return substr($source, $offset, $width);\n    };\n"
  else if psStringEq helper "stringNext" then "    $__ps_stringNext = static function (string $source, \\GMP $position) use ($__ps_stringGet): \\GMP {\n        return gmp_add($position, strlen($__ps_stringGet($source, $position)));\n    };\n"
  else if psStringEq helper "stringExtract" then "    $__ps_stringExtract = static function (string $source, \\GMP $start, \\GMP $stop) use ($__ps_unicodeChars): string {\n        if (gmp_cmp($start, $stop) >= 0) {\n            return '';\n        }\n        $offset = 0;\n        $started = false;\n        $result = '';\n        foreach ($__ps_unicodeChars($source) as $character) {\n            if (!$started) {\n                $started = gmp_cmp($start, $offset) === 0;\n            }\n            if ($started) {\n                if (gmp_cmp($stop, $offset) === 0) {\n                    return $result;\n                }\n                $result .= $character;\n            }\n            $offset += strlen($character);\n        }\n        return $result;\n    };\n"
  else ""

def psPhpRuntimeSourceAcc (requirements : List String) (source : String) : String :=
  match requirements with
  | List.nil => source
  | List.cons helper rest =>
      psPhpRuntimeSourceAcc rest (String.Internal.append source (psPhpRuntimePart helper))

def psPhpSelectedRuntimeSource (requirements : List String) : String :=
  psPhpRuntimeSourceAcc requirements ""
