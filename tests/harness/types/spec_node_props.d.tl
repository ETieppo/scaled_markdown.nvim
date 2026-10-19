local record SpecNodeProps
    name: string
    parent: SpecNodeProps
    children: {SpecNodeProps}
    before_each: {function()}
    after_each: {function()}
    body: function()
end

return SpecNodeProps
