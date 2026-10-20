partial def errorWhile (flag : Bool) : Except Nat Nat := do
  let mut index : Nat := 0
  try
    while Nat.blt index 10000 do
      index := index + 1
      if flag && Nat.beq index 3 then
        throw index
  catch error =>
    index := index + error + 50
  return index
