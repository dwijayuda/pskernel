-- Portable layout only: target syntax and precedence belong to the emitters.
inductive PsDoc where
  | text (value : String)
  | line
  | hardline
  | append (left right : PsDoc)
  | nest (spaces : Nat) (body : PsDoc)
  | group (body : PsDoc)
  | origin (symbol : String) (body : PsDoc)

structure PsDocRange where
  symbol : String
  startByte : Nat
  endByte : Nat

structure PsRenderedDoc where
  text : String
  ranges : List PsDocRange

def psDocJoin (separator : PsDoc) : List PsDoc → PsDoc
  | [] => .text ""
  | [doc] => doc
  | doc :: rest => .append doc (.append separator (psDocJoin separator rest))

def psDocBlock (header : String) (body : List PsDoc) : PsDoc :=
  .append (.text (header ++ " {"))
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline body)))
      (.append .hardline (.text "}")))

-- A bounded scan stops once a group cannot fit. It never changes syntax.
def psDocFits : Nat → Nat → List PsDoc → Bool
  | 0, _, _ => false
  | _ + 1, _, [] => true
  | fuel + 1, width, doc :: rest =>
      match doc with
      | .text text =>
          if text.length > width || text.contains '\n' then false
          else psDocFits fuel (width - text.length) rest
      | .line => if width == 0 then false else psDocFits fuel (width - 1) rest
      | .hardline => false
      | .append left right => psDocFits fuel width (left :: right :: rest)
      | .nest _ body | .group body | .origin _ body => psDocFits fuel width (body :: rest)

inductive PsDocTask where
  | doc (indent : Nat) (flat : Bool) (body : PsDoc)
  | endOrigin (symbol : String) (startByte : Nat)

structure PsDocState where
  chunks : List String := []
  ranges : List PsDocRange := []
  byteOffset : Nat := 0
  column : Nat := 0

def psDocWrite (state : PsDocState) (text : String) : PsDocState :=
  { state with chunks := text :: state.chunks,
    byteOffset := state.byteOffset + text.utf8ByteSize,
    column := if text.contains '\n' then (text.splitOn "\n").getLast!.length else state.column + text.length }

def psDocRenderLoop (width : Nat) : Nat → List PsDocTask → PsDocState →
    Except String PsRenderedDoc
  | 0, _, _ => .error "PSCV0-PRINT: layout budget exhausted"
  | _ + 1, [], state => .ok {
      text := String.join state.chunks.reverse, ranges := state.ranges.reverse }
  | fuel + 1, task :: rest, state =>
      match task with
      | .endOrigin symbol startByte =>
          psDocRenderLoop width fuel rest { state with
            ranges := { symbol, startByte, endByte := state.byteOffset } :: state.ranges }
      | .doc indent flat doc =>
          let next := psDocRenderLoop width fuel
          match doc with
          | .text text => next rest (psDocWrite state text)
          | .append left right =>
              next (.doc indent flat left :: .doc indent flat right :: rest) state
          | .nest spaces body => next (.doc (indent + spaces) flat body :: rest) state
          | .group body =>
              next (.doc indent (flat || psDocFits 10000 (width - state.column) [body]) body :: rest) state
          | .origin symbol body =>
              next (.doc indent flat body :: .endOrigin symbol state.byteOffset :: rest) state
          | .line =>
              if flat then next rest (psDocWrite state " ")
              else
                let padding := String.ofList (List.replicate indent ' ')
                next rest { psDocWrite state ("\n" ++ padding) with column := indent }
          | .hardline =>
              let padding := String.ofList (List.replicate indent ' ')
              next rest { psDocWrite state ("\n" ++ padding) with column := indent }

def psRenderDoc (doc : PsDoc) (width : Nat := 100) : Except String PsRenderedDoc :=
  psDocRenderLoop width 5000000 [.doc 0 false doc] {}
