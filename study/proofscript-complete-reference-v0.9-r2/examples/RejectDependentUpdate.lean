import Init
structure SizedData where
  n : Nat
  data : Fin n → Nat
def invalid (s : SizedData) : SizedData := { s with n := s.n + 1 }
