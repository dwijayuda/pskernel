import Std.WP

set_option experimental.intrinsic true

def impossibleContract (x : Nat) : Nat
  requires True
  ensures result => result ≠ x
  := x
