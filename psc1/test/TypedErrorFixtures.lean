-- This exact source is compiled twice: by the pinned native Lean oracle and
-- by PSC1 through both supported source grammars. No PSC1 backend is the oracle.

def errorCaught (flag : Bool) : Except Nat Nat := do
  let mut value : Nat := 10
  try
    value := value + 3
    if flag then
      throw value
    value := value + 7
  catch error =>
    value := value + error
  return value

def errorUncaught (flag : Bool) : Except Nat Nat := do
  if flag then
    throw 19
  return 23

def errorAfter (flag : Bool) : Except Nat Nat := do
  try
    pure ()
  catch error =>
    return error + 1000
  if flag then
    throw 41
  return 43

def errorEarly (flag : Bool) : Except Nat Nat := do
  try
    if flag then
      return 31
    throw 6
  catch error =>
    return error + 70

def errorTerminal (flag : Bool) : Except Nat Nat := do
  try
    if flag then
      throw 5
    pure 7
  catch error =>
    pure (error + 9)

def errorNested (flag : Bool) : Except Nat Nat := do
  let mut value : Nat := 2
  try
    value := 10
    try
      value := 20
      throw 3
    catch inner =>
      value := value + inner
      if flag then
        throw value
    value := value + 1
  catch outer =>
    value := value + outer
  return value

def errorHandlerRethrow (flag : Bool) : Except Nat Nat := do
  try
    throw 2
  catch error =>
    if flag then
      throw (error + 5)
    return (error + 9)

def errorShadow (flag : Bool) : Except Nat Nat := do
  let error : Nat := 90
  try
    if flag then
      throw 4
  catch error =>
    return error
  return error

def errorCapture (flag : Bool) : Except Nat Nat := do
  let mut value : Nat := 2
  let captured : Nat -> Nat := fun (x : Nat) => value + x
  try
    value := 8
    if flag then
      throw 3
  catch error =>
    value := captured error
  return (value * 100 + captured 1)

def errorFor (flag : Bool) : Except Nat Nat := do
  let mut total : Nat := 0
  for i in [0:4] do
    try
      total := total + i
      if flag && Nat.beq i 2 then
        throw 9
    catch error =>
      total := total + error
  return total

def errorForReturn (flag : Bool) : Except Nat Nat := do
  let mut total : Nat := 0
  try
    for i in [0:4] do
      total := total + i
      if Nat.beq i 2 then
        if flag then
          return (total + 50)
        throw 9
  catch error =>
    total := total + error
  return total

def errorNestedDo (flag : Bool) : Except Nat Nat := do
  let nested : Except Nat Nat := do
    try
      if flag then
        return 7
      throw 2
    catch error =>
      return (error + 10)
  match nested with
  | Except.error error => Except.error error
  | Except.ok value => Except.ok (value + 100)

def errorBoundThrow (flag : Bool) : Except Nat Nat := do
  try
    let value : Nat <- throw 11
    return value
  catch error =>
    if flag then
      return (error + 1)
    return (error + 2)

def errorThrowShadow (flag : Bool) : Except Nat Nat := do
  let throw : Nat -> Except Nat Unit := fun (value : Nat) => Except.ok ()
  try
    throw 7
  catch error =>
    return error
  if flag then
    return 101
  return 103

def errorResultPayload (flag : Bool) : Except Nat Nat := do
  let result : Except Nat (Except Nat Nat) := do
    try
      if flag then
        return (Except.error 29)
      throw 3
    catch error =>
      return (Except.ok (error + 30))
  match result with
  | Except.error error => Except.ok (error + 1000)
  | Except.ok inner =>
    match inner with
    | Except.error value => Except.ok (value + 100)
    | Except.ok value => Except.ok (value + 200)

def errorPatternFor (flag : Bool) : Except Nat Nat := do
  let mut total : Nat := 0
  for i in [0:2] do
    if flag && Nat.beq i 1 then
      throw 9
    try
      let (value, ignored) : Nat × Nat := (i, 0)
      total := total + value + 1
    catch error =>
      return error + 100
  return total
