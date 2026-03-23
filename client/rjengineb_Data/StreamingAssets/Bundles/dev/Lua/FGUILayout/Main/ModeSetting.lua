local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ModeSetting = class("ModeSetting", BaseFGUILayout)

function ModeSetting:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:SetCloseUIWhenClickOutside(self)
    FGUI:setOnClickEvent(self._ui.Button_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.Button_ok, handler(self, self.OnSure))
    FGUI:setOnClickEvent(self._ui.Button_fightMode1, handler(self, self.ClickMode1))
    FGUI:setOnClickEvent(self._ui.Button_fightMode2, handler(self, self.ClickMode2))
    FGUI:setOnClickEvent(self._ui.Button_fightMode3, handler(self, self.ClickMode3))
    FGUI:GList_itemRenderer(self._ui.List_mode, handler(self, self.OnListModeRender))

    self._modes = {}

    self:InitModeDatas()
    FGUI:GList_setNumItems(self._ui.List_mode, #self._modes)

    self._findTargetMode = SL:GetValue("SETTING_FIND_TARGET_MODE")
    self:SelectMode()
end

function ModeSetting:SelectMode()
    FGUI:GButton_setSelected(self._ui.Button_fightMode1, self._findTargetMode == SLDefine.FIND_TARGET_MODE.PRIORITY_MONSTER)
    FGUI:GButton_setSelected(self._ui.Button_fightMode2, self._findTargetMode == SLDefine.FIND_TARGET_MODE.PRIORITY_PLAYER)
    FGUI:GButton_setSelected(self._ui.Button_fightMode3, self._findTargetMode == SLDefine.FIND_TARGET_MODE.ONLY_PLAYER)
end

function ModeSetting:ClickMode1()
    self._findTargetMode = SLDefine.FIND_TARGET_MODE.PRIORITY_MONSTER
    self:SelectMode()
end

function ModeSetting:ClickMode2()
    self._findTargetMode = SLDefine.FIND_TARGET_MODE.PRIORITY_PLAYER
    self:SelectMode()
end

function ModeSetting:ClickMode3()
    self._findTargetMode = SLDefine.FIND_TARGET_MODE.ONLY_PLAYER
    self:SelectMode()
end

function ModeSetting:Enter()
    self:InitView()
end

function ModeSetting:Exit()

end

function ModeSetting:Destroy()
    self._ui = nil	
end


--------------------------------------------------------

function ModeSetting:InitModeDatas()
    table.clear(self._modes)
    local config = SL:GetValue("SERVER_PKMODE_LIST") or SL:GetValue("PKMODE_CONFIG")
    if not config then return end
    
    for k, v in pairs(config) do
        table.insert(self._modes, v)
    end
    if #self._modes > 2 then
        table.sort(self._modes, function(a,b)
            if not a.Order or not b.Order then
                return false
            end
            return a.Order < b.Order
        end)
    end
end

function ModeSetting:InitView()
    local mode = SL:GetValue("PKMODE")
    for k, v in pairs(self._modes) do
        if v and v.ID == mode then
            FGUI:GList_setSelectedIndex(self._ui.List_mode, k - 1)
            break
        end
    end
end


function ModeSetting:OnListModeRender(index, item)
    local idx = index + 1
    local data = self._modes[idx]
    if not idx then return end
    local Loader_icon = FGUI:GetChild(item, "Loader_icon")
    local Text_desc = FGUI:GetChild(item, "Text_desc")
    FGUI:GLoader_setUrl(Loader_icon, "ui://Main/main_player_mode" .. data.ID)
    FGUI:GTextField_setText(Text_desc, data.Desc)
end

function ModeSetting:OnSure()
    local index = FGUI:GList_getSelectedIndex(self._ui.List_mode)
    local idx = index + 1
    local mode = self._modes[idx]
    if mode and mode.ID ~= SL:GetValue("PKMODE") then
        SL:RequestChangePKMode(mode.ID)
    end
    SL:SetValue("SETTING_FIND_TARGET_MODE", self._findTargetMode)

    self:Close()
end


return ModeSetting