import Ps.BackendCommon.Plan

-- Backend-owned readable helpers; exact selected bytes and order are preserved.
def psPythonRuntimeVersion : String := "psc1-python-runtime/1"
def psPythonMinimumVersion : String := "3.14"

def psPythonRuntimeDependencies (helper : String) : List String :=
  if psStringEq helper "builtins" then []
  else if psStringEq helper "calls" then ["builtins"]
  else if psStringEq helper "int-repr" then ["builtins"]
  else if psStringEq helper "char-of-nat" then ["builtins"]
  else if psStringEq helper "string-get" then ["builtins"]
  else if psStringEq helper "string-next" then ["builtins"]
  else if psStringEq helper "string-extract" then ["builtins"]
  else if psStringEq helper "array-get" then ["builtins"]
  else if psStringEq helper "array-get-d" then ["builtins"]
  else if psStringEq helper "array-set" then ["builtins"]
  else if psStringEq helper "array-set-if" then ["builtins"]
  else if psStringEq helper "array-map" then ["builtins", "calls"]
  else if psStringEq helper "array-foldl" then ["builtins", "calls"]
  else List.nil

def psPythonRuntimeBody (helper : String) : String :=
  if psStringEq helper "builtins" then "import builtins as _psc_b\n\n"
  else if psStringEq helper "calls" then "from types import GeneratorType as _psc_Generator\n\ndef _psc_run(fn, *args):\n    \"\"\"Evaluate generated calls with an explicit stack and no runtime fuel.\"\"\"\n    current = fn(*args)\n    if _psc_b.type(current) is not _psc_Generator:\n        return current\n    stack = []\n    value = None\n    while True:\n        try:\n            request = current.send(value)\n        except _psc_b.StopIteration as finished:\n            value = finished.value\n            if not stack:\n                return value\n            current = stack.pop()\n            continue\n        callee, arguments, tail = request\n        result = callee(*arguments)\n        if _psc_b.type(result) is _psc_Generator:\n            if not tail:\n                stack.append(current)\n            current = result\n            value = None\n        else:\n            value = result\n\n"
  else if psStringEq helper "int-repr" then "def _psc_int_repr(value):\n    \"\"\"Unbounded decimal formatting without changing Python's global digit limit.\"\"\"\n    if value == 0:\n        return \"0\"\n    negative = value < 0\n    magnitude = -value if negative else value\n    chunks = []\n    while magnitude:\n        magnitude, remainder = _psc_b.divmod(magnitude, 1000000000)\n        chunks.append(_psc_b.str(remainder))\n    result = chunks.pop()\n    while chunks:\n        result += chunks.pop().rjust(9, \"0\")\n    return \"-\" + result if negative else result\n\n"
  else if psStringEq helper "char-of-nat" then "def _psc_char_of_nat(value):\n    if 0 <= value < 0xD800 or 0xDFFF < value < 0x110000:\n        return _psc_b.chr(value)\n    return \"\\x00\"\n\n"
  else if psStringEq helper "string-get" then "def _psc_string_get(text, position):\n    data = text.encode(\"utf-8\")\n    if position < 0 or position >= _psc_b.len(data):\n        return \"A\"\n    first = data[position]\n    if 0x80 <= first < 0xC0:\n        return \"A\"\n    width = 1 if first < 0x80 else 2 if first < 0xE0 else 3 if first < 0xF0 else 4\n    return data[position:position + width].decode(\"utf-8\")\n\n"
  else if psStringEq helper "string-next" then "def _psc_string_next(text, position):\n    data = text.encode(\"utf-8\")\n    if position < 0 or position >= _psc_b.len(data):\n        return position + 1\n    first = data[position]\n    if 0x80 <= first < 0xC0:\n        return position + 1\n    width = 1 if first < 0x80 else 2 if first < 0xE0 else 3 if first < 0xF0 else 4\n    return position + width\n\n"
  else if psStringEq helper "string-extract" then "def _psc_string_extract(text, begin, end):\n    if begin >= end:\n        return \"\"\n    data = text.encode(\"utf-8\")\n    size = _psc_b.len(data)\n    if begin < 0 or begin >= size or 0x80 <= data[begin] < 0xC0:\n        return \"\"\n    if end >= size or 0x80 <= data[end] < 0xC0:\n        return data[begin:].decode(\"utf-8\")\n    return data[begin:end].decode(\"utf-8\")\n\n"
  else if psStringEq helper "array-get" then "def _psc_array_get(array, index):\n    if index < 0 or index >= _psc_b.len(array):\n        raise _psc_b.IndexError(\"PSC1_ARRAY_BOUNDS\")\n    return array[index]\n\n"
  else if psStringEq helper "array-get-d" then "def _psc_array_get_d(array, index, fallback):\n    return array[index] if 0 <= index < _psc_b.len(array) else fallback\n\n"
  else if psStringEq helper "array-set" then "def _psc_array_set(array, index, value):\n    if index < 0 or index >= _psc_b.len(array):\n        raise _psc_b.IndexError(\"PSC1_ARRAY_BOUNDS\")\n    return array[:index] + (value,) + array[index + 1:]\n\n"
  else if psStringEq helper "array-set-if" then "def _psc_array_set_if(array, index, value):\n    if index < 0 or index >= _psc_b.len(array):\n        return array\n    return array[:index] + (value,) + array[index + 1:]\n\n"
  else if psStringEq helper "array-map" then "def _psc_array_map(fn, array):\n    result = []\n    for value in array:\n        result.append((yield (fn, (value,), False)))\n    return _psc_b.tuple(result)\n\n"
  else if psStringEq helper "array-foldl" then "def _psc_array_foldl(fn, initial, array, start, stop):\n    result = initial\n    end = stop if stop <= _psc_b.len(array) else _psc_b.len(array)\n    for index in _psc_b.range(start, end):\n        result = yield (fn, (result, array[index]), False)\n    return result\n\n"
  else ""

def psPythonRuntimeFold
    (step : List String -> String -> List String)
    (selected : List String) (names : List String) : List String :=
  match names with
  | List.nil => selected
  | List.cons name rest => psPythonRuntimeFold step (step selected name) rest

def psPythonRuntimeAddWithFuel (fuel : Nat) : List String -> String -> List String :=
  match fuel with
  | Nat.zero => fun (selected : List String) (_helper : String) => selected
  | Nat.succ remaining =>
      fun (selected : List String) (helper : String) =>
        if psBackendNameSeen helper selected then selected
        else psListAppend
          (psPythonRuntimeFold (psPythonRuntimeAddWithFuel remaining)
            selected (psPythonRuntimeDependencies helper)) [helper]

def psPythonRuntimeClosure (requested : List String) : List String :=
  psPythonRuntimeFold (psPythonRuntimeAddWithFuel 16) List.nil requested

def psPythonRuntimeSourceAcc (selected : List String) (source : String) : String :=
  match selected with
  | List.nil => source
  | List.cons helper rest =>
      psPythonRuntimeSourceAcc rest (String.Internal.append source (psPythonRuntimeBody helper))

def psPythonRuntimeSource (selected : List String) : String :=
  psPythonRuntimeSourceAcc selected ""
