---
name: rust-standards
description: "Coding standards for Rust projects. Apply when writing or reviewing Rust code. Covers error handling (anyhow scope, thiserror conventions, Result type aliases), test naming, and async test patterns. Triggers on any Rust coding task in a project using these conventions."
---

# Rust Coding Standards

Project-specific standards for Rust code. Apply these when writing new code or reviewing existing code.

## Error Handling

### `anyhow` scope

`anyhow` is permitted only in code that compiles directly into a binary (i.e. `main.rs` and modules reachable only from binary entry points). It must not be used in library code.

**Why:** `anyhow::Error` is opaque and erases the original error type. Library consumers cannot match on it or handle specific variants — they are effectively forced to adopt `anyhow` themselves, which constrains downstream integrations.

```rust
// ✅ Binary code (src/main.rs, src/bin/*.rs)
use anyhow::Result;
fn main() -> Result<()> { ... }

// ❌ Library code (src/lib.rs, any public module)
pub fn parse_config(path: &Path) -> anyhow::Result<Config> { ... }

// ✅ Library code — use a typed error
pub fn parse_config(path: &Path) -> Result<Config, ConfigError> { ... }
```

### Custom error types

When defining a custom error type — whether manually or with `thiserror` — always define a corresponding `Result` type alias immediately after it:

```rust
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("file not found: {0}")]
    NotFound(PathBuf),
    #[error("invalid format: {0}")]
    InvalidFormat(String),
}

pub type ConfigResult<T> = Result<T, ConfigError>;
```

This keeps function signatures concise and makes the error type implicit at the call site:

```rust
// ✅
pub fn load(path: &Path) -> ConfigResult<Config> { ... }

// ✗ Verbose, but acceptable if no alias exists yet
pub fn load(path: &Path) -> Result<Config, ConfigError> { ... }
```

The alias should live in the same module as the error type and be exported at the same visibility level.

## Tests

### Naming

Test function names must describe what is being tested, concisely. Do not prefix test names with `test_` — the `#[test]` attribute already marks them as tests, and the prefix adds noise without value.

```rust
// ✅
#[test]
fn empty_input_returns_error() { ... }

#[test]
fn config_loads_from_valid_file() { ... }

// ❌
#[test]
fn test_empty_input() { ... }

#[test]
fn test_config() { ... }
```

A good name reads as a sentence fragment describing the expected behaviour: `empty_input_returns_error`, `duplicate_key_is_rejected`, `connection_retries_on_timeout`.

### Async test timing

Do not use `tokio::time::sleep` or `std::thread::sleep` in tests to wait for a condition to become true. Sleep-based waits are fragile (they either wait too long under normal conditions or fail under load) and slow the test suite unnecessarily.

**Instead, use a check-delay-retry loop with a timeout:**

```rust
async fn wait_for<F, Fut>(mut condition: F, timeout: Duration) -> bool
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = bool>,
{
    let deadline = tokio::time::Instant::now() + timeout;
    let poll_interval = Duration::from_millis(10);
    loop {
        if condition().await {
            return true;
        }
        if tokio::time::Instant::now() >= deadline {
            return false;
        }
        tokio::time::sleep(poll_interval).await;
    }
}

// Usage in a test
assert!(wait_for(|| async { server.is_ready().await }, Duration::from_secs(5)).await);
```

This pattern keeps tests fast in the common case (condition met quickly) and reliable under load (retries up to the timeout rather than failing on a single missed window).

**Exceptions:** A sleep may be used when the test is explicitly validating timing behaviour (e.g. verifying that a timeout fires after the expected duration). In such cases, add a comment explaining why a sleep is appropriate.

```rust
// Verifying that the cache entry expires after its TTL.
// A sleep is necessary here because we are testing time-dependent behaviour.
tokio::time::sleep(TTL + Duration::from_millis(50)).await;
assert!(cache.get(&key).await.is_none());
```
