local documents = {}

file = {
  getcontents = function(path)
    return documents[path]
  end,
}

local I18n = dofile("package/i18n.lua")

local function equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %q, got %q", label, tostring(expected), tostring(actual)))
  end
end

equal(I18n.normalize("en-US"), "en", "English region")
equal(I18n.normalize("EN_us"), "en", "English underscore")
equal(I18n.normalize("zh-CN"), "zh-CN", "Simplified Chinese")
equal(I18n.normalize("zh-Hant"), "zh-CN", "Chinese variant")
equal(I18n.normalize(""), "zh-CN", "system default")
equal(I18n.normalize_mode(""), "system", "default language mode")
equal(I18n.normalize_mode("zh_TW"), "zh-CN", "Chinese override mode")
equal(I18n.normalize_mode("en-US"), "en", "English override mode")
equal(I18n.resolve("system", "en-US"), "en", "system English resolution")
equal(I18n.resolve("zh-CN", "en"), "zh-CN", "Chinese override resolution")

documents.settings = [[{"locale":"en-GB"}]]
equal(I18n.read("settings"), "en", "locale alias")
documents.settings = [[{"lang":"zh_CN"}]]
equal(I18n.read("settings"), "zh-CN", "lang alias")
documents.settings = [[{"language":"en"}]]
equal(I18n.read("settings"), "en", "language field")

equal(I18n.display_width("ABC"), 3, "ASCII display width")
equal(I18n.display_width("上海A"), 5, "Chinese display width")
equal(I18n.clip("上海市浦东新区", 10), "上海市...", "Chinese clipping")
equal(I18n.clip("CodexMonitor", 8), "Codex...", "ASCII clipping")
equal(I18n.clip("中文", 4), "中文", "unclipped Chinese")

print("i18n tests passed")
