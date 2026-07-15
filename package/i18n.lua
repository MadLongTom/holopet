local I18n = {}

local DEFAULT_LANGUAGE = "zh-CN"

local function read_text(path)
  if not file then return nil end
  if file.getcontents then
    local ok, value = pcall(file.getcontents, path)
    if ok and type(value) == "string" then return value end
  end
  if not file.open then return nil end
  local fd = file.open(path, "r")
  if not fd then return nil end
  local chunks = {}
  while true do
    local part = fd:read(512)
    if not part or part == "" then break end
    chunks[#chunks + 1] = part
  end
  fd:close()
  return table.concat(chunks)
end

function I18n.normalize(value)
  local text = tostring(value or ""):gsub("_", "-"):lower()
  if text == "en" or text:match("^en%-") then return "en" end
  if text == "zh" or text:match("^zh%-") then return "zh-CN" end
  return DEFAULT_LANGUAGE
end

function I18n.read(path)
  local raw = read_text(path)
  if type(raw) ~= "string" or raw == "" then return DEFAULT_LANGUAGE end

  local codec = rawget(_G, "json") or rawget(_G, "sjson")
  if codec and codec.decode then
    local ok, doc = pcall(codec.decode, raw)
    if ok and type(doc) == "table" then
      return I18n.normalize(doc.language or doc.locale or doc.lang)
    end
  end

  local value = raw:match('"language"%s*:%s*"([^"]+)"')
    or raw:match('"locale"%s*:%s*"([^"]+)"')
    or raw:match('"lang"%s*:%s*"([^"]+)"')
  return I18n.normalize(value)
end

function I18n.is_zh(language)
  return I18n.normalize(language) == "zh-CN"
end

function I18n.normalize_mode(value)
  local text = tostring(value or ""):gsub("_", "-"):lower()
  if text == "en" or text:match("^en%-") then return "en" end
  if text == "zh" or text:match("^zh%-") then return "zh-CN" end
  return "system"
end

function I18n.resolve(mode, system_language)
  local normalized = I18n.normalize_mode(mode)
  if normalized == "system" then return I18n.normalize(system_language) end
  return normalized
end

function I18n.pick(language, en, zh)
  return I18n.is_zh(language) and zh or en
end

local function utf8_span(text, index)
  local lead = text:byte(index)
  if not lead or lead < 0x80 then return 1 end
  local length = lead >= 0xF0 and lead <= 0xF4 and 4
    or lead >= 0xE0 and lead <= 0xEF and 3
    or lead >= 0xC2 and lead <= 0xDF and 2
    or 1
  if index + length - 1 > #text then return 1 end
  for offset = 1, length - 1 do
    local byte = text:byte(index + offset)
    if not byte or byte < 0x80 or byte > 0xBF then return 1 end
  end
  return length
end

function I18n.display_width(value)
  local text = tostring(value or "")
  local width, index = 0, 1
  while index <= #text do
    local span = utf8_span(text, index)
    width = width + (span == 1 and 1 or 2)
    index = index + span
  end
  return width
end

function I18n.clip(value, max_width)
  local text = tostring(value or "")
  max_width = math.max(0, tonumber(max_width) or 0)
  if I18n.display_width(text) <= max_width then return text end
  if max_width <= 3 then return string.rep(".", max_width) end

  local parts, width, index = {}, 0, 1
  local limit = max_width - 3
  while index <= #text do
    local span = utf8_span(text, index)
    local cells = span == 1 and 1 or 2
    if width + cells > limit then break end
    parts[#parts + 1] = text:sub(index, index + span - 1)
    width = width + cells
    index = index + span
  end
  return table.concat(parts) .. "..."
end

I18n.DEFAULT_LANGUAGE = DEFAULT_LANGUAGE

return I18n
