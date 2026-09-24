-- Same module is shipped with each supported mod. UE4SS shared primitive
-- variables join their separate Lua states; no function pointers are shared.
local InputState=require("InputState")
local Hub={}; Hub.__index=Hub
local ids={"stats","augment"}
local titles={stats="스탯 편집기",augment="증강 체스"}
local localState={}
local function get(key)
    if ModRef then
        local ok,value=pcall(function() return ModRef:GetSharedVariable("fps.hub."..key) end)
        if ok then return value end
    end
    return localState[key]
end
local function set(key,value)
    if ModRef then
        local ok=pcall(function() ModRef:SetSharedVariable("fps.hub."..key,value) end)
        if ok then return end
    end
    localState[key]=value
end
function Hub.busy() return get("open")==true end
function Hub.locked() return get("cards")==true end
function Hub.setLocked(value) set("cards",value) end
function Hub.dismiss() set("open",false) end
local function leader() for _,id in ipairs(ids) do if get("ready."..id) then return id end end end
local function decode(data)
    local rows={}
    for line in (data or ""):gmatch("[^\n]+") do
        local label,value,kind=line:match("([^\t]*)\t([^\t]*)\t([^\t]*)")
        if label then rows[#rows+1]={label=label,value=value,kind=kind} end
    end
    return rows
end
local function wrapText(content,width)
    -- UMG_ChatMessage has internal left/right padding that is not reflected
    -- in GetDesiredSize().  Use a conservative display width so the last
    -- glyph cannot escape the panel on Korean and mixed ASCII lines.
    local result,used={},0
    local limit=math.max(18,math.floor(width/30))
    for _,code in utf8.codes(tostring(content or "")) do
        local char=utf8.char(code)
        local units=code<128 and 0.55 or 1
        if char=="\n" then
            result[#result+1]="\n"; used=0
        else
            if used+units>limit and used>0 then result[#result+1]="\n"; used=0 end
            result[#result+1]=char; used=used+units
        end
    end
    return table.concat(result)
end
function Hub:close()
    set("open",false)
    self:dispose()
end
function Hub:dispose()
    for _,item in ipairs(self.items or {}) do self.api.call(item.widget,"RemoveFromParent") end
    self.items={}; self.root=nil; self.signature=nil
    if self.input then
        self.api.call(self.input.pc,"SetIgnoreMoveInput",false)
        self.api.call(self.input.pc,"SetIgnoreLookInput",false)
        if not Hub.locked() then InputState.restore(self.api,self.input) end
        self.input=nil
    end
end
function Hub:publish()
    local rows=self.adapter.rows()
    local lines={}
    for _,row in ipairs(rows) do
        lines[#lines+1]=table.concat({tostring(row.label):gsub("[\t\n]"," "),tostring(row.value or ""):gsub("[\t\n]"," "),row.kind or "number"},"\t")
    end
    set("rows."..self.id,table.concat(lines,"\n"))
    set("target."..self.id,self.adapter.target and self.adapter.target() or "settings")
end
function Hub:command(delta,value)
    local rows=decode(get("rows."..tostring(self.mod)))
    local row=rows[self.row]
    if not row or get("command."..self.mod) then return end
    local mod,index=self.mod,self.row
    if row.kind=="launch" then self:close() end
    set("targetRequest."..mod,get("target."..mod))
    set("command."..mod,table.concat({index,delta or 0,value or ""},"|"))
    self.inputText=""
end
function Hub:handle(key)
    if key==0x72 then
        self.api.log("F3 입력 수신: provider="..self.id..", leader="..tostring(leader()))
        -- The instance that registered the shared key remains the keyboard
        -- owner even after another provider becomes available.  Using the
        -- first ready provider here made F3 stop responding when the mods
        -- loaded in the opposite order.
        if get("keyOwner")~=self.id or Hub.locked() then return end
        if Hub.busy() then self:close() else
            self.adapter.close()
            set("open",true); self.mod=nil; self.row=1; self.inputText=""
        end
        return
    end
    if not Hub.busy() then return end
    if key==0x1B then self.escapeUntil=os.clock()+0.45; self:close(); return end
    if key==0x01 then
        if not self.root then return end
        local layout=StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
        local slate=StaticFindObject("/Script/UMG.Default__SlateBlueprintLibrary")
        local p=slate:AbsoluteToLocal(self.root:GetCachedGeometry(),layout:GetMousePositionOnPlatform())
        for _,hit in ipairs(self.hits or {}) do
            if p.X>=hit.x and p.X<hit.x+hit.w and p.Y>=hit.y and p.Y<hit.y+hit.h then
                if hit.mod then self.mod=hit.mod; self.row=1; self.inputText=""
                else
                    self.row=hit.row; self.inputText=""
                    if hit.delta then self:command(hit.delta) end
                end
                return
            end
        end
    elseif key==0x09 then
        local available={}; for _,id in ipairs(ids) do if get("ready."..id) then available[#available+1]=id end end
        local current=0; for i,id in ipairs(available) do if id==self.mod then current=i end end
        self.mod=available[current%#available+1]; self.row=1; self.inputText=""
    elseif key==0x57 or key==0x26 or key==0x53 or key==0x28 then
        local count=#decode(get("rows."..tostring(self.mod)))
        if count>0 then self.row=(self.row-1+((key==0x57 or key==0x26) and -1 or 1))%count+1 end
        self.inputText=""
    elseif key==0x41 or key==0x25 then self:command(-1)
    elseif key==0x44 or key==0x27 or key==0x20 then self:command(1)
    elseif key==0x0D then self:command(0,tonumber(self.inputText))
    elseif key==0x08 then self.inputText=self.inputText:sub(1,-2)
    elseif key>=0x30 and key<=0x39 then self.inputText=self.inputText..tostring(key-0x30)
    elseif key>=0x60 and key<=0x69 then self.inputText=self.inputText..tostring(key-0x60)
    elseif key==0xBE or key==0x6E then if not self.inputText:find(".",1,true) then self.inputText=self.inputText.."." end
    elseif key==0xBD or key==0x6D then
        self.inputText=self.inputText:sub(1,1)=="-" and self.inputText:sub(2) or "-"..self.inputText
    end
end
function Hub:render()
    local api=self.api
    local pc=api.localController()
    if not api.valid(pc) then self:close(); return end
    if not api.valid(self.root) then
        local candidates={}
        local pawn=api.read(pc,"Pawn")
        local own=api.read(pawn,"PieceHUD")
        if api.valid(own) then candidates[#candidates+1]=own end
        for _,w in ipairs(api.findAll("PieceHUD_C") or {}) do candidates[#candidates+1]=w end
        for _,w in ipairs(api.findAll("UserWidget") or {}) do candidates[#candidates+1]=w end
        for _,w in ipairs(candidates) do
            if api.call(w,"IsInViewport")==true then
                local tree=api.read(w,"WidgetTree"); local root=api.read(tree,"RootWidget")
                if api.valid(root) and root:GetClass():GetFName():ToString()=="CanvasPanel" then
                    self.root,self.tree=root,tree; break
                end
            end
        end
        if not self.root then return end
        self.input=InputState.capture(api,pc)
        api.call(pc,"SetIgnoreMoveInput",true); api.call(pc,"SetIgnoreLookInput",true)
        api.write(pc,"bShowMouseCursor",true)
        local border=StaticConstructObject(StaticFindObject("/Script/UMG.Border"),self.tree)
        if not api.valid(border) then self:dispose(); return end
        border:SetBrushColor({R=0.025,G=0.035,B=0.055,A=0.98}); border:SetVisibility(3)
        local slot=self.root:AddChildToCanvas(border); slot:SetZOrder(12000)
        local widget,label=self.createMessage(pc)
        if not api.valid(widget) or not api.valid(label) then self:dispose(); return end
        widget:SetVisibility(3); widget:SetRenderTransformPivot({X=0,Y=0})
        local textSlot=self.root:AddChildToCanvas(widget); textSlot:SetAutoSize(false); textSlot:SetZOrder(12001)
        self.items={{widget=border,slot=slot},{widget=widget,label=label,slot=textSlot}}
        api.call(StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary"),"SetInputMode_UIOnly",pc,widget,0)
    end
    local slate=StaticFindObject("/Script/UMG.Default__SlateBlueprintLibrary")
    local size=slate:GetLocalSize(self.root:GetCachedGeometry())
    if size.X<=0 or size.Y<=0 then
        -- The first Slate paint can report an empty geometry.  Use the
        -- viewport in that frame so F3 still creates clickable rectangles.
        local layout=StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
        local viewport=api.call(layout,"GetViewportSize",pc)
        local viewportScale=api.call(layout,"GetViewportScale",pc)
        if viewport and viewportScale and viewport.X>0 and viewport.Y>0 and viewportScale>0 then
            size={X=viewport.X/viewportScale,Y=viewport.Y/viewportScale}
        else
            return
        end
    end
    local availableWidth=math.max(560,size.X-48)
    local scale=math.min(1,availableWidth/1180,(size.Y-48)/820)
    local panelWidth=1180*scale
    local x=(size.X-panelWidth)/2
    local textWidth=1116
    local lines={
        "모드 설정  |  F3 / Esc 닫기",
        "W / S 항목 · A / D 값 조절 · Space 변경 · Tab 모드 전환",
        "",
    }
    for _,id in ipairs(ids) do
        local available=get("ready."..id)==true
        lines[#lines+1]=(self.mod==id and "▶ " or "   ")..titles[id]..(available and "" or " (비활성)")
    end
    if self.mod then
        lines[#lines+1]=""
        local rows=decode(get("rows."..tostring(self.mod)))
        local first=math.max(1,math.min(self.row-4,math.max(1,#rows-9)))
        for i=1,10 do
            local index=first+i-1; local row=rows[index]
            if row then
                lines[#lines+1]=(index==self.row and "▶ " or "   ")..row.label.." : "..row.value.."   [ − ] [ + ]"
            end
        end
        lines[#lines+1]=""
        lines[#lines+1]="입력: "..self.inputText
    else
        lines[#lines+1]=""
        lines[#lines+1]="왼쪽 목록에서 설정할 모드를 선택하세요."
    end
    lines[#lines+1]=""
    lines[#lines+1]="마우스로 모드·항목을 클릭할 수 있습니다. 숫자 입력 후 Enter 적용"
    local content=wrapText(table.concat(lines,"\n"),textWidth)
    local lineCount=1
    for _ in content:gmatch("\n") do lineCount=lineCount+1 end
    local panelHeight=math.min(820,math.max(300,72+lineCount*34))*scale
    local y=(size.Y-panelHeight)/2
    local signature=table.concat({tostring(self.mod),self.row,self.inputText,get("rows."..tostring(self.mod)) or "",size.X,size.Y,content},":")
    if self.signature==signature then return end
    self.signature=signature; self.hits={}
    self.items[1].slot:SetPosition({X=x,Y=y}); self.items[1].slot:SetSize({X=panelWidth,Y=panelHeight})
    local item=self.items[2]
    item.label:SetText(FText(content)); item.slot:SetPosition({X=x+32*scale,Y=y+28*scale})
    item.slot:SetSize({X=(textWidth-4)*scale,Y=math.max(80,panelHeight/scale-56)*scale})
    api.call(item.widget,"ForceLayoutPrepass")
    local desired=api.call(item.widget,"GetDesiredSize") or {X=1,Y=1}
    local fit=math.min(1,(textWidth-4)*scale/math.max(1,desired.X),math.max(80,panelHeight/scale-56)*scale/math.max(1,desired.Y))
    item.widget:SetRenderScale({X=fit,Y=fit})
    -- The text starts at +28 and the first mode follows the two guide lines
    -- plus one blank line.  Keep the polled mouse rectangles on those rows.
    local modeTop=(28+3*34)*scale
    for i,id in ipairs(ids) do
        local available=get("ready."..id)==true
        if available then self.hits[#self.hits+1]={mod=id,x=x+24*scale,y=y+modeTop+(i-1)*38*scale,w=320*scale,h=36*scale} end
    end
    local rows=decode(get("rows."..tostring(self.mod)))
    local first=math.max(1,math.min(self.row-4,math.max(1,#rows-9)))
    for i=1,10 do
        local index=first+i-1; local row=rows[index]
        if row then
            local cy=y+(28+(3+#ids+1)*34+(i-1)*34)*scale
            self.hits[#self.hits+1]={row=index,x=x+24*scale,y=cy,w=790*scale,h=32*scale}
            self.hits[#self.hits+1]={row=index,delta=-1,x=x+820*scale,y=cy,w=120*scale,h=32*scale}
            self.hits[#self.hits+1]={row=index,delta=1,x=x+940*scale,y=cy,w=150*scale,h=32*scale}
        end
    end
end
function Hub.new(id,api,createMessage,adapter)
    local self=setmetatable({id=id,api=api,createMessage=createMessage,adapter=adapter,items={},row=1,inputText=""},Hub)
    set("ready."..id,true); set("command."..id,nil)
    local owner=get("keyOwner")
    if not owner then set("keyOwner",id); owner=id end
    api.log("F3 Hub 준비: "..id..", owner="..tostring(owner)..", shared="..tostring(ModRef~=nil))
    if owner==id then
        local keys={0x72,0x1B,0x01,0x09,0x57,0x53,0x26,0x28,0x41,0x44,0x25,0x27,0x20,0x0D,0x08,0xBE,0x6E,0xBD,0x6D}
        for n=0,9 do keys[#keys+1]=0x30+n; keys[#keys+1]=0x60+n end
        for _,key in ipairs(keys) do RegisterKeyBind(key,function() ExecuteInGameThread(function() self:handle(key) end) end) end
    end
    local queued=false
    LoopAsync(100,function()
        if queued then return end; queued=true
        ExecuteInGameThread(function()
            local ok,err=pcall(function()
                if Hub.busy() or Hub.locked() then adapter.close() end
                local command=get("command."..id)
                if command then
                    set("command."..id,nil)
                    local index,delta,value=command:match("^(%d+)|([%-%.%d]+)|(.*)$")
                    if index and not Hub.locked() and get("targetRequest."..id)==(adapter.target and adapter.target() or "settings") then
                        adapter.apply(tonumber(index),tonumber(delta),tonumber(value))
                    end
                end
                if Hub.busy() then self:publish() end
                if get("keyOwner")==id then
                    if Hub.locked() then self:close()
                    elseif Hub.busy() then self:render()
                    elseif self.input then self:dispose() end
                end
                if self.escapeUntil and os.clock()<self.escapeUntil and adapter.suppressEscape then adapter.suppressEscape() end
            end)
            queued=false
            if not ok then self:close(); api.log("F3 메뉴 오류: "..tostring(err)) end
        end)
    end)
    return self
end
return Hub
