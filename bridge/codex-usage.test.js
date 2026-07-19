"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeUsage, resetDateText } = require("./codex-usage");

test("reads the current weekly-only primary window", () => {
  const reset = 1784982710;
  const usage = normalizeUsage({
    limit_id: "codex",
    primary: { used_percent: 2, window_minutes: 10080, resets_at: reset },
    secondary: null,
  }, 1234);
  assert.deepEqual(usage, {
    weekly_percent: 2,
    weekly_resets_at: reset,
    weekly_reset_text: resetDateText(reset),
    limit_id: "codex",
    limit_name: "",
    sampled_at: 1234,
  });
});

test("keeps compatibility with legacy telemetry where weekly was secondary", () => {
  const usage = normalizeUsage({
    limitId: "codex",
    primary: { usedPercent: 61, windowDurationMins: 300, resetsAt: 100 },
    secondary: { usedPercent: 17, windowDurationMins: 10080, resetsAt: 200 },
  }, 300);
  assert.equal(usage.weekly_percent, 17);
  assert.equal(usage.weekly_resets_at, 200);
  assert.equal(usage.five_hour_percent, undefined);
});

test("ignores non-weekly windows and invalid percentages", () => {
  assert.equal(normalizeUsage({ primary: { used_percent: 3, window_minutes: 300 } }), null);
  assert.equal(normalizeUsage({ primary: { used_percent: "bad", window_minutes: 10080 } }), null);
  assert.equal(resetDateText(null), "--/--");
});
