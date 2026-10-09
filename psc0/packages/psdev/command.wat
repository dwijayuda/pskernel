;; psc-command/1: request the supervisor's selected checked build on initial event 0.
;; The prepared command.wasm is checked against its exact bytes/hash in Actions.
(module
  (func (export "psc_event") (param $event i32) (result i32)
    local.get $event
    i32.eqz))
