local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SettingPickUpPanel = class("SettingPickUpPanel", BaseFGUILayout)

function SettingPickUpPanel:Create()
	FGUIFunction:SetCloseUIWhenClickOutside(self)
    self._packageName = "Setting"
	self._ui = FGUI:ui_delegate(self.component)
	self._list_content = self._ui.list_content
	self:InitData()
	self:InitEvent()
end 

function SettingPickUpPanel:InitData()
	local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.PICKUP_EQU)
	local strAry = string.split(args,'|')
    self._list_eqlv = {}
    self._list_eqlv_count = 0
    for _, v in pairs(strAry) do
		local lv = tonumber(v)
        table.insert(self._list_eqlv, lv)
        self._list_eqlv_count = self._list_eqlv_count + 1
    end
	
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.PICKUP_ITEM)
	local strAry = string.split(args,'|')
    self._list_item = {}
    self._list_item_count = 0
    for _, v in pairs(strAry) do
        table.insert(self._list_item, tonumber(v))
        self._list_item_count = self._list_item_count + 1
    end
	
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.PICKUP_HP)
	local strAry = string.split(args,'|')
    self._list_hp = {}
    self._list_hp_count = 0
    for _, v in pairs(strAry) do
        table.insert(self._list_hp, tonumber(v))
        self._list_hp_count = self._list_hp_count + 1
    end
	
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.PICKUP_MP)
	local strAry = string.split(args,'|')
    self._list_mp = {}
    self._list_mp_count = 0
    for _, v in pairs(strAry) do
        table.insert(self._list_mp, tonumber(v))
        self._list_mp_count = self._list_mp_count + 1
    end

	-- 关闭按钮
	self.handler_clickCloseBtn						= handler(self, self.OnClose)
    self.handler_OnEqLvShowDropItemSwitchChange     = handler(self, self.OnEqLvShowDropItemSwitchChange)
    self.handler_OnEqLvPickSwitchChange             = handler(self, self.OnEqLvPickSwitchChange)
    self.handler_OnClickCheckEqLvBtn                = handler(self, self.OnClickCheckEqLvBtn)

    self.handler_OnItemShowDropItemSwitchChange     = handler(self, self.OnItemShowDropItemSwitchChange)
    self.handler_OnItemPickSwitchChange             = handler(self, self.OnItemPickSwitchChange)

    self.handler_HpListRender                       = handler(self, self.HpListRender)
    self.handler_OnHpItemSwitchChange               = handler(self, self.OnHpItemSwitchChange)
    self.handler_MpListRender                       = handler(self, self.MpListRender)
    self.handler_OnMpItemSwitchChange               = handler(self, self.OnMpItemSwitchChange)
    self.handler_OnNotSelectAllPickItemChange       = handler(self, self.OnNotSelectAllPickItemChange)
end

function SettingPickUpPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
    FGUI:GList_itemProvider(self._list_content, handler(self, self.ContentProvider))
    FGUI:GList_itemRenderer(self._list_content, handler(self, self.ItemRender))
end

function SettingPickUpPanel:Enter(userdata)
	self:RegisterEvent()
	self:RefreshPanel()
end

function SettingPickUpPanel:Exit()

	self:RemoveEvent()
end

function SettingPickUpPanel:OnClose()
	self.super.Close(self)
end

function SettingPickUpPanel:Destroy()
end

function SettingPickUpPanel:RegisterEvent()
end

function SettingPickUpPanel:RemoveEvent()
end

function SettingPickUpPanel:RefreshPanel()
    FGUI:GList_setNumItems(self._list_content, self._list_eqlv_count + self._list_item_count + 1)
end

function SettingPickUpPanel:ContentProvider(idx)
    local total = self._list_eqlv_count + self._list_item_count
    if idx < total then
        return "ui://"..self._packageName.."/pickup_item"
    elseif idx == total then
        return "ui://"..self._packageName.."/pickup_item_potion"
    else
        release_log("ERROR SettingPickUpPanel.ContentProvider Index out of range Idx:"..idx)
        return nil
    end
end

