local HEX_COLOR_PATTERN = '^#(%x%x)(%x%x)(%x%x)$'
local HEX_COLOR_FORMAT = '#%02x%02x%02x'

local color_math = {}


function color_math.hex_to_rgb(hex_color)
   local red, green, blue = hex_color:match(HEX_COLOR_PATTERN)
   if not red then
      error(('invalid hex color: %s'):format(tostring(hex_color)))
   end
   return {
      math.floor(tonumber(red, 16)),
      math.floor(tonumber(green, 16)),
      math.floor(tonumber(blue, 16)),
   }
end

function color_math.rgb_to_hex(rgb_color)
   return HEX_COLOR_FORMAT:format(rgb_color[1], rgb_color[2], rgb_color[3])
end

local function lerp_rgb(a, b, t)
   local out = {}
   for channel_index = 1, 3 do
      local value = a[channel_index] + (b[channel_index] - a[channel_index]) * t
      out[channel_index] = math.floor(value + 0.5)
   end
   return out
end

function color_math.interpolate_hex(
   colors,
   ratio)

   local stops = {}
   for _, color in ipairs(colors or {}) do
      stops[#stops + 1] = color
   end

   if #stops == 1 then return stops[1] end

   ratio = math.max(0, math.min(1, ratio))
   local segment_count = #stops - 1
   local scaled = ratio * segment_count
   local index = math.floor(scaled) + 1

   if index > segment_count then
      index = segment_count
   end

   local local_t = scaled - (index - 1)
   local start_rgb = color_math.hex_to_rgb(stops[index])
   local end_rgb = color_math.hex_to_rgb(stops[index + 1])

   return color_math.rgb_to_hex(lerp_rgb(start_rgb, end_rgb, local_t))
end

return color_math
