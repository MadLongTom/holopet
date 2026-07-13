local Timezone = dofile("package/timezone.lua")

local function equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
  end
end

equal(Timezone.offset_for_epoch("UTC0", 1783929600), 0, "UTC offset")
equal(Timezone.offset_for_epoch("CST-8", 1783929600), 8 * 3600, "China offset")
equal(Timezone.offset_for_epoch("JST-9", 1783929600), 9 * 3600, "Japan offset")

local eastern = "EST5EDT,M3.2.0/2,M11.1.0/2"
equal(Timezone.offset_for_epoch(eastern, 1772953199), -5 * 3600, "EST before DST start")
equal(Timezone.offset_for_epoch(eastern, 1772953200), -4 * 3600, "EDT at DST start")
equal(Timezone.is_dst(eastern, 1772953200), true, "DST active")
equal(Timezone.offset_for_epoch(eastern, 1793512799), -4 * 3600, "EDT before DST end")
equal(Timezone.offset_for_epoch(eastern, 1793512800), -5 * 3600, "EST at DST end")
equal(Timezone.is_dst(eastern, 1793512800), false, "DST inactive")

local values = {
  ["valid"] = { timezone = " PST8PDT,M3.2.0/2,M11.1.0/2 " },
  ["blank"] = { timezone = "  " },
}
file = { getcontents = function(path) return path end }
json = { decode = function(raw) return values[raw] or {} end }

equal(Timezone.read_settings("valid", "CST-8"), "PST8PDT,M3.2.0/2,M11.1.0/2", "settings timezone")
equal(Timezone.read_settings("blank", "CST-8"), "CST-8", "blank timezone fallback")
equal(Timezone.read_settings("missing", "CST-8"), "CST-8", "missing timezone fallback")

print("timezone tests passed")
