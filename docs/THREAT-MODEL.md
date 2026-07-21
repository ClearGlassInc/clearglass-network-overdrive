# Threat model

System owner: ClearGlassInc. Founder and principal author: Desmond Otieno Odhiambo.

## Assets

Administrator authority, network configuration, rollback state, audit events, policy configuration, release artifacts, and operator trust.

## Trust boundaries

Untrusted inputs include imported evidence, adapter metadata, configuration changes, external model output, pull-request code, and dependency packages. Trusted execution is limited to reviewed source on the protected default branch, the fixed command allowlist, Windows privilege checks, and explicitly approved operator actions.

## Primary threats and controls

- Arbitrary command execution: intelligence emits data only; execution accepts a fixed allowlist.
- Privilege escalation: Apply and Rollback require an existing administrator context and never acquire credentials.
- Unsafe tuning: high-risk universal settings are excluded by policy.
- Prompt injection: external AI is disabled; future output must validate against a versioned schema and cannot authorize execution.
- Supply-chain compromise: least-privilege workflow permissions, pinned tool versions, code ownership, static analysis, and tests.
- Silent regression: baseline scoring, canary rollout, circuit breaker, audit events, and rollback.
- Evidence tampering: versioned records and correlation identifiers; signed artifacts and append-only remote storage remain future work.
- Secret exposure: no secrets in source, logs, recommendations, issues, or test fixtures.
- Denial of service: bounded workflow duration, action limits, run intervals, and failure thresholds.
- Unauthorized access: no feature bypasses authentication, repository permissions, endpoint policy, or network access controls.

## Residual risks

Rollback currently restores documented safe defaults instead of parsing and restoring every original TCP value. Local audit files are not cryptographically sealed. PowerShell Gallery installation remains an external supply-chain dependency. These gaps must be closed before fleet-wide or regulated deployment.

## Release gate

A release is blocked unless tests pass, static analysis passes, the manifest validates, source ownership is explicit, no secret is detected, rollback behavior is verified on a Windows canary, and the operator approves the measured result.
