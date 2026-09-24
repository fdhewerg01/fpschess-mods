-- Logical HUD coordinates, shared by drawing and mouse hit testing.
local Layout = {}
function Layout.build(width, height, count)
    count = math.max(1, math.min(5, math.floor(count)))
    local scale = math.min(1, width / 1280, height / 720)
    local gap, margin = 18 * scale, 36 * scale
    local cardWidth = math.min(270 * scale, (width - margin * 2 - gap * (count - 1)) / count)
    local cardHeight = 370 * scale
    local left = (width - cardWidth * count - gap * (count - 1)) / 2
    local top = (height - cardHeight) / 2
    local result = {scale=scale, width=width, height=height, cards={}, top=top}
    for i=1,count do
        result.cards[i] = {x=left+(i-1)*(cardWidth+gap), y=top, w=cardWidth, h=cardHeight}
    end
    return result
end
function Layout.hit(layout, x, y)
    if not layout or type(x)~="number" or type(y)~="number" then return nil end
    for i,r in ipairs(layout.cards) do
        if x>=r.x and x<r.x+r.w and y>=r.y and y<r.y+r.h then return i end
    end
end
return Layout

