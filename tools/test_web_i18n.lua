local Web = dofile("package/web.lua")

local en = Web.build_html("/holo_pet/api", "en")
assert(en:find('<html lang="en">', 1, true), "English html lang missing")
assert(en:find("Clawd Monitor Settings", 1, true), "English title missing")
assert(en:find("Weather city", 1, true), "English weather label missing")
assert(not en:find("天气城市", 1, true), "Chinese copy leaked into English WebUI")
assert(en:find("let formDirty=false", 1, true), "form dirty tracking missing")
assert(en:find("if(formDirty&&!force)return", 1, true), "edited form protection missing")
assert(en:find("paint(d,true,true)", 1, true), "saved settings do not force a form sync")
assert(en:find("paint(d,false,false)", 1, true), "status polling still syncs form fields")

local zh = Web.build_html("/holo_pet/api", "zh-CN")
assert(zh:find('<html lang="zh-CN">', 1, true), "Chinese html lang missing")
assert(zh:find("Clawd Monitor 设置", 1, true), "Chinese title missing")
assert(zh:find("天气城市", 1, true), "Chinese weather label missing")
assert(not zh:find("Weather city", 1, true), "English copy leaked into Chinese WebUI")

print("web i18n tests passed")
