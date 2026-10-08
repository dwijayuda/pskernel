import Std.WP

set_option experimental.intrinsic true
set_option experimental.vcgen true

-- Lean's intrinsic contract infrastructure expects a registered WP computation.
def checkedIdentity (x : Nat) : Except String Nat
  requires True
  ensures result => result = x
  := pure x

#check checkedIdentity.spec
