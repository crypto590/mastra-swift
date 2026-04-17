# Security Policy

## Supported Versions

`mastra-swift` is pre-1.0 and under active development. Security fixes are
applied to the latest `0.x` release only.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security problems.**

Report privately via one of the following:

- Email: corey@coreywyoung.com
- GitHub: [private vulnerability report](https://github.com/crypto590/mastra-swift/security/advisories/new)

Please include:

- A description of the issue and its impact
- Steps to reproduce (minimal repro preferred)
- Affected version(s) and platform(s)
- Your contact for follow-up

You can expect an initial response within 5 business days. Fixes for
confirmed issues are coordinated before public disclosure; we will agree on
a disclosure timeline with the reporter.

## Scope

In scope:

- The `Mastra` library target under `Sources/Mastra/`
- The `MastraTestingSupport` target
- Build and CI configuration in this repository

Out of scope:

- Vulnerabilities in the upstream Mastra server or `@mastra/client-js` —
  report those to the [Mastra project](https://github.com/mastra-ai/mastra)
- Third-party transports or extensions not maintained here
