# rust-standards

Coding standards for Rust projects covering error handling and test conventions.

- **`anyhow` scope** — restrict `anyhow` to binary crates; library code must use typed errors
- **Result type aliases** — every custom error type should have a paired `Result<T, E>` alias
- **Test naming** — descriptive names, no `test_` prefix
- **Async test timing** — use check-delay-retry loops instead of sleeps

See `SKILL.md` for the full standards with examples.
