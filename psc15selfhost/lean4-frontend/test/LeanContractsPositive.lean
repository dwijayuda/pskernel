import Std.WP

set_option experimental.intrinsic true

def checkedIdentity (x : Nat) : Nat
  requires True
  ensures result => result = x
  := x

#check checkedIdentity.spec
