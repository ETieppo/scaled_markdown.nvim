local enum RendererEnum
  'graphics'
  'typeface'
  'toilet'
  'figlet'
  'plain'
end

local record RendererEnumProps
  type RendererEnum = RendererEnum

  GRAPHICS: RendererEnum
  TYPEFACE: RendererEnum
  TOILET: RendererEnum
  FIGLET: RendererEnum
  PLAIN: RendererEnum
end

local RENDERER_ENUM <const>: RendererEnumProps = {
  GRAPHICS = 'graphics',
  TYPEFACE = 'typeface',
  TOILET = 'toilet',
  FIGLET = 'figlet',
  PLAIN = 'plain',
}

return RENDERER_ENUM
