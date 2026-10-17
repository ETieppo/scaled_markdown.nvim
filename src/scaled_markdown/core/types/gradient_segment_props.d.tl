local GRADIENT_VARIANT_ENUM =
  require 'scaled_markdown.core.enums.gradient_variant_enum'
local type GradientVariantEnum = GRADIENT_VARIANT_ENUM.GradientVariantEnum

local record GradientSegmentProps
  text: string
  highlight: string
  variant: GradientVariantEnum
end

return GradientSegmentProps
