local State={}
function State.combat(api,pc)
    local piece=api.read(pc,"Pawn") or api.call(pc,"GetPawn")
    return api.valid(piece) and api.call(piece,"IsA","/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C")==true
end
function State.capture(api,pc)
    return {pc=pc,mouse=api.read(pc,"bShowMouseCursor"),click=api.read(pc,"bEnableClickEvents"),
        hover=api.read(pc,"bEnableMouseOverEvents"),combat=State.combat(api,pc)}
end
function State.restore(api,state,focus)
    if not state or not api.valid(state.pc) then return end
    local pc=state.pc
    local lib=StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local combat=state.combat
    if type(combat)~="boolean" then combat=State.combat(api,pc) end
    if combat then
        api.call(lib,"SetInputMode_GameOnly",pc)
        api.call(lib,"SetFocusToGameViewport")
    else
        if not api.valid(focus) then
            for _,widget in ipairs(api.findAll("UserWidget") or {}) do
                if api.call(widget,"IsInViewport")==true then focus=widget; break end
            end
        end
        api.call(lib,"SetInputMode_GameAndUI",pc,focus,false,false)
    end
    local mouse=state.mouse
    local click=state.click
    local hover=state.hover
    if type(mouse)~="boolean" then mouse=not combat end
    if type(click)~="boolean" then click=not combat end
    if type(hover)~="boolean" then hover=not combat end
    api.write(pc,"bShowMouseCursor",mouse)
    api.write(pc,"bEnableClickEvents",click)
    api.write(pc,"bEnableMouseOverEvents",hover)
end
return State
