# Supabase Assessment and Architecture Decision

**Status:** Not needed for the portable OS core  
**Reviewed:** 2026-10-12  
**Scope:** Protable-Linux

## Decision summary

Keep the USB-based portable operating system independent of Supabase. Boot, persistence, local files/settings, recovery, and installation must work offline and must not depend on cloud authentication or network availability.

The connected Supabase account currently lists no projects. No project, deployment, user data, or OS configuration was changed.

## Possible optional future uses

A future opt-in companion service could publish update metadata or an online catalog, but only if it has a concrete benefit. It must not be required for boot, persistence, updates to the local system, or recovery. Any telemetry must be opt-in, documented, minimized, and easy to disable.

## Acceptance gate

Require a clear use case, privacy/security review, cost comparison, offline/failure tests, and proof that persistence, UEFI boot, and recovery behavior are unaffected. Do not add cloud credentials to the image or expose privileged operations through a cloud backend.

## Changelog

- 2026-10-12: Added initial assessment; no OS, persistence, boot, or infrastructure changes.
