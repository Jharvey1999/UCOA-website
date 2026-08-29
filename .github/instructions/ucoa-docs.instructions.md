---
name: UCOA Documentation
description: "Use when editing README.md or docs/**/*.md for the UCOA plan, migration, legacy source inventory, security, or construction history."
applyTo: ["README.md", "docs/**/*.md"]
---
# UCOA Documentation Guidelines

- Keep [docs/planning/PLAN.md](../../docs/planning/PLAN.md) as the implementation source of truth and link to it instead of duplicating the entire plan.
- Keep README.md useful as the project entry point: state current status, MVP scope, stack, security boundary, and links to the detailed docs.
- Time-stamp external research and distinguish observed facts, decisions, assumptions, and open questions.
- Treat Meetup, Instagram, Campsite.bio, Discord, Jotform, and Google Forms as changeable external sources, not application databases.
- Never place member exports, private form responses, passwords, tokens, banking information, or emergency-contact data in documentation.
- When a source conflicts with repository text, record the conflict and required owner verification instead of silently selecting a value.
- Keep implementation steps, acceptance checks, and open decisions close to the document that owns them.
- Update docs/HISTORY/project-construction-timeline.md when an architectural decision or milestone is completed.
- Use ASCII unless an existing source requires another character set. Preserve concise headings and stable relative links.
