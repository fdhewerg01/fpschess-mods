-- Cards live in the game viewport, not in the combat HUD's WidgetTree.
-- The combat HUD is replaced during round transitions; retaining a child of
-- that tree (or removing it during teardown) can dereference a stale Slate node.
local Layout = require("CardLayout")
local View = {}
View.__index = View

local function wrap(content, limit)
    local lines, used = {}, 0
    for _, code in utf8.codes(tostring(content or "")) do
        local character = utf8.char(code)
        if character == "\n" then
            lines[#lines + 1], used = "\n", 0
        else
            local units = code < 128 and 0.55 or 1
            if used + units > limit and used > 0 then
                lines[#lines + 1], used = "\n", 0
            end
            lines[#lines + 1] = character
            used = used + units
        end
    end
    return table.concat(lines)
end

function View.new(api, createMessage)
    return setmetatable({api=api, createMessage=createMessage, widgets={}, cards={}, signatures={}}, View)
end

function View:hide()
    for _, item in pairs(self.widgets) do
        if item and self.api.valid(item.widget) then
            self.api.call(item.widget, "SetVisibility", 1) -- Collapsed
        end
    end
end

function View:destroy()
    -- Never call RemoveFromParent while the game is destroying a combat HUD.
    -- Keep viewport-owned widgets for reuse in the next draw.
    self:hide()
    self.layout, self.signature = nil, nil
    self.lastX, self.lastY = nil, nil
    self.inputAttached = false
end

function View:make(name, controller)
    self.api.log("카드 UI 생성 전: "..name)
    local item = self.widgets[name]
    if item and self.api.valid(item.widget) and self.api.valid(item.label)
        and self.api.call(item.widget, "IsInViewport") == true then
        return item
    end
    local widget, label = self.createMessage(controller)
    self.api.log("카드 UI 위젯 생성 후: "..name)
    if not self.api.valid(widget) or not self.api.valid(label) then return nil end

    -- ChatMessage is intentionally just the text layer. Give each viewport
    -- widget its own canvas background so card text does not float directly
    -- over the 3D scene. This mirrors the proven Border-on-Canvas pattern in
    -- ModHub and keeps the background owned by the same UMG widget tree.
    local background, backgroundSlot
    local tree = self.api.read(widget, "WidgetTree")
    local root = self.api.read(tree, "RootWidget")
    if self.api.valid(tree) and self.api.valid(root)
        and self.api.className(root) == "CanvasPanel" then
        local borderClass = StaticFindObject("/Script/UMG.Border")
        if self.api.valid(borderClass) then
            local ok, border = pcall(function()
                return StaticConstructObject(borderClass, tree)
            end)
            if ok and self.api.valid(border) then
                local added, slot = pcall(function()
                    border:SetVisibility(3)
                    local childSlot = root:AddChildToCanvas(border)
                    childSlot:SetAutoSize(false)
                    childSlot:SetPosition({X=0,Y=0})
                    childSlot:SetSize({X=1,Y=1})
                    childSlot:SetZOrder(-1)
                    return childSlot
                end)
                if added then
                    background, backgroundSlot = border, slot
                else
                    self.api.log("카드 UI 배경 연결 실패: "..name.." / "..tostring(slot))
                end
            else
                self.api.log("카드 UI 배경 생성 실패: "..name)
            end
        end
    else
        self.api.log("카드 UI CanvasPanel 없음: "..name)
    end

    widget:AddToViewport(12000)
    self.api.log("카드 UI 뷰포트 추가 후: "..name)
    widget:SetVisibility(3) -- HitTestInvisible: key and mouse polling stay in main.lua.
    item = {widget=widget, label=label, text=nil, background=background, backgroundSlot=backgroundSlot}
    self.widgets[name] = item
    return item
end

function View:place(item, content, x, y, width, height, backgroundColor)
    self.api.log("카드 UI 배치 시작")
    item.widget:SetVisibility(3)
    item.widget:SetPositionInViewport({X=x,Y=y}, false)
    item.widget:SetDesiredSizeInViewport({X=width,Y=height})
    if item.background and self.api.valid(item.background) then
        if item.backgroundSlot and self.api.valid(item.backgroundSlot) then
            item.backgroundSlot:SetSize({X=width,Y=height})
        end
        item.background:SetBrushColor(backgroundColor or {R=0.025,G=0.035,B=0.055,A=0.94})
        item.background:SetVisibility(3)
    end
    self.api.log("카드 UI 크기 설정 후")
    if item.text ~= content then
        item.label:SetText(FText(content))
        item.text = content
    end
    item.widget:ForceLayoutPrepass()
    self.api.log("카드 UI 레이아웃 계산 후")
    local desired = item.widget:GetDesiredSize()
    if desired and desired.X and desired.Y then
        local fit = math.min(1, width / math.max(1, desired.X), height / math.max(1, desired.Y))
        item.widget:SetRenderScale({X=fit,Y=fit})
    end
end

function View:render(offered, selected, waiting, remaining, owned, maximum)
    if not self.signature then self.api.log("카드 UI 렌더 시작") end
    if not offered or #offered == 0 then return false end
    local controller = self.api.localController()
    if not self.api.valid(controller) then return false end
    local library = StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
    if not self.api.valid(library) then return false end
    local viewport = self.api.call(library, "GetViewportSize", controller)
    if not self.signature then self.api.log("카드 UI 뷰포트 크기 읽음") end
    local dpi = self.api.call(library, "GetViewportScale", controller) or 1
    if not viewport or not viewport.X or viewport.X <= 0 or not viewport.Y or viewport.Y <= 0 or dpi <= 0 then return false end
    local width, height = viewport.X / dpi, viewport.Y / dpi
    local signature = table.concat({width,height,selected,tostring(waiting),remaining,owned,maximum}, ":")
    if self.signature == signature then return true end
    self.layout = Layout.build(width,height,#offered)
    if not self.signature then self.api.log("카드 UI 레이아웃 생성") end
    local layout, scale = self.layout, self.layout.scale
    local header = self:make("header", controller)
    local footer = self:make("footer", controller)
    if not header or not footer then return false end
    self:place(header, waiting and "선택 완료 · 상대를 기다리는 중" or "증강 카드를 선택하세요",
        36*scale, layout.top-78*scale, width-72*scale, 62*scale,
        {R=0.035,G=0.045,B=0.075,A=0.96})
    local timer = remaining < 0 and "상대 대기 중" or ("남은 시간 "..remaining.."초")
    self:place(footer, timer.."  ·  A / D 또는 ← / → 선택  ·  SPACE 확정  ·  보유 "..owned.." / "..maximum,
        36*scale, layout.top+layout.cards[1].h+16*scale, width-72*scale, 75*scale,
        {R=0.035,G=0.045,B=0.075,A=0.96})
    for index, card in ipairs(offered) do
        local rect = layout.cards[index]
        local item = self:make("card"..index, controller)
        if not item then return false end
        local heading = index == selected and "▶ 선택 중" or ("  "..index.."번 카드")
        local content = heading.."\n["..tostring(card.rarity or "일반").."] "
            ..tostring(card.title or card.id or "카드").."\n\n"
            ..wrap(card.text or "", math.max(10,math.floor(rect.w/(23*scale))))
        self:place(item, content, rect.x+10*scale, rect.y+12*scale,
            rect.w-20*scale, rect.h-24*scale,
            index == selected and {R=0.16,G=0.105,B=0.035,A=0.98}
                or {R=0.025,G=0.035,B=0.055,A=0.96})
    end
    for index=#offered+1,5 do
        local item = self.widgets["card"..index]
        if item and self.api.valid(item.widget) then item.widget:SetVisibility(1) end
    end
    self.signature = signature
    return true
end

function View:hit(movedOnly)
    if not self.layout then return nil end
    local controller = self.api.localController()
    if not self.api.valid(controller) then return nil end
    local library = StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
    if not self.api.valid(library) then return nil end
    local point = self.api.call(library, "GetMousePositionOnViewport", controller)
    if not point then return nil end
    local moved = self.lastX ~= point.X or self.lastY ~= point.Y
    self.lastX, self.lastY = point.X, point.Y
    if movedOnly and not moved then return nil end
    return Layout.hit(self.layout, point.X, point.Y)
end

return View
