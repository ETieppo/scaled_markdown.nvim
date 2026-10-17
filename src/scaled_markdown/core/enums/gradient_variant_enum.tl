local enum GradientVariantEnum
  'foreground'
  'fill'
end

local record GradientVariantEnumProps
  type GradientVariantEnum = GradientVariantEnum

  FOREGROUND: GradientVariantEnum
  FILL: GradientVariantEnum
end

local GRADIENT_VARIANT_ENUM <const>: GradientVariantEnumProps = {
  FOREGROUND = 'foreground',
  FILL = 'fill',
}

return GRADIENT_VARIANT_ENUM
