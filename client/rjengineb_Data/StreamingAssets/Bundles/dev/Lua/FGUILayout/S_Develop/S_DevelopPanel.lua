local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_DevelopPanelEx = require("FGUILayer/S_DevelopPanelEx")
local S_DevelopPanel = class("S_DevelopPanel", S_DevelopPanelEx)

local resolutionList = {
    "1334x750",
    "1600x900",
    "1920x1080"
}

local pcResolutionList = {
    "800x600",
    "1024x768",
    "1334x750",
    "1280x1024",
    "1600x900",
    "1600x1200",
    "1680x1050",
    "1920x1080"
}

function S_DevelopPanel:Create()
    self.super:Create()
    self._ui = FGUI:ui_delegate(self.component)

    FGUI:GComboBox_setOnChangeCallback(self._ui.ComboBox_resolution, handler(self, self.OnResolutionSetChanged))
    FGUI:GComboBox_setOnChangeCallback(self._ui.ComboBox_mode, handler(self, self.OnModeSetChanged))
    FGUI:setOnClickEvent(self._ui.btn_sure, handler(self, self.OnClickSure))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function S_DevelopPanel:Enter()
    self.super:Enter()
    self:InitData()
    self:InitUI()
end

function S_DevelopPanel:Exit()

end

function S_DevelopPanel:Destroy()
    self._selectResolutionIdx = 0
    self._selectModeIdx = 0
    self._ui = nil
end

function S_DevelopPanel:InitData()
    self._data = {}
    self._selectResolutionIdx = 0
    self._selectModeIdx = 0     -- 0: 手机端 1: PC端
    self._showList = {}

    local dataStr = self._originDataStr
    if dataStr and dataStr ~= "" then
        self._data = SL:JsonDecode(dataStr) or {}
    end

    self._selectModeIdx = 0
    if tonumber(self._data["oper_mode"]) == 1 then -- oper_mode: 1: PC端 2: 手机端
        self._selectModeIdx = 1
    end
end

function S_DevelopPanel:InitUI()
    FGUI:GComboBox_setSelectedIndex(self._ui.ComboBox_mode, self._selectModeIdx)
    self:UpdateResolution()
end

function S_DevelopPanel:UpdateResolution(isModeChange)
    local setResolution = self._data["resolution"]
    local list = self._selectModeIdx == 0 and resolutionList or pcResolutionList
    self._selectResolutionIdx = 0
    if setResolution and setResolution ~= "" and not SL:GetValue("IS_EDITOR") then
        for i = 1, #list do
            if list[i] == setResolution then
                self._selectResolutionIdx = i
                break 
            end
        end
    else
        local sWidth = SL:GetValue("SCREEN_WIDTH")
        local sHeight = SL:GetValue("SCREEN_HEIGHT")
        for i = 1, #list do
            local t = string.split(list[i], "x")
            if tonumber(t[1]) == sWidth and tonumber(t[2]) == sHeight then
                self._selectResolutionIdx = i
                break 
            end
        end
    end
    -- 模式改变
    if isModeChange and not SL:GetValue("IS_EDITOR") then
        if self._selectModeIdx == 0 then
            -- 手机端默认1334x750
            self._selectResolutionIdx = 1
        else
            -- PC端默认1024x768
            self._selectResolutionIdx = 2
        end
        self._data["resolution"] = list[self._selectResolutionIdx]
    elseif SL:GetValue("IS_EDITOR") and self._selectResolutionIdx == 0 then
        self._data["resolution"] = nil
    end

    self._showList = SL:CopyData(list)
    if SL:GetValue("IS_EDITOR") then
        table.insert(self._showList, 1, "编辑器默认")
    elseif self._selectResolutionIdx ~= 0 then
        self._selectResolutionIdx = self._selectResolutionIdx - 1
    end
    FGUI:GComboBox_setItems(self._ui.ComboBox_resolution, self._showList)
    FGUI:GComboBox_setSelectedIndex(self._ui.ComboBox_resolution, self._selectResolutionIdx)
end

function S_DevelopPanel:OnResolutionSetChanged()
    self._selectResolutionIdx = FGUI:GComboBox_getSelectedIndex(self._ui.ComboBox_resolution)
    if SL:GetValue("IS_EDITOR") then
        if not self._selectResolutionIdx or self._selectResolutionIdx == 0 then
            self._data["resolution"] = nil
        else
            self._data["resolution"] = self._showList[self._selectResolutionIdx]
        end
    else
        if not self._selectResolutionIdx then
            self._data["resolution"] = nil
        else
            self._data["resolution"] = self._showList[self._selectResolutionIdx + 1]
        end
    end
end

function S_DevelopPanel:OnModeSetChanged()
    local lastSelectIdx = self._selectModeIdx
    self._selectModeIdx = FGUI:GComboBox_getSelectedIndex(self._ui.ComboBox_mode)
    if self._selectModeIdx == 0 then
        self._data["oper_mode"] = 2
    else
        self._data["oper_mode"] = self._selectModeIdx
    end

    if lastSelectIdx ~= self._selectModeIdx then
        self:UpdateResolution(true)
    end
end


return S_DevelopPanel