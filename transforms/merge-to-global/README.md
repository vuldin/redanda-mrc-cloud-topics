# merge-to-global Data Transform

Passthrough WASM Data Transform that copies records from regional perf topics
(`perf-us`, `perf-eu`, `perf-ap`) to the `perf-global` merged topic.

## Build

```bash
# Install the Rust WASM target
rustup target add wasm32-wasip1

# Build
cargo build --release --target wasm32-wasip1

# The WASM binary will be at:
# target/wasm32-wasip1/release/merge_to_global.wasm
```

## Deploy

Deploy one transform instance per regional topic:

```bash
rpk transform deploy target/wasm32-wasip1/release/merge_to_global.wasm \
  --name merge-us-to-global \
  --input-topic perf-us \
  --output-topic perf-global

rpk transform deploy target/wasm32-wasip1/release/merge_to_global.wasm \
  --name merge-eu-to-global \
  --input-topic perf-eu \
  --output-topic perf-global

rpk transform deploy target/wasm32-wasip1/release/merge_to_global.wasm \
  --name merge-ap-to-global \
  --input-topic perf-ap \
  --output-topic perf-global
```

## Verify

```bash
rpk transform list
rpk topic consume perf-global --num 5
```

## Cleanup

```bash
rpk transform delete merge-us-to-global
rpk transform delete merge-eu-to-global
rpk transform delete merge-ap-to-global
```
