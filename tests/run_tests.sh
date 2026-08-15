#!/bin/bash
# Runs the whole test suite. No dependencies beyond bash + coreutils.
#   ./tests/run_tests.sh
cd "$(dirname "$0")" || exit 1

failed=0
for file in test_*.sh; do
  bash "$file" || failed=1
  echo
done

if [ "$failed" -ne 0 ]; then
  echo "TEST SUITE FAILED"
  exit 1
fi
echo "TEST SUITE PASSED"
