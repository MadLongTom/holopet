local Timezone = {}

local function trim(value)
  return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

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

function Timezone.read_settings(path, fallback)
  fallback = trim(fallback) ~= "" and trim(fallback) or "CST-8"
  local raw = read_text(path)
  local codec = rawget(_G, "json") or rawget(_G, "sjson")
  if type(raw) ~= "string" or raw == "" or not codec or not codec.decode then return fallback end
  local ok, doc = pcall(codec.decode, raw)
  if not ok or type(doc) ~= "table" then return fallback end
  local timezone = trim(doc.timezone)
  return timezone ~= "" and timezone or fallback
end

local function is_digit(ch)
  return ch and ch:match("%d") ~= nil
end

local function parse_posix_offset(text, index)
  text = tostring(text or "")
  local i = index or 1
  local sign = 1
  local ch = text:sub(i, i)
  if ch == "+" then
    i = i + 1
  elseif ch == "-" then
    sign = -1
    i = i + 1
  end

  local start_i = i
  while is_digit(text:sub(i, i)) do i = i + 1 end
  if i == start_i then return nil, index end

  local hours = tonumber(text:sub(start_i, i - 1)) or 0
  local minutes, seconds = 0, 0
  if text:sub(i, i) == ":" then
    i = i + 1
    start_i = i
    while is_digit(text:sub(i, i)) do i = i + 1 end
    minutes = tonumber(text:sub(start_i, i - 1)) or 0
    if text:sub(i, i) == ":" then
      i = i + 1
      start_i = i
      while is_digit(text:sub(i, i)) do i = i + 1 end
      seconds = tonumber(text:sub(start_i, i - 1)) or 0
    end
  end

  -- POSIX timezone signs are reversed: CST-8 means UTC+8.
  return -(sign * (hours * 3600 + minutes * 60 + seconds)), i
end

local function parse_tz_name(text, index)
  text = tostring(text or "")
  local i = index or 1
  local start_i = i
  while text:sub(i, i):match("%a") do i = i + 1 end
  if i == start_i then return nil, index end
  return text:sub(start_i, i - 1), i
end

local function is_leap_year(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

local function days_in_month(year, month)
  if month == 2 then return is_leap_year(year) and 29 or 28 end
  return ({ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 })[month] or 30
end

local function days_before_year(year)
  local days, current = 0, 1970
  while current < year do
    days = days + (is_leap_year(current) and 366 or 365)
    current = current + 1
  end
  return days
end

local function days_before_month(year, month)
  local days, current = 0, 1
  while current < month do
    days = days + days_in_month(year, current)
    current = current + 1
  end
  return days
end

local function weekday(year, month, day)
  return (days_before_year(year) + days_before_month(year, month) + day - 1 + 4) % 7
end

local function year_from_epoch(seconds)
  local days = math.floor((tonumber(seconds) or 0) / 86400)
  local year = 1970
  while true do
    local year_days = is_leap_year(year) and 366 or 365
    if days < year_days then return year end
    days = days - year_days
    year = year + 1
  end
end

local function local_epoch(year, month, day, hour, minute, second)
  local days = days_before_year(year) + days_before_month(year, month) + day - 1
  return days * 86400 + (hour or 0) * 3600 + (minute or 0) * 60 + (second or 0)
end

local function parse_rule_time(text)
  text = trim(text)
  if text == "" then return 2 * 3600 end
  local sign = 1
  if text:sub(1, 1) == "-" then
    sign, text = -1, text:sub(2)
  elseif text:sub(1, 1) == "+" then
    text = text:sub(2)
  end
  local hour, minute, second = text:match("^(%d+):(%d+):(%d+)$")
  if not hour then hour, minute = text:match("^(%d+):(%d+)$") end
  if not hour then hour = text:match("^(%d+)$") end
  if not hour then return 2 * 3600 end
  return sign * ((tonumber(hour) or 0) * 3600 + (tonumber(minute) or 0) * 60 + (tonumber(second) or 0))
end

local function parse_dst_rule(text)
  local rule_text, time_text = tostring(text or ""):match("^([^/]+)/*(.*)$")
  local month, week, dow = tostring(rule_text or ""):match("^M(%d+)%.(%d+)%.(%d+)$")
  if not month then return nil end
  return { month = tonumber(month), week = tonumber(week), dow = tonumber(dow), time = parse_rule_time(time_text) }
end

local function transition_utc(year, rule, offset_before)
  local first_dow = weekday(year, rule.month, 1)
  local day = 1 + ((rule.dow - first_dow + 7) % 7) + (rule.week - 1) * 7
  local max_day = days_in_month(year, rule.month)
  if rule.week == 5 and day > max_day then day = day - 7 end
  return local_epoch(year, rule.month, day, 0, 0, rule.time) - offset_before
end

local function parse_posix_timezone(timezone)
  local text = trim(timezone)
  local std_name, index = parse_tz_name(text, 1)
  if not std_name then return nil end
  local std_offset, next_index = parse_posix_offset(text, index)
  if not std_offset then return nil end
  index = next_index

  local dst_name
  dst_name, index = parse_tz_name(text, index)
  if not dst_name then return { std_offset = std_offset } end

  local dst_offset = std_offset + 3600
  local ch = text:sub(index, index)
  if ch ~= "," and ch ~= "" then
    local explicit_offset, explicit_index = parse_posix_offset(text, index)
    if explicit_offset then dst_offset, index = explicit_offset, explicit_index end
  end
  if text:sub(index, index) ~= "," then return { std_offset = std_offset } end

  local rules = text:sub(index + 1)
  local comma = rules:find(",", 1, true)
  if not comma then return { std_offset = std_offset } end
  local start_rule = parse_dst_rule(rules:sub(1, comma - 1))
  local end_rule = parse_dst_rule(rules:sub(comma + 1))
  if not start_rule or not end_rule then return { std_offset = std_offset } end
  return { std_offset = std_offset, dst_offset = dst_offset, start_rule = start_rule, end_rule = end_rule }
end

local function offset_and_dst(timezone, seconds)
  local parsed = parse_posix_timezone(timezone)
  if not parsed then return 0, false end
  if not parsed.start_rule or not parsed.end_rule then return parsed.std_offset, false end
  seconds = tonumber(seconds) or 0
  local year = year_from_epoch(seconds + parsed.std_offset)
  local start_utc = transition_utc(year, parsed.start_rule, parsed.std_offset)
  local end_utc = transition_utc(year, parsed.end_rule, parsed.dst_offset)
  local in_dst
  if start_utc < end_utc then
    in_dst = seconds >= start_utc and seconds < end_utc
  else
    in_dst = seconds >= start_utc or seconds < end_utc
  end
  return in_dst and parsed.dst_offset or parsed.std_offset, in_dst
end

function Timezone.offset_for_epoch(timezone, seconds)
  return offset_and_dst(timezone, seconds)
end

function Timezone.is_dst(timezone, seconds)
  local _, in_dst = offset_and_dst(timezone, seconds)
  return in_dst
end

return Timezone
