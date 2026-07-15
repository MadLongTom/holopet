local ConsoleText = {}
ConsoleText.__index = ConsoleText

local MAIN = (rawget(_G, "LV_PART_MAIN") or 0) | (rawget(_G, "LV_STATE_DEFAULT") or 0)
local CANVAS_FMT = rawget(_G, "LV_IMG_CF_TRUE_COLOR") or rawget(_G, "LV_COLOR_FORMAT_NATIVE")

local function canvas_begin(canvas)
  if lv_canvas_frame_begin then
    local ok, result = pcall(lv_canvas_frame_begin, canvas)
    return ok and result ~= false
  end
  if lv_canvas_begin then
    local ok, result = pcall(lv_canvas_begin, canvas)
    return ok and result ~= false
  end
  return false
end

local function canvas_end(canvas, explicit)
  if not explicit then return end
  if lv_canvas_frame_end then
    pcall(lv_canvas_frame_end, canvas)
  elseif lv_canvas_end then
    pcall(lv_canvas_end, canvas)
  end
end

function ConsoleText.open(options)
  options = options or {}
  local self = setmetatable({
    ready = false,
    family = "Clawd Console",
    source = "Cascadia Mono",
    rendering = "RGB subpixel / RGB565 compositor",
    module_path = tostring(options.module_path or "/sd/apps/holo_pet/modules/aida_font.so"),
    font_path = tostring(options.font_path or "/sd/apps/holo_pet/font/clawd_console.ttf"),
    module = nil,
    error = "",
  }, ConsoleText)

  if type(lv_canvas_create) ~= "function" or type(lv_canvas_blit_rgb565) ~= "function" then
    self.error = "RGB565 canvas API unavailable"
    return self
  end

  local required, module_or_error = pcall(require, self.module_path)
  if not required or type(module_or_error) ~= "table" then
    self.error = "console module unavailable: " .. tostring(module_or_error)
    return self
  end
  if type(module_or_error.open) ~= "function" or type(module_or_error.render) ~= "function" then
    self.error = "console module API mismatch"
    return self
  end

  local opened, result, open_error = pcall(module_or_error.open, self.font_path)
  if not opened or not result then
    self.error = "console font load failed: " .. tostring(open_error or result)
    return self
  end

  self.module = module_or_error
  self.ready = true
  return self
end

function ConsoleText:create_canvas(parent, width, height)
  if not self.ready then return nil end
  width, height = math.max(1, math.floor(width or 1)), math.max(1, math.floor(height or 1))
  if CANVAS_FMT then
    local ok, canvas = pcall(lv_canvas_create, parent, width, height, CANVAS_FMT)
    if ok and canvas then return canvas end
  end
  local ok, canvas = pcall(lv_canvas_create, parent, width, height)
  return ok and canvas or nil
end

function ConsoleText:raster(text, width, height, size, color, background, align)
  if not self.ready or not self.module then return nil, self.error end
  width, height = math.max(1, math.floor(width or 1)), math.max(1, math.floor(height or 1))
  local options = {
    align = tonumber(align) or 0,
    opaque = true,
    subpixel = 1,
  }
  local ok, data, render_error = pcall(self.module.render,
    tostring(text or ""), width, height, math.max(6, math.floor(size or 12)),
    tonumber(color) or 0xFFFFFF, tonumber(background) or 0,
    0x00FF00, options)
  if not ok or type(data) ~= "string" then
    self.error = "console raster failed: " .. tostring(render_error or data)
    return nil, self.error
  end
  local expected = width * height * 2
  if #data ~= expected then
    self.error = "console buffer mismatch: " .. tostring(#data) .. "/" .. tostring(expected)
    return nil, self.error
  end
  return data
end

function ConsoleText:blit(canvas, data, width, height)
  if not canvas or type(data) ~= "string" then return false, "invalid console canvas" end
  local explicit = canvas_begin(canvas)
  local ok, result = pcall(lv_canvas_blit_rgb565, canvas, 0, 0, width, height,
    data, { byte_order = "little", full_rewrite = true })
  if not ok or result == false then
    ok, result = pcall(lv_canvas_blit_rgb565, canvas, 0, 0, width, height, data)
  end
  canvas_end(canvas, explicit)
  if not ok or result == false then
    self.error = "RGB565 text blit failed"
    return false, self.error
  end
  return true
end

function ConsoleText:validate(parent)
  if not self.ready then return false, self.error end
  local canvas = self:create_canvas(parent, 16, 16)
  if not canvas then
    self.ready = false
    self.error = "console validation canvas failed"
    return false, self.error
  end
  pcall(lv_obj_set_style_bg_opa, canvas, 0, MAIN)
  local data, raster_error = self:raster("M", 16, 16, 12, 0xFFFFFF, 0, 0)
  local ok, blit_error = false, nil
  if data then ok, blit_error = self:blit(canvas, data, 16, 16) end
  if lv_obj_del then pcall(lv_obj_del, canvas) end
  if not data or not ok then
    self.ready = false
    self.error = tostring(raster_error or blit_error or self.error or "console validation failed")
    return false, self.error
  end
  return true
end

function ConsoleText:disable(reason)
  self.ready = false
  self.error = tostring(reason or self.error or "console renderer disabled")
end

return ConsoleText
