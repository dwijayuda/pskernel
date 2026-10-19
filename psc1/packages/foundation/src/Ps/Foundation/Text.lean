-- Higher occupied levels contain older chunks. Carrying combines older then newer.
-- The representation uses only immutable strings and structural list recursion.
structure PsTextBuilder where
  levels : List (Option String)

def psTextBuilderEmpty : PsTextBuilder :=
  PsTextBuilder.mk List.nil

def psTextInsert
    (levels : List (Option String)) :
    String -> List (Option String) :=
  match levels with
  | List.nil =>
      fun (chunk : String) =>
        List.cons (Option.some chunk) List.nil
  | List.cons level rest =>
      let smaller : String -> List (Option String) :=
        psTextInsert rest;
      fun (chunk : String) =>
        match level with
        | Option.none =>
            List.cons (Option.some chunk) rest
        | Option.some older =>
            List.cons Option.none
              (smaller (String.Internal.append older chunk))

def psTextBuilderAppend
    (builder : PsTextBuilder)
    (chunk : String) : PsTextBuilder :=
  PsTextBuilder.mk (psTextInsert builder.levels chunk)

def psTextFinish
    (levels : List (Option String)) : String :=
  match levels with
  | List.nil => ""
  | List.cons level rest =>
      let older : String := psTextFinish rest;
      match level with
      | Option.none => older
      | Option.some newer => String.Internal.append older newer

def psTextBuilderFinish
    (builder : PsTextBuilder) : String :=
  psTextFinish builder.levels

def psTextJoinWorker
    (separator : String)
    (values : List String) :
    Bool -> PsTextBuilder -> String :=
  match values with
  | List.nil =>
      fun (_first : Bool) (builder : PsTextBuilder) =>
        psTextBuilderFinish builder
  | List.cons value rest =>
      let smaller : Bool -> PsTextBuilder -> String :=
        psTextJoinWorker separator rest;
      fun (first : Bool) (builder : PsTextBuilder) =>
        let separated : PsTextBuilder :=
          if first then builder else psTextBuilderAppend builder separator;
        smaller false (psTextBuilderAppend separated value)

def psTextJoin
    (separator : String)
    (values : List String) : String :=
  psTextJoinWorker separator values true psTextBuilderEmpty
