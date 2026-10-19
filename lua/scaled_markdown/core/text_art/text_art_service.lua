local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local config_store = require 'scaled_markdown.core.config.config_store'
local figlet_renderer = require 'scaled_markdown.core.text_art.figlet_renderer'
local text_art_cache = require 'scaled_markdown.core.text_art.text_art_cache'
local text_art_line_wrapper =
  require 'scaled_markdown.core.text_art.text_art_line_wrapper'
local toilet_renderer = require 'scaled_markdown.core.text_art.toilet_renderer'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local graphics_renderer =
  require 'scaled_markdown.core.text_art.graphics_renderer'
local typeface_renderer =
  require 'scaled_markdown.core.text_art.typeface_renderer'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@type table<RendererEnum, TextArtRendererProps>
local RENDERER_BY_ENUM = {
  [RENDERER_ENUM.GRAPHICS] = graphics_renderer,
  [RENDERER_ENUM.TYPEFACE] = typeface_renderer,
  [RENDERER_ENUM.TOILET] = toilet_renderer,
  [RENDERER_ENUM.FIGLET] = figlet_renderer,
}
---@type table<RendererEnum, boolean>
local NATIVELY_WRAPPING_RENDERERS = {
  [RENDERER_ENUM.GRAPHICS] = true,
  [RENDERER_ENUM.TOILET] = true,
  [RENDERER_ENUM.FIGLET] = true,
}
---@type RendererEnum[]
local FALLBACK_ORDER = {
  RENDERER_ENUM.GRAPHICS,
  RENDERER_ENUM.TYPEFACE,
  RENDERER_ENUM.TOILET,
  RENDERER_ENUM.FIGLET,
}
local PENDING_RESULT = nil
local FAILED_RESULT = false

---@alias TextArtRequestProps TextArtProps|boolean

---@class text_art_service
local text_art_service = {}

---@type table<string, boolean>
local pending_keys = {}
---@type (fun())?
local ready_listener = nil

---@param preferred_renderer RendererEnum
---@return RendererEnum[]
local function resolve_renderer_order(preferred_renderer)
  ---@type RendererEnum[]
  local renderer_order = { preferred_renderer }
  for _, renderer in ipairs(FALLBACK_ORDER) do
    if renderer ~= preferred_renderer then
      renderer_order[#renderer_order + 1] = renderer
    end
  end
  return renderer_order
end

---@param text_art_dto TextArtProps
---@return integer
local function measure_widest(text_art_dto)
  local widest = 0
  for _, line in ipairs(text_art_dto.lines) do
    widest = math.max(widest, utf8_text.display_width(line))
  end
  return widest
end

---@param key string
---@param renderer RendererEnum
---@param text string
---@param style_props TextArtStyleProps
---@param width integer
local function start_render(key, renderer, text, style_props, width)
  if pending_keys[key] then return end
  pending_keys[key] = true
  RENDERER_BY_ENUM[renderer].render_async(
    text,
    style_props,
    width,
    ---@param art_lines TextArtProps
    function(art_lines)
      vim.schedule(function()
        pending_keys[key] = nil
        text_art_cache.store(key, art_lines)
        if ready_listener then ready_listener() end
      end)
    end
  )
end

---@param renderer RendererEnum
---@param style_props TextArtStyleProps
---@param width integer
---@param text string
---@return TextArtRequestProps?
local function request_single(renderer, style_props, width, text)
  local key = text_art_cache.build_key(renderer, style_props, width, text)
  local cached_art = text_art_cache.lookup(key)
  if cached_art == nil then
    start_render(key, renderer, text, style_props, width)
    return PENDING_RESULT
  end
  return cached_art
end

---@param renderer RendererEnum
---@param style_props TextArtStyleProps
---@param width integer
---@param segment string
---@return TextArtRequestProps?
local function request_fitting_segment(renderer, style_props, width, segment)
  local segment_art = request_single(
    renderer,
    style_props,
    CORE_CONSTANTS.UNBOUNDED_TEXT_ART_WIDTH,
    segment
  )
  if type(segment_art) == 'table' and measure_widest(segment_art) > width then
    return request_single(renderer, style_props, width, segment)
  end
  return segment_art
end

---@param renderer RendererEnum
---@param style_props TextArtStyleProps
---@param width integer
---@param text string
---@return TextArtRequestProps?
local function request_wrapped(renderer, style_props, width, text)
  local full_art = request_single(
    renderer,
    style_props,
    CORE_CONSTANTS.UNBOUNDED_TEXT_ART_WIDTH,
    text
  )
  if not (type(full_art) == 'table') then return full_art end
  if measure_widest(full_art) <= width then return full_art end
  ---@type string[]
  local stacked_lines = {}
  local is_pending = false
  for _, segment in
    ipairs(text_art_line_wrapper.wrap(text, measure_widest(full_art), width))
  do
    local segment_art =
      request_fitting_segment(renderer, style_props, width, segment)
    if segment_art == FAILED_RESULT then return FAILED_RESULT end
    is_pending = is_pending or segment_art == PENDING_RESULT
    vim.list_extend(
      stacked_lines,
      type(segment_art) == 'table' and segment_art.lines or {}
    )
  end
  if is_pending then return PENDING_RESULT end
  return { lines = stacked_lines }
end

---@param renderer RendererEnum
---@param style_props TextArtStyleProps
---@param width integer
---@param text string
---@return TextArtRequestProps?
local function request_with_renderer(renderer, style_props, width, text)
  if NATIVELY_WRAPPING_RENDERERS[renderer] then
    return request_single(renderer, style_props, width, text)
  end
  return request_wrapped(renderer, style_props, width, text)
end

---@param text string
---@param style_by_renderer table<RendererEnum, TextArtStyleProps>
---@param width integer
---@return TextArtProps?
function text_art_service.request(text, style_by_renderer, width)
  local preferred_renderer = config_store.get().renderer --[[@as RendererEnum]]
  if preferred_renderer == RENDERER_ENUM.PLAIN then return nil end
  for _, renderer in ipairs(resolve_renderer_order(preferred_renderer)) do
    local style_props = style_by_renderer[renderer]
    if style_props and RENDERER_BY_ENUM[renderer].is_available() then
      local art_lines =
        request_with_renderer(renderer, style_props, width, text)
      if type(art_lines) == 'table' then return art_lines end
      if art_lines == PENDING_RESULT then return PENDING_RESULT end
    end
  end
  return nil
end

---@param listener fun()
function text_art_service.set_ready_listener(listener) ready_listener = listener end

---@return boolean
function text_art_service.has_pending() return next(pending_keys) ~= nil end

function text_art_service.clear_cache()
  text_art_cache.clear()
  graphics_image_registry.release_all()
end

return text_art_service
