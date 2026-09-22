import { nameFromDotted, numName, strName } from '../core/name.js';
const natBitwisePrivateBase=numName(nameFromDotted('_private.Init.Data.Nat.Bitwise.Basic'),0);
const natBitwiseUnaryProof1=strName(strName(strName(natBitwisePrivateBase,'Nat'),'bitwise'),'_unary');
const NatBitwiseUnaryProof1=strName(natBitwiseUnaryProof1,'_proof_1');

export const N={
 Nat:nameFromDotted('Nat'),NatZero:nameFromDotted('Nat.zero'),NatSucc:nameFromDotted('Nat.succ'),NatAdd:nameFromDotted('Nat.add'),NatSub:nameFromDotted('Nat.sub'),NatMul:nameFromDotted('Nat.mul'),NatPow:nameFromDotted('Nat.pow'),NatPred:nameFromDotted('Nat.pred'),NatGcd:nameFromDotted('Nat.gcd'),NatMod:nameFromDotted('Nat.mod'),NatDiv:nameFromDotted('Nat.div'),NatBeq:nameFromDotted('Nat.beq'),NatBle:nameFromDotted('Nat.ble'),NatBitwise:nameFromDotted('Nat.bitwise'),NatBitwiseRecLemma:nameFromDotted('Nat.bitwise_rec_lemma'),NatBitwiseUnaryProof1,NatLand:nameFromDotted('Nat.land'),NatLor:nameFromDotted('Nat.lor'),NatXor:nameFromDotted('Nat.xor'),NatShiftLeft:nameFromDotted('Nat.shiftLeft'),NatShiftRight:nameFromDotted('Nat.shiftRight'),
 Bool:nameFromDotted('Bool'),BoolFalse:nameFromDotted('Bool.false'),BoolTrue:nameFromDotted('Bool.true'),BoolRec:nameFromDotted('Bool.rec'),BoolDecEq:nameFromDotted('Bool.decEq'),
 Ite:nameFromDotted('ite'),Dite:nameFromDotted('dite'),Not:nameFromDotted('Not'),False:nameFromDotted('False'),
 Decidable:nameFromDotted('Decidable'),DecidableIsTrue:nameFromDotted('Decidable.isTrue'),DecidableIsFalse:nameFromDotted('Decidable.isFalse'),
 LE:nameFromDotted('LE'),LELe:nameFromDotted('LE.le'),InstLENat:nameFromDotted('instLENat'),NatDecLe:nameFromDotted('Nat.decLe'),NatLeOfBleTrue:nameFromDotted('Nat.le_of_ble_eq_true'),NatNotLeOfNotBleTrue:nameFromDotted('Nat.not_le_of_not_ble_eq_true'),NatDecEq:nameFromDotted('Nat.decEq'),NatEqOfBeqTrue:nameFromDotted('Nat.eq_of_beq_eq_true'),NatNeOfBeqFalse:nameFromDotted('Nat.ne_of_beq_eq_false'),NatModCoreGo:nameFromDotted('Nat.modCore.go'),NatDivGo:nameFromDotted('Nat.div.go'),NatDivRecFuelLemma:nameFromDotted('Nat.div_rec_fuel_lemma'),NatLtSuccSelf:nameFromDotted('Nat.lt_succ_self'),
 String:nameFromDotted('String'),Char:nameFromDotted('Char'),List:nameFromDotted('List'),ListNil:nameFromDotted('List.nil'),ListCons:nameFromDotted('List.cons'),StringOfList:nameFromDotted('String.ofList'),CharOfNat:nameFromDotted('Char.ofNat'),
 Eq:nameFromDotted('Eq'),EqRefl:nameFromDotted('Eq.refl'),
 Quot:nameFromDotted('Quot'),QuotMk:nameFromDotted('Quot.mk'),QuotLift:nameFromDotted('Quot.lift'),QuotInd:nameFromDotted('Quot.ind'),
 WfNatFix:nameFromDotted('WellFounded.Nat.fix'),WfNatFixGo:nameFromDotted('WellFounded.Nat.fix.go'),WfNatEager:nameFromDotted('WellFounded.Nat.eager'),
 EagerReduce:nameFromDotted('eagerReduce'),
 AccRec:nameFromDotted('Acc.rec'),AccIntro:nameFromDotted('Acc.intro')
} as const;