function SettingPickUpPanel:ItemRender(idx, item)
    local total = self._list_eqlv_count
    if idx < total then
        self:ItemRender_EqLv(idx, item)
        return
    end
    total = total + self._list_item_count
    if idx < total then
        self:ItemRender_Item(idx, item)
        return
    end
    total = total + 1
    if idx < total then
        self:ItemRender_Potion(idx, item)
    end
end

function SettingPickUpPanel:ItemRender_EqLv(idx, item)
    idx = idx + 1
    local id = self._list_eqlv[idx]
    FGUI:GTextField_setText(FGUI:GetChild(item, "text_name"), string.format(GET_STRING(80000410), id))
    local btn = FGUI:GetChild(item, "switch_show")
    FGUI:SetIntData(btn, idx)
    FGUI:GButton_setOnChangedCallback(btn, self.handler_OnEqLvShowDropItemSwitchChange)
    FGUI:GButton_setSelected(btn, SL:GetValue("SETTING_SHOW_DROPITEM", SLDefine.SET_FUNC.PICKUP_EQU, id))
    local btn = FGUI:GetChild(item, "switch_pickup")
    FGUI:SetIntData(btn, idx)
    FGUI:GButton_setOnChangedCallback(btn, self.handler_OnEqLvPickSwitchChange)
    FGUI:GButton_setSelected(btn, SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_EQU, id))
    local btn = FGUI:GetChild(item, "btn_detail")
    FGUI:SetIntData(btn, idx)
    FGUI:setVisible(btn, true)
    FGUI:setOnClickEvent(btn, self.handler_OnClickCheckEqLvBtn)
    
end

function SettingPickUpPanel:OnEqLvShowDropItemSwitchChange(context)
    local btn = context.sender
    local idx = FGUI:GetIntData(btn)
    local id = self._list_eqlv[idx]
    local enable = FGUI:GButton_getSelected(btn)
    SL:SetValue("SETTING_SHOW_DROPITEM",SLDefine.SET_FUNC.PICKUP_EQU, id, enable)
end

function SettingPickUpPanel:OnEqLvPickSwitchChange(context)
    local btn = context.sender
    local idx = FGUI:GetIntData(btn)
    local id = self._list_eqlv[idx]
    local enable = FGUI:GButton_getSelected(btn)
    SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_EQU, id, enable)
end

function SettingPickUpPanel:OnClickCheckEqLvBtn(context)
    local btn = context.sender
    local idx = FGUI:GetIntData(btn)
    local id = self._list_eqlv[idx]
    
    FGUI:Open("Setting", "SettingCheckPickUpPanel", id)
end

function SettingPickUpPanel:ItemRender_Item(idx, item)
    idx = idx - self._list_eqlv_count + 1
    local id = self._list_item[idx]
    FGUI:GTextField_setText(FGUI:GetChild(item, "text_name"), SL:GetValue("ITEM_NAME", id))
    local btn = FGUI:GetChild(item, "switch_show")
    FGUI:SetIntData(btn, idx)
    FGUI:GButton_setOnChangedCallback(btn, self.handler_OnItemShowDropItemSwitchChange)
    FGUI:GButton_setSelected(btn, SL:GetValue("SETTING_SHOW_DROPITEM", SLDefine.SET_FUNC.PICKUP_ITEM, id))
    local btn = FGUI:GetChild(item, "switch_pickup")
    FGUI:SetIntData(btn, idx)
    FGUI:GButton_setOnChangedCallback(btn, self.handler_OnItemPickSwitchChange)
    FGUI:GButton_setSelected(btn, SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_ITEM, id))
    local btn = FGUI:GetChild(item, "btn_detail")
    FGUI:setVisible(btn, false)
end

function SettingPickUpPanel:OnItemShowDropItemSwitchChange(context)
    local btn = context.sender
    local idx = FGUI:GetIntData(btn)
    local id = self._list_item[idx]
    local enable = FGUI:GButton_getSelected(btn)
    SL:SetValue("SETTING_SHOW_DROPITEM", SLDefine.SET_FUNC.PICKUP_ITEM, id, enable)
end

