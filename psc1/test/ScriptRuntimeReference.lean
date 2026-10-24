import Ps.BackendPython.Runtime
import Ps.BackendPhp.Runtime

namespace PsScriptRuntimeReference.Python
-- Backend-owned readable Python helpers. Only the requested transitive closure is emitted.
def psPythonRuntimeVersion : String := "psc1-python-runtime/1"
def psPythonMinimumVersion : String := "3.14"

def psPythonRuntimeDependencies : String → List String
  | "builtins" => []
  | "calls" => ["builtins"]
  | "int-repr" => ["builtins"]
  | "char-of-nat" => ["builtins"]
  | "string-get" => ["builtins"]
  | "string-next" => ["builtins"]
  | "string-extract" => ["builtins"]
  | "array-get" => ["builtins"]
  | "array-get-d" => ["builtins"]
  | "array-set" => ["builtins"]
  | "array-set-if" => ["builtins"]
  | "array-map" => ["builtins", "calls"]
  | "array-foldl" => ["builtins", "calls"]
  | _ => []

def psPythonRuntimeBody : String → String
  | "builtins" => "import builtins as _psc_b\n\n"
  | "calls" => "from types import GeneratorType as _psc_Generator\n\ndef _psc_run(fn, *args):\n    \"\"\"Evaluate generated calls with an explicit stack and no runtime fuel.\"\"\"\n    current = fn(*args)\n    if _psc_b.type(current) is not _psc_Generator:\n        return current\n    stack = []\n    value = None\n    while True:\n        try:\n            request = current.send(value)\n        except _psc_b.StopIteration as finished:\n            value = finished.value\n            if not stack:\n                return value\n            current = stack.pop()\n            continue\n        callee, arguments, tail = request\n        result = callee(*arguments)\n        if _psc_b.type(result) is _psc_Generator:\n            if not tail:\n                stack.append(current)\n            current = result\n            value = None\n        else:\n            value = result\n\n"
  | "int-repr" => "def _psc_int_repr(value):\n    \"\"\"Unbounded decimal formatting without changing Python's global digit limit.\"\"\"\n    if value == 0:\n        return \"0\"\n    negative = value < 0\n    magnitude = -value if negative else value\n    chunks = []\n    while magnitude:\n        magnitude, remainder = _psc_b.divmod(magnitude, 1000000000)\n        chunks.append(_psc_b.str(remainder))\n    result = chunks.pop()\n    while chunks:\n        result += chunks.pop().rjust(9, \"0\")\n    return \"-\" + result if negative else result\n\n"
  | "char-of-nat" => "def _psc_char_of_nat(value):\n    if 0 <= value < 0xD800 or 0xDFFF < value < 0x110000:\n        return _psc_b.chr(value)\n    return \"\\x00\"\n\n"
  | "string-get" => "def _psc_string_get(text, position):\n    data = text.encode(\"utf-8\")\n    if position < 0 or position >= _psc_b.len(data):\n        return \"A\"\n    first = data[position]\n    if 0x80 <= first < 0xC0:\n        return \"A\"\n    width = 1 if first < 0x80 else 2 if first < 0xE0 else 3 if first < 0xF0 else 4\n    return data[position:position + width].decode(\"utf-8\")\n\n"
  | "string-next" => "def _psc_string_next(text, position):\n    data = text.encode(\"utf-8\")\n    if position < 0 or position >= _psc_b.len(data):\n        return position + 1\n    first = data[position]\n    if 0x80 <= first < 0xC0:\n        return position + 1\n    width = 1 if first < 0x80 else 2 if first < 0xE0 else 3 if first < 0xF0 else 4\n    return position + width\n\n"
  | "string-extract" => "def _psc_string_extract(text, begin, end):\n    if begin >= end:\n        return \"\"\n    data = text.encode(\"utf-8\")\n    size = _psc_b.len(data)\n    if begin < 0 or begin >= size or 0x80 <= data[begin] < 0xC0:\n        return \"\"\n    if end >= size or 0x80 <= data[end] < 0xC0:\n        return data[begin:].decode(\"utf-8\")\n    return data[begin:end].decode(\"utf-8\")\n\n"
  | "array-get" => "def _psc_array_get(array, index):\n    if index < 0 or index >= _psc_b.len(array):\n        raise _psc_b.IndexError(\"PSC1_ARRAY_BOUNDS\")\n    return array[index]\n\n"
  | "array-get-d" => "def _psc_array_get_d(array, index, fallback):\n    return array[index] if 0 <= index < _psc_b.len(array) else fallback\n\n"
  | "array-set" => "def _psc_array_set(array, index, value):\n    if index < 0 or index >= _psc_b.len(array):\n        raise _psc_b.IndexError(\"PSC1_ARRAY_BOUNDS\")\n    return array[:index] + (value,) + array[index + 1:]\n\n"
  | "array-set-if" => "def _psc_array_set_if(array, index, value):\n    if index < 0 or index >= _psc_b.len(array):\n        return array\n    return array[:index] + (value,) + array[index + 1:]\n\n"
  | "array-map" => "def _psc_array_map(fn, array):\n    result = []\n    for value in array:\n        result.append((yield (fn, (value,), False)))\n    return _psc_b.tuple(result)\n\n"
  | "array-foldl" => "def _psc_array_foldl(fn, initial, array, start, stop):\n    result = initial\n    end = stop if stop <= _psc_b.len(array) else _psc_b.len(array)\n    for index in _psc_b.range(start, end):\n        result = yield (fn, (result, array[index]), False)\n    return result\n\n"
  | _ => ""

