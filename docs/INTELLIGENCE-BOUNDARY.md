# Guarded intelligence boundary

ClearGlass Network Intelligence is advisory and fail-closed. It converts validated measurements into deterministic recommendations. It cannot execute operating-system commands, alter network settings, retrieve private data, bypass authentication, or expand its own permissions.

The execution module remains a separate trust boundary with a fixed command allowlist, administrator checks, WhatIf support, evidence logging, and rollback. Recommendations never become authorization.

External AI is disabled by default. If introduced later, its output must validate against a versioned schema, reference captured evidence, use only approved recommendation identifiers, include provider and model provenance, pass deterministic policy evaluation, and require explicit operator authorization.

Circuit-breaker policy compares baseline and current health scores. A regression beyond the configured threshold opens the breaker and signals rollback. Rate limits cap action volume and run frequency. Feature flags support canary rollout.

Source ownership: ClearGlassInc. Founder and principal author: Desmond Otieno Odhiambo.