function SettingPickUpPanel:OnItemPickSwitchChange(context)
    local btn = context.sender
    local idx = FGUI:GetIntData(btn)
    local id = self._list_item[idx]
    local enable = FGUI:GButton_getSelected(btn)
    SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_ITEM, id, enable)
end

function SettingPickUpPanel:ItemRender_Potion(idx, item)
    local hp_list = FGUI:GetChild(item, "hp_list")
    FGUI:GList_itemRenderer(hp_list, self.handler_HpListRender)
	FGUI:GList_addOnClickItemEvent(hp_list, self.handler_OnHpItemSwitchChange)
    FGUI:GList_setNumItems(hp_list, self._list_hp_count)

    local mp_list = FGUI:GetChild(item, "mp_list")
    FGUI:GList_itemRenderer(mp_list, self.handler_MpListRender)
	FGUI:GList_addOnClickItemEvent(mp_list, self.handler_OnMpItemSwitchChange)
    FGUI:GList_setNumItems(mp_list, self._list_mp_count)

    local not_select_all = FGUI:GetChild(item, "not_select_all")
    FGUI:GButton_setSelected(not_select_all, not SL:GetValue("SETTING_AUTO_PICKUP",-1, -1))
    FGUI:GButton_setOnChangedCallback(not_select_all, self.handler_OnNotSelectAllPickItemChange)
end

function SettingPickUpPanel:HpListRender(idx, item)
    idx = idx + 1
    local id = self._list_hp[idx]
    FGUI:SetIntData(item, idx)
    FGUI:GButton_setTitle(item, SL:GetValue("ITEM_NAME", id))
    local enable = SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_HP, id)
    FGUI:GButton_setSelected(item, enable)
end

function SettingPickUpPanel:OnHpItemSwitchChange(context)
    local idx = FGUI:GetIntData(context.data)
    local id = self._list_hp[idx]
    local enable = FGUI:GButton_getSelected(context.data)
    SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_HP, id, enable)
end

function SettingPickUpPanel:MpListRender(idx, item)
    idx = idx + 1
    local id = self._list_mp[idx]
    FGUI:SetIntData(item, idx)
    FGUI:GButton_setTitle(item, SL:GetValue("ITEM_NAME", id))
    local enable = SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_MP, id)
    FGUI:GButton_setSelected(item, enable)
end

function SettingPickUpPanel:OnMpItemSwitchChange(context)
    local idx = FGUI:GetIntData(context.data)
    local id = self._list_mp[idx]
    local enable = FGUI:GButton_getSelected(context.data)
    SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_MP, id, enable)
end

function SettingPickUpPanel:OnNotSelectAllPickItemChange(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    if SL:GetValue("SETTING_AUTO_PICKUP", -1, -1) == not enable then
        return
    end
    
    for k, id in pairs(self._list_hp) do
        SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_HP, id, not enable)
    end
    for k, id in pairs(self._list_mp) do
        SL:SetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_MP, id, not enable)
    end
    SL:SetValue("SETTING_AUTO_PICKUP", -1, -1, not enable)
    local nums = FGUI:GList_getNumItems(self._list_content)
    local childIdx = FGUI:GList_itemIndexToChildIndex(self._list_content, nums - 1)
    local item = FGUI:GetChildAt(self._list_content, childIdx)
    local hp_list = FGUI:GetChild(item, "hp_list")
    for i, id in ipairs(self._list_hp) do
        local idx = FGUI:GList_itemIndexToChildIndex(hp_list, i - 1)
        local tog = FGUI:GetChildAt(hp_list, idx)
        FGUI:GButton_setSelected(tog, SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_HP, id))
    end
    local mp_list = FGUI:GetChild(item, "mp_list")
    for i, id in ipairs(self._list_mp) do
        local idx = FGUI:GList_itemIndexToChildIndex(mp_list, i - 1)
        local tog = FGUI:GetChildAt(mp_list, idx)
        FGUI:GButton_setSelected(tog, SL:GetValue("SETTING_AUTO_PICKUP", SLDefine.SET_FUNC.PICKUP_MP, id))
    end
end

return SettingPickUpPanel