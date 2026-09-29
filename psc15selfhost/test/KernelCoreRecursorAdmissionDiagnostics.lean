import KernelCoreRecursorAdmissionParityTests

def main : IO Unit := do
  if psKcRecursorAdmissionPositive then
    IO.println "PHASE10_ADMISSION_POSITIVE=PASS"
  else
    IO.println "PHASE10_ADMISSION_POSITIVE=FAIL"
  if psKcZeroConstructorRecursor then
    IO.println "PHASE10_ADMISSION_EMPTY=PASS"
  else
    IO.println "PHASE10_ADMISSION_EMPTY=FAIL"
  if psRefRecursorAdmissionPositive then
    IO.println "PHASE10_ADMISSION_REFERENCE=PASS"
  else
    IO.println "PHASE10_ADMISSION_REFERENCE=FAIL"
