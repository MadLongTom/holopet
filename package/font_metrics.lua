local FontMetrics = {}

-- stb_truetype maps the requested size to the font em square, while the
-- visible line box comes from hhea ascent/descent. Noto Sans SC therefore
-- renders taller than Clawd Console at the same nominal size:
--
--   Clawd Console  (1900 - -480) / 2048 = 1.1621 em
--   Noto Sans SC   (1160 - -288) / 1000 = 1.4480 em
--
-- Normalize the Chinese raster size to the English line box. Keeping this in
-- the app layer avoids changing the shared AIDA font module or UI geometry.
local EN_ASCENT = 1900
local EN_DESCENT = -480
local EN_UNITS_PER_EM = 2048
local ZH_ASCENT = 1160
local ZH_DESCENT = -288
local ZH_UNITS_PER_EM = 1000

local EN_LINE_EM = (EN_ASCENT - EN_DESCENT) / EN_UNITS_PER_EM
local ZH_LINE_EM = (ZH_ASCENT - ZH_DESCENT) / ZH_UNITS_PER_EM

FontMetrics.CJK_SCALE = EN_LINE_EM / ZH_LINE_EM

local function rounded(value)
  return math.floor(value + 0.5)
end

local function baseline(size, ascent, units_per_em)
  return math.ceil(size * ascent / units_per_em)
end

function FontMetrics.role(size, fallback, is_zh)
  local nominal = math.max(6, math.floor(tonumber(size) or 12))
  local render_size = nominal
  local y_offset = 0

  if is_zh then
    render_size = math.max(6, rounded(nominal * FontMetrics.CJK_SCALE))
    y_offset = baseline(nominal, EN_ASCENT, EN_UNITS_PER_EM)
      - baseline(render_size, ZH_ASCENT, ZH_UNITS_PER_EM)
  end

  return {
    size = nominal,
    render_size = render_size,
    y_offset = y_offset,
    fallback = fallback,
  }
end

return FontMetrics
