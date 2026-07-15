local FontMetrics = dofile("package/font_metrics.lua")

local function equal(actual, expected, message)
  assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

assert(FontMetrics.CJK_SCALE > 0.80 and FontMetrics.CJK_SCALE < 0.81, "CJK metric scale")

local expected = {
  [10] = { render_size = 8, y_offset = 0 },
  [12] = { render_size = 10, y_offset = 0 },
  [14] = { render_size = 11, y_offset = 0 },
  [16] = { render_size = 13, y_offset = -1 },
  [28] = { render_size = 22, y_offset = 0 },
}

for size, calibration in pairs(expected) do
  local zh = FontMetrics.role(size, "fallback", true)
  equal(zh.size, size, "Chinese nominal size " .. size)
  equal(zh.render_size, calibration.render_size, "Chinese raster size " .. size)
  equal(zh.y_offset, calibration.y_offset, "Chinese baseline " .. size)
  equal(zh.fallback, "fallback", "Chinese fallback " .. size)

  local en = FontMetrics.role(size, "fallback", false)
  equal(en.size, size, "English nominal size " .. size)
  equal(en.render_size, size, "English raster size " .. size)
  equal(en.y_offset, 0, "English baseline " .. size)
end

print("font metric tests passed")
