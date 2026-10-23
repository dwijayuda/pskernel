-- Higher occupied levels contain older chunks. Carrying combines older then newer.
-- The representation uses only immutable strings and structural list recursion.
structure PsTextBuilder where
  levels : List (Option String)

def psTextBuilderEmpty : PsTextBuilder :=
  PsTextBuilder.mk List.nil

def psTextInsertApplied (levels : List (Option String)) (chunk : String) :
    List (Option String) :=
  match levels with
  | List.nil => List.cons (Option.some chunk) List.nil
  | List.cons level rest =>
      match level with
      | Option.none => List.cons (Option.some chunk) rest
      | Option.some older =>
          List.cons Option.none
            (psTextInsertApplied rest (String.Internal.append older chunk))

def psTextInsert (levels : List (Option String)) : String -> List (Option String) :=
  fun (chunk : String) => psTextInsertApplied levels chunk

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

def psTextJoinApplied (separator : String) (values : List String)
    (first : Bool) (builder : PsTextBuilder) : String :=
  match values with
  | List.nil => psTextBuilderFinish builder
  | List.cons value rest =>
      let separated : PsTextBuilder :=
        if first then builder else psTextBuilderAppend builder separator;
      psTextJoinApplied separator rest false (psTextBuilderAppend separated value)

def psTextJoinWorker (separator : String) (values : List String) :
    Bool -> PsTextBuilder -> String :=
  fun (first : Bool) (builder : PsTextBuilder) =>
    psTextJoinApplied separator values first builder

def psTextJoin
    (separator : String)
    (values : List String) : String :=
  psTextJoinWorker separator values true psTextBuilderEmpty
