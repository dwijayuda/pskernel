#!/usr/bin/env bash
# CI tooling only; never runs project proofs/tests on the local host.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = true
test "${RUNNER_OS:-}" = Linux
: "${RUNNER_TEMP:?}" "${GITHUB_PATH:?}"
if [ ! -x "$HOME/.elan/bin/elan" ]; then
  for elan_attempt in 1 2 3; do
    if curl --fail --show-error --location --connect-timeout 15 --max-time 60 \
        https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
        -o "$RUNNER_TEMP/psc1-elan-init.sh" &&
        timeout 60 sh "$RUNNER_TEMP/psc1-elan-init.sh" -y; then
      break
    fi
  done
  test -x "$HOME/.elan/bin/elan"
fi
"$HOME/.elan/bin/elan" --version
echo "$HOME/.elan/bin" >> "$GITHUB_PATH"
