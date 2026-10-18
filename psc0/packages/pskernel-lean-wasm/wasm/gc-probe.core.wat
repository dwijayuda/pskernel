(module
  (rec
    (type $__ps_Value (sub (struct)))
    (type $__ps_Scalar (sub final $__ps_Value (struct
      (field $value i32))))
    (type $__ps_WideScalar (sub final $__ps_Value (struct
      (field $value i64))))
    (type $__ps_Float32Box (sub final $__ps_Value (struct
      (field $value f32))))
    (type $__ps_Float64Box (sub final $__ps_Value (struct
      (field $value f64))))
    (type $__ps_Natural (sub final $__ps_Value (struct
      (field $limbs (ref $__ps_Limbs)))))
    (type $__ps_Integer (sub final $__ps_Value (struct
      (field $sign i32)
      (field $magnitude (ref $__ps_Natural)))))
    (type $__ps_String (sub final $__ps_Value (struct
      (field $bytes (ref $__ps_Bytes))
      (field $length i32))))
    (type $__ps_Array (sub final $__ps_Value (struct
      (field $values (ref $__ps_Values)))))
    (type $__ps_Closure (sub final $__ps_Value (struct
      (field $code funcref)
      (field $captures (ref $__ps_Values)))))
    (type $HPow (sub final $__ps_Value (struct
      (field $hPow (ref $__ps_Closure)))))
    (type $Pow (sub final $__ps_Value (struct
      (field $pow (ref $__ps_Closure)))))
    (type $NatPow (sub final $__ps_Value (struct
      (field $pow (ref $__ps_Closure)))))
    (type $HShiftLeft (sub final $__ps_Value (struct
      (field $hShiftLeft (ref $__ps_Closure)))))
    (type $HShiftRight (sub final $__ps_Value (struct
      (field $hShiftRight (ref $__ps_Closure)))))
    (type $ShiftLeft (sub final $__ps_Value (struct
      (field $shiftLeft (ref $__ps_Closure)))))
    (type $ShiftRight (sub final $__ps_Value (struct
      (field $shiftRight (ref $__ps_Closure)))))
    (type $OfScientific (sub final $__ps_Value (struct
      (field $ofScientific (ref $__ps_Closure)))))
    (type $Add (sub final $__ps_Value (struct
      (field $add (ref $__ps_Closure)))))
    (type $Sub (sub final $__ps_Value (struct
      (field $sub (ref $__ps_Closure)))))
    (type $Mul (sub final $__ps_Value (struct
      (field $mul (ref $__ps_Closure)))))
    (type $Div (sub final $__ps_Value (struct
      (field $div (ref $__ps_Closure)))))
    (type $Mod (sub final $__ps_Value (struct
      (field $mod (ref $__ps_Closure)))))
    (type $Append (sub final $__ps_Value (struct
      (field $append (ref $__ps_Closure)))))
    (type $Float_Model (sub final $__ps_Value (struct
      (field $toBits i64))))
    (type $Float32_Model (sub final $__ps_Value (struct
      (field $toBits i32))))
    (type $ByteArray (sub final $__ps_Value (struct
      (field $data (ref $__ps_Array)))))
    (type $Hashable (sub final $__ps_Value (struct
      (field $hash (ref $__ps_Closure)))))
    (type $BitVec (sub final $__ps_Value (struct
      (field $toFin (ref $Fin)))))
    (type $ReprTuple (sub final $__ps_Value (struct
      (field $reprTuple (ref $__ps_Closure)))))
    (type $Repr (sub final $__ps_Value (struct
      (field $reprPrec (ref $__ps_Closure)))))
    (type $ReprAtom (sub final $__ps_Value (struct)))
    (type $Std_ToFormat (sub final $__ps_Value (struct
      (field $format (ref $__ps_Closure)))))
    (type $_psc0Format_TextPrefix (sub final $__ps_Value (struct
      (field $position (ref $__ps_Natural))
      (field $columns (ref $__ps_Natural)))))
    (type $_psc0Format_SpaceResult (sub final $__ps_Value (struct
      (field $foundLine i32)
      (field $foundFlattenedHardLine i32)
      (field $space (ref $__ps_Natural)))))
    (type $_psc0Format_WorkItem (sub final $__ps_Value (struct
      (field $f (ref $Std_Format))
      (field $indent (ref $__ps_Integer)))))
    (type $_psc0Format_WorkGroup (sub final $__ps_Value (struct
      (field $fla (ref $Std_Format_FlattenAllowability))
      (field $flb (ref $Std_Format_FlattenBehavior))
      (field $items (ref $List)))))
    (type $_psc0Format_State (sub final $__ps_Value (struct
      (field $out (ref $__ps_String))
      (field $column (ref $__ps_Natural)))))
    (type $_psc0Format_Machine (sub final $__ps_Value (struct
      (field $groups (ref $List))
      (field $state (ref $_psc0Format_State)))))
    (type $Coe (sub final $__ps_Value (struct
      (field $coe (ref $__ps_Closure)))))
    (type $CoeSort (sub final $__ps_Value (struct
      (field $coe (ref $__ps_Closure)))))
    (type $OfNat (sub final $__ps_Value (struct
      (field $ofNat (ref $__ps_Value)))))
    (type $HAdd (sub final $__ps_Value (struct
      (field $hAdd (ref $__ps_Closure)))))
    (type $HSub (sub final $__ps_Value (struct
      (field $hSub (ref $__ps_Closure)))))
    (type $HMul (sub final $__ps_Value (struct
      (field $hMul (ref $__ps_Closure)))))
    (type $HDiv (sub final $__ps_Value (struct
      (field $hDiv (ref $__ps_Closure)))))
    (type $HMod (sub final $__ps_Value (struct
      (field $hMod (ref $__ps_Closure)))))
    (type $HAppend (sub final $__ps_Value (struct
      (field $hAppend (ref $__ps_Closure)))))
    (type $Neg (sub final $__ps_Value (struct
      (field $neg (ref $__ps_Closure)))))
    (type $BEq (sub final $__ps_Value (struct
      (field $beq (ref $__ps_Closure)))))
    (type $ToString (sub final $__ps_Value (struct
      (field $toString (ref $__ps_Closure)))))
    (type $Inhabited (sub final $__ps_Value (struct
      (field $default (ref $__ps_Value)))))
    (type $Prod (sub final $__ps_Value (struct
      (field $fst (ref $__ps_Value))
      (field $snd (ref $__ps_Value)))))
    (type $GetElem (sub final $__ps_Value (struct
      (field $getElem (ref $__ps_Closure)))))
    (type $GetElem_ (sub final $__ps_Value (struct
      (field $toGetElem (ref $GetElem))
      (field $getElem_ (ref $__ps_Closure))
      (field $getElem__ (ref $__ps_Closure)))))
    (type $Fin (sub final $__ps_Value (struct
      (field $val (ref $__ps_Natural)))))
    (type $PsKernelGcPair (sub final $__ps_Value (struct
      (field $left i32)
      (field $right i32))))
    (type $Sum (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_3_Sum_inl (sub final $Sum (struct
      (field $__ps_tag i32)
      (field $val (ref $__ps_Value)))))
    (type $__ps_constructor_3_Sum_inr (sub final $Sum (struct
      (field $__ps_tag i32)
      (field $val (ref $__ps_Value)))))
    (type $Std_Format_FlattenBehavior (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_26_Std_Format_FlattenBehavior_allOrNone (sub final $Std_Format_FlattenBehavior (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_26_Std_Format_FlattenBehavior_fill (sub final $Std_Format_FlattenBehavior (struct
      (field $__ps_tag i32))))
    (type $Std_Format (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_10_Std_Format_nil (sub final $Std_Format (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_10_Std_Format_line (sub final $Std_Format (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_10_Std_Format_align (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $force i32))))
    (type $__ps_constructor_10_Std_Format_text (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $text (ref $__ps_String)))))
    (type $__ps_constructor_10_Std_Format_nest (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $indent (ref $__ps_Integer))
      (field $f (ref $Std_Format)))))
    (type $__ps_constructor_10_Std_Format_append (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $left (ref $Std_Format))
      (field $right (ref $Std_Format)))))
    (type $__ps_constructor_10_Std_Format_group (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $f (ref $Std_Format))
      (field $behavior (ref $Std_Format_FlattenBehavior)))))
    (type $__ps_constructor_10_Std_Format_tag (sub final $Std_Format (struct
      (field $__ps_tag i32)
      (field $tag (ref $__ps_Natural))
      (field $f (ref $Std_Format)))))
    (type $Std_Format_FlattenAllowability (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_30_Std_Format_FlattenAllowability_allow (sub final $Std_Format_FlattenAllowability (struct
      (field $__ps_tag i32)
      (field $fits i32))))
    (type $__ps_constructor_30_Std_Format_FlattenAllowability_disallow (sub final $Std_Format_FlattenAllowability (struct
      (field $__ps_tag i32))))
    (type $Empty (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $List (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_4_List_nil (sub final $List (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_4_List_cons (sub final $List (struct
      (field $__ps_tag i32)
      (field $head (ref $__ps_Value))
      (field $tail (ref $List)))))
    (type $Option (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_6_Option_none (sub final $Option (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_6_Option_some (sub final $Option (struct
      (field $__ps_tag i32)
      (field $value (ref $__ps_Value)))))
    (type $Except (sub $__ps_Value (struct
      (field $__ps_tag i32))))
    (type $__ps_constructor_6_Except_error (sub final $Except (struct
      (field $__ps_tag i32)
      (field $error (ref $__ps_Value)))))
    (type $__ps_constructor_6_Except_ok (sub final $Except (struct
      (field $__ps_tag i32)
      (field $value (ref $__ps_Value)))))
    (type $__ps_Limbs (array (mut i32)))
    (type $__ps_Bytes (array (mut i8)))
    (type $__ps_Values (array (mut (ref $__ps_Value))))
  )
  (type $__ps_ClosureCode_1 (func (param (ref $__ps_Closure) (ref $__ps_Value)) (result (ref $__ps_Value))))
  (type $__ps_ClosureCode_2 (func (param (ref $__ps_Closure) (ref $__ps_Value) (ref $__ps_Value)) (result (ref $__ps_Value))))
  (type $signature0 (func (param (ref $PsKernelGcPair)) (result i32)))
  (type $signature1 (func (param (ref $PsKernelGcPair)) (result i32)))
  (type $signature2 (func (param i32 i32) (result i32)))
  (func $PsKernelGcPair_left (type $signature0) (param $self (ref $PsKernelGcPair)) (result i32)
    local.get $self
    struct.get $PsKernelGcPair 0
  )
  (func $PsKernelGcPair_right (type $signature1) (param $self (ref $PsKernelGcPair)) (result i32)
    local.get $self
    struct.get $PsKernelGcPair 1
  )
  (func $pskernelWasmGcProbe (type $signature2) (param $left i32) (param $right i32) (result i32)
    (local $left_ i32)
    (local $right_ i32)
    (local $cell (ref $PsKernelGcPair))
    local.get $left
    local.set $left_
    local.get $right
    local.set $right_
    local.get $left_
    local.get $right_
    struct.new $PsKernelGcPair
    local.set $cell
    local.get $cell
    struct.get $PsKernelGcPair 0
    i32.const 1
    i32.eq
    if (result i32)
      local.get $cell
      struct.get $PsKernelGcPair 1
    else
      i32.const 0
    end
  )
  (export "PsKernelGcPair.left" (func $PsKernelGcPair_left))
  (export "PsKernelGcPair.right" (func $PsKernelGcPair_right))
  (export "pskernelWasmGcProbe" (func $pskernelWasmGcProbe))
)
