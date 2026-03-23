local GPluginPath = _G.PluginPath

local TYPE_TEXT_NONE = 0
local TYPE_TEXT_CLIP = 1
local TYPE_TEXT_ROLL = 2

local TYPE_TEXT_MAP = {
    [TYPE_TEXT_NONE] = "无",
    [TYPE_TEXT_CLIP] = "裁剪",
    [TYPE_TEXT_ROLL] = "滚动",
}

local textExtend = {}
function textExtend.create()
    textExtend.panel = CS.FairyGUI.UIPackage.CreateObject("TextExtend", "View")
    textExtend.Input_rollSpeed = textExtend.panel:GetChild("Input_rollSpeed"):GetChild("title")
    textExtend.Input_rollStartDelay = textExtend.panel:GetChild("Input_rollStartDelay"):GetChild("title")
    textExtend.Input_rollEndDelay = textExtend.panel:GetChild("Input_rollEndDelay"):GetChild("title")
    textExtend.combo = textExtend.panel:GetChild("comboBox")

    textExtend.combo.onChanged:Set(textExtend.OnChangeCombo)
    textExtend.Input_rollSpeed.onSubmit:Set(textExtend.UpdateCustomData)
    textExtend.Input_rollSpeed.onFocusOut:Set(textExtend.UpdateCustomData)
    textExtend.Input_rollStartDelay.onSubmit:Set(textExtend.UpdateCustomData)
    textExtend.Input_rollStartDelay.onFocusOut:Set(textExtend.UpdateCustomData)
    textExtend.Input_rollEndDelay.onSubmit:Set(textExtend.UpdateCustomData)
    textExtend.Input_rollEndDelay.onFocusOut:Set(textExtend.UpdateCustomData)
    return textExtend.panel
end

function textExtend.updateUI()
    local sels = App.activeDoc.inspectingTargets
    local obj = sels[0]
    if not obj or obj.objectType ~= "text" then return false end
    local typeIdx, arg1, arg2, arg3 = textExtend.GetCustomInfo(obj.customData)
    textExtend.combo.selectedIndex = typeIdx
    textExtend.combo.title = TYPE_TEXT_MAP[typeIdx]
    textExtend.Input_rollSpeed.text = arg1 or ""
    textExtend.Input_rollStartDelay.text = arg2 or ""
    textExtend.Input_rollEndDelay.text = arg3 or ""
    return true
end

function textExtend.GetCustomInfo(customData)
    if not customData or customData == "" then return TYPE_TEXT_NONE end
    local strs = string.split(customData, "\n")
    for k, str in pairs(strs) do
        if string.startWith(str, string.format("%s#", TYPE_TEXT_CLIP)) then
            return TYPE_TEXT_CLIP
        elseif string.startWith(str, string.format("%s#", TYPE_TEXT_ROLL)) then
            local infos = string.split(str, "#")
            return TYPE_TEXT_ROLL, tonumber(infos[2]) or "", tonumber(infos[3]) or "", tonumber(infos[4]) or ""
        end
    end
    return TYPE_TEXT_NONE
end

function textExtend.GetEmptyCustomStrs(customData)
    local newStrs = {}
    if not customData or customData == "" then return newStrs, true end
    local strs = string.split(customData, "\n")
    for k, str in pairs(strs) do
        if string.startWith(str, string.format("%s#", TYPE_TEXT_CLIP)) or 
            string.startWith(str, string.format("%s#", TYPE_TEXT_ROLL)) then
            --过滤
        else
            table.insert(newStrs, str)
        end
    end
    return newStrs, false
end

function textExtend.OnChangeCombo()
    local typeIdx = textExtend.combo.selectedIndex
    if typeIdx == TYPE_TEXT_CLIP or typeIdx == TYPE_TEXT_ROLL then
        local obj = App.activeDoc.inspectingTarget
        if obj and obj.docElement then
            obj.docElement:SetProperty("singleLine", "true")
        end
    end
    textExtend.UpdateCustomData()
end

function textExtend.UpdateCustomData()
    local obj = App.activeDoc.inspectingTarget
    if not obj or not obj.docElement then return end
    local typeIdx = textExtend.combo.selectedIndex
    local customData = obj.customData
    local strs, isEmpty = textExtend.GetEmptyCustomStrs(customData)
    if typeIdx == TYPE_TEXT_CLIP then
        --裁剪
        table.insert(strs, string.format("%s#", TYPE_TEXT_CLIP))
    elseif typeIdx == TYPE_TEXT_ROLL then
        --滚动
        local speed = textExtend.Input_rollSpeed.text
        local startDelay = textExtend.Input_rollStartDelay.text
        local endDelay = textExtend.Input_rollEndDelay.text
        table.insert(strs, string.format("%s#%s#%s#%s", TYPE_TEXT_ROLL, tonumber(speed) or "", tonumber(startDelay) or "", tonumber(endDelay) or ""))
    else
        --无
        if isEmpty then return end
    end
    local newStr = table.concat(strs, "\n")
    if newStr == customData then return end
    obj.docElement:SetProperty("customData", newStr)
end


App.inspectorView:AddInspector(textExtend, "TextExtend", "文本扩展");
App.docFactory:ConnectInspector("TextExtend", "mixed", false, false);
App.pluginManager:LoadUIPackage(GPluginPath .. '/Package/TextExtend')