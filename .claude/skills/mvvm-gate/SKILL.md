---
name: mvvm-gate
description: Run the full project quality gate (build_runner, analyze, import boundaries, 200-LOC check, tests) and report pass/fail.
---

Run the project quality gate and report the result of each step:

    dart run tool/gate.dart

- If it prints `GATE PASSED` (exit 0), confirm the gate is green.
- Otherwise, identify exactly which step failed from the output, summarise the errors, and fix them — then run the gate again. Do not stop until it is green.
