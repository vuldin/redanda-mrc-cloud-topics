// Passthrough Data Transform: copies records from regional topics to perf-global.
// Deployed per-region: consumes from perf-us/perf-eu/perf-ap, produces to perf-global.
// Runs in-broker on the Raft leader core — no extra network hops.

use redpanda_transform_sdk::*;

fn main() {
    on_record_written(passthrough);
}

fn passthrough(event: WriteEvent, writer: &mut RecordWriter) -> Result<(), Box<dyn std::error::Error>> {
    let record = event.record;
    writer.write_with_options(
        record,
        WriteOptions::new().with_topic("perf-global"),
    )?;
    Ok(())
}
