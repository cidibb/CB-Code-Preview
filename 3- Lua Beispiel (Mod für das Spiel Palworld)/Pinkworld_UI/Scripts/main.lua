local ColorLightPink = {
    R = 1.0,
    G = 0.3,
    B = 0.6,
    A = 1
}

local ColorDarkPink = {
    R = 1.0,
    G = 0.357,
    B = 0.722,
    A = 0.75
}

local function SetAssetColor(path, color) 
    LoadAsset(path)
    RegisterHook(path .. ":SetEnable", function (self)
        self:get().Icon:SetColorAndOpacity(color)
    end)
end

NotifyOnNewObject("/Script/UMG.Image", function (Context)
    local WidgetTree = Context:GetOuter()
    if WidgetTree:IsValid() then
        local Parent = WidgetTree:GetOuter()
        if Parent:GetClass():GetFName():ToString() == "WBP_Title_MenuButton_C" then
            Context:SetColorAndOpacity(ColorLightPink)
        end
    end
end)


NotifyOnNewObject("/Game/Pal/Blueprint/UI/PalTextBlock/BP_PalTextBlock.BP_PalTextBlock_C", function (Context)
        Context.Font.OutlineSettings.OutlineColor = ColorDarkPink
end)


