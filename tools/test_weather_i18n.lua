file = {
  getcontents = function()
    return [[{"weather_address":"Beijing"}]]
  end,
}

local WeatherClient = dofile("package/weather_client.lua")

local function equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %q, got %q", label, tostring(expected), tostring(actual)))
  end
end

local forecast = {
  current = {
    time = "2026-07-15T12:00", temperature_2m = 30, apparent_temperature = 32,
    relative_humidity_2m = 60, precipitation = 0, weather_code = 0,
    wind_speed_10m = 8, wind_direction_10m = 90, wind_gusts_10m = 12,
  },
  hourly = {
    time = { "2026-07-15T12:00" }, temperature_2m = { 30 },
    relative_humidity_2m = { 60 }, precipitation_probability = { 0 },
    precipitation = { 0 }, weather_code = { 0 }, wind_speed_10m = { 8 },
    wind_direction_10m = { 90 }, wind_gusts_10m = { 12 },
  },
}

local en = WeatherClient.new({ language = "en" })
assert(en:parse_forecast(forecast))
equal(en.state.city, "WEATHER", "English initial city")
equal(en.state.current.label, "CLEAR", "English weather label")
equal(en.state.current.temp_text, "30C", "English temperature unit")
equal(en.state.rain_time, "DRY", "English rain label")

local zh = WeatherClient.new({ language = "zh-CN" })
assert(zh:parse_forecast(forecast))
equal(zh.state.city, "天气", "Chinese initial city")
equal(zh.state.current.label, "晴", "Chinese weather label")
equal(zh.state.current.temp_text, "30℃", "Chinese temperature unit")
equal(zh.state.rain_time, "无雨", "Chinese rain label")

local requested_url = ""
http = {
  get = function(url)
    requested_url = url
  end,
}
zh.running = true
zh:resolve_location("北京", function() end)
assert(requested_url:find("language=zh", 1, true), "Chinese geocoding language missing")
en.running = true
en:resolve_location("Beijing", function() end)
assert(requested_url:find("language=en", 1, true), "English geocoding language missing")

print("weather i18n tests passed")
