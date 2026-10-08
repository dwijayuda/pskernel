import Std.WP

set_option experimental.intrinsic true
set_option experimental.vcgen true

def impossibleContract (x : Nat) : Except String Nat
  requires True
  ensures result => result ≠ x
  := pure x
