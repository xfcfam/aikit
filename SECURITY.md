# Security Policy

## Supported versions

This repository contains the **xfcfam/aikit** Claude plugin —
instructions, skills, and the plugin manifest that ship to Claude
users. Only the latest published version receives security updates.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| older   | :x:                |

## Reporting a vulnerability

Plugins for AI assistants can be a security-sensitive surface. We
particularly want to hear about:

- **Prompt-injection vectors** in the bundled instructions or skills
  that could cause Claude to take harmful actions on a user's behalf.
- **Skills that mishandle untrusted input** (file contents, web pages,
  user-provided arguments).
- **Excessive permissions** requested by the plugin manifest.
- **Supply-chain issues** with the CI workflows or with assets the
  plugin downloads at install time.

**Please do not file a public GitHub issue for security reports.**

Use one of:

1. **GitHub private vulnerability reporting** (preferred) — repository
   **Security** tab → **"Report a vulnerability"**. Private to the
   maintainers.
2. **Email** — `security@xfcfam.org` (PGP key on request).

We aim to acknowledge reports within **72 hours** and provide an
initial assessment within **7 days**. Fixes are coordinated with the
reporter before public disclosure; reporters are credited unless they
ask to remain anonymous.

## Scope

In scope:

- `plugin.json` (manifest, permissions, declared MCPs).
- Anything under `skills/` and `instructions/`.
- The GitHub Actions workflows that publish or validate the plugin.

Out of scope:

- Vulnerabilities in Claude itself — report those to Anthropic.
- Issues in upstream MCPs referenced by the plugin — report to the MCP
  authors, then notify us if our wiring exposes them.
