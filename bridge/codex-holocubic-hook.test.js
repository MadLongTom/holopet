"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  buildStatus,
  displayTool,
  projectFromCwd,
  responseLooksFailed,
} = require("./codex-holocubic-hook");
const { buildStartupCommand, upsertHookEntry } = require("./install-codex-hook");
const { EVENTS } = require("./install-codex-hook");

test("maps Codex lifecycle events without leaking prompt text", () => {
  const status = buildStatus({
    hook_event_name: "UserPromptSubmit",
    cwd: "E:\\holocubic",
    session_id: "session-1",
    model: "gpt-test",
    prompt: "private prompt",
  });
  assert.equal(status.state, "thinking");
  assert.equal(status.project, "holocubic");
  assert.equal(status.prompt, undefined);
});

test("normalizes tool names for the tiny display", () => {
  assert.equal(displayTool("Bash"), "terminal");
  assert.equal(displayTool("apply_patch"), "edit");
  assert.equal(displayTool("mcp__filesystem__read_file"), "filesystem__read_file");
});

test("detects failed tool responses", () => {
  assert.equal(responseLooksFailed({ exit_code: 1 }), true);
  assert.equal(responseLooksFailed({ success: false }), true);
  assert.equal(responseLooksFailed({ exit_code: 0 }), false);
});

test("covers every Codex hook event documented by the installed release", () => {
  assert.deepEqual(EVENTS, [
    "SessionStart", "UserPromptSubmit", "PreToolUse", "PermissionRequest",
    "PostToolUse", "PreCompact", "PostCompact", "SubagentStart", "SubagentStop", "Stop",
  ]);
  assert.equal(buildStatus({ hook_event_name: "PreCompact" }).state, "working");
  assert.equal(buildStatus({ hook_event_name: "PostCompact" }).state, "thinking");
});

test("handles Windows and POSIX project paths", () => {
  assert.equal(projectFromCwd("E:\\work\\demo"), "demo");
  assert.equal(projectFromCwd("/home/me/demo/"), "demo");
});

test("builds a hidden Windows startup command with quoted paths", () => {
  const command = buildStartupCommand("C:\\Program Files\\nodejs\\node.exe", "E:\\holo pet\\server.js");
  assert.match(command, /-WindowStyle Hidden/);
  assert.match(command, /'C:\\Program Files\\nodejs\\node\.exe'/);
  assert.match(command, /'E:\\holo pet\\server\.js'/);
});

test("migrates managed hook entries from an old repository path", () => {
  const userEntry = { hooks: [{ type: "command", command: "custom-hook" }] };
  const oldEntry = { hooks: [{ type: "command", command: "node /old/codex-holocubic-hook.js" }] };
  const desired = { hooks: [{ type: "command", command: "node /new/codex-holocubic-hook.js" }] };
  const result = upsertHookEntry([userEntry, oldEntry], desired);
  assert.equal(result.changed, true);
  assert.equal(result.added, false);
  assert.deepEqual(result.entries, [userEntry, desired]);
  assert.equal(upsertHookEntry(result.entries, desired).changed, false);
});
