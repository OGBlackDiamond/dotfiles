---
name: add_memory
description: "Use when asked to remember, save, or update durable information about Caden, preferences, projects, or decisions in MEMORY.md."
---

# Add Memory

`MEMORY.md` is public and managed by chezmoi. Treat its privacy boundary as mandatory.

## Before Adding

1. Read `~/.config/opencode/MEMORY.md` first to avoid duplicates and preserve its structure.
2. Add only durable, useful context: stable preferences, long-lived goals, public-safe project summaries, recurring workflow constraints, or decisions likely to matter in future sessions.
3. Do not add temporary task state, unverified claims, chat transcripts, credentials, personal contact details, IP addresses, hostnames, private repository information, family or friend information, physical locations, or other confidential data.
4. Private projects are excluded unless Caden explicitly approves the exact public-safe wording to store.

## Update Procedure

1. Edit the chezmoi source of truth at `~/.local/share/chezmoi/dot_config/opencode/MEMORY.md`, using the smallest accurate update.
2. Apply only the managed target with `chezmoi apply ~/.config/opencode/MEMORY.md`.
3. Run `chezmoi diff ~/.config/opencode/MEMORY.md` to confirm the source and deployed file are synchronized.
4. Briefly report what was added and why it is suitable for long-term public memory.

Never edit only the deployed `~/.config/opencode/MEMORY.md`; that would be overwritten by chezmoi and would not be tracked.
