"use strict";

const WEEKLY_WINDOW_MINUTES = 7 * 24 * 60;

function field(value, snake, camel) {
  return value?.[snake] ?? value?.[camel] ?? null;
}

function resetDateText(epochSeconds) {
  const seconds = Number(epochSeconds);
  if (!Number.isFinite(seconds) || seconds <= 0) return "--/--";
  const date = new Date(seconds * 1000);
  return `${String(date.getMonth() + 1).padStart(2, "0")}/${String(date.getDate()).padStart(2, "0")}`;
}

function normalizeUsage(limits, sampledAt) {
  if (!limits || typeof limits !== "object") return null;
  const windows = [limits.primary, limits.secondary].filter(Boolean);
  const weekly = windows.find((item) => (
    Number(field(item, "window_minutes", "windowDurationMins")) === WEEKLY_WINDOW_MINUTES
  ));
  if (!weekly) return null;

  const rawPercent = field(weekly, "used_percent", "usedPercent");
  const weeklyPercent = Number(rawPercent);
  if (rawPercent === null || !Number.isFinite(weeklyPercent)) return null;
  const resetAt = Number(field(weekly, "resets_at", "resetsAt")) || 0;

  return {
    weekly_percent: weeklyPercent,
    weekly_resets_at: resetAt,
    weekly_reset_text: resetDateText(resetAt),
    limit_id: String(field(limits, "limit_id", "limitId") || ""),
    limit_name: String(field(limits, "limit_name", "limitName") || ""),
    sampled_at: Number(sampledAt) || Date.now(),
  };
}

module.exports = {
  WEEKLY_WINDOW_MINUTES,
  normalizeUsage,
  resetDateText,
};