private def addHelper (fuel : Nat) (selected : List String) (id : String) : List String :=
  match fuel with
  | 0 => selected
  | fuel + 1 =>
      if selected.contains id then selected
      else
        let selected := (psPythonRuntimeDependencies id).foldl (addHelper fuel) selected
        selected ++ [id]

def psPythonRuntimeClosure (requested : List String) : List String :=
  requested.foldl (addHelper 16) []

def psPythonRuntimeSource (selected : List String) : String :=
  String.join (selected.map psPythonRuntimeBody)

end PsScriptRuntimeReference.Python

namespace PsScriptRuntimeReference.Php
/- Backend-owned selected runtime; no compiler or proof checker. -/
def psPhpRuntimeVersion : String := "psc1-php-runtime/1"

def psPhpRuntimeOrder : List String :=
  ["gmp", "calls", "unicodeChars", "utf8Valid", "charOfNat", "charToNat", "stringGet", "stringNext", "stringExtract"]

def psPhpRuntimeClosure (requested : List String) : List String :=
  let requested := if requested.contains "stringNext" then "stringGet" :: requested else requested
  let requested := if requested.contains "stringGet" then "utf8Valid" :: requested else requested
  let requested := if requested.contains "stringExtract" then "unicodeChars" :: requested else requested
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
  | "utf8Valid" => r#"    // PHP memoizes immutable String-key hashes; retain at most two valid keys.
    $__ps_utf8Valid = static function (string $source): bool {
        static $checked = [];
        if (isset($checked[$source])) {
            return true;
        }
        if (preg_match('//u', $source) !== 1) {
            return false;
        }
        if (count($checked) === 2) {
            unset($checked[array_key_first($checked)]);
        }
        $checked[$source] = true;
        return true;
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
  | "stringGet" => r#"    $__ps_stringGet = static function (string $source, \GMP $position) use ($__ps_utf8Valid): string {
        // Validate the entire String even when the requested position is outside it.
        if (!$__ps_utf8Valid($source)) {
            throw new \TypeError('PSC1_PHP_INVALID_UTF8');
        }
        if (gmp_cmp($position, 0) < 0 || gmp_cmp($position, strlen($source)) >= 0) {
            return 'A';
        }
        // Conversion is safe only after comparison with the native String size.
        $offset = gmp_intval($position);
        $first = ord($source[$offset]);
        if ($first < 0x80) {
            return $source[$offset];
        }
        if ($first < 0xc0) {
            return 'A';
        }
        $width = $first <= 0xdf ? 2 : ($first <= 0xef ? 3 : 4);
        return substr($source, $offset, $width);
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

end PsScriptRuntimeReference.Php
