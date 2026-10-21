#!/usr/bin/env bash
# CI-only bootstrap. Retries downloads; never substitutes a toolchain or skips gates.
set -euo pipefail
PSC1_LEAN_PIN=leanprover/lean4:v4.35.0
PSC1_LEAN_COMMIT=eb6cafb7290e8bd5f2937522d8d804f58f02bafc
PSC1_INSTALL_SCRIPT="${RUNNER_TEMP:?}/psc1-elan-init.sh"

psc1_retry() {
  local psc1_attempt
  for psc1_attempt in 1 2 3; do
    if "$@"; then return 0; fi
    if [ "$psc1_attempt" -lt 3 ]; then
      echo "Pinned-toolchain infrastructure retry $psc1_attempt/3" >&2
      sleep "$((psc1_attempt * 2))"
    fi
  done
  return 1
}

psc1_retry curl -sSfL --connect-timeout 30 --max-time 120 \
  https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
  -o "$PSC1_INSTALL_SCRIPT"
psc1_retry sh "$PSC1_INSTALL_SCRIPT" -y --default-toolchain none
psc1_retry "$HOME/.elan/bin/elan" toolchain install "$PSC1_LEAN_PIN"
test "$("$HOME/.elan/bin/elan" run "$PSC1_LEAN_PIN" lean --githash)" = "$PSC1_LEAN_COMMIT"
echo "$HOME/.elan/bin" >> "${GITHUB_PATH:?}"
echo "PSC1_PINNED_LEAN_INSTALLED $PSC1_LEAN_PIN $PSC1_LEAN_COMMIT"
