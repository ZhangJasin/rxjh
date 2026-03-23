local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCQuickUseTips = class("PCQuickUseTips", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function PCQuickUseTips:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
end

function PCQuickUseTips:InitData()
    self._itemPool = Queue.new()
    self._itemData = nil
    self._initTips = false
end

function PCQuickUseTips:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_equip, handler(self, self.OnClickEquip))
    FGUI:setOnClickEvent(self._ui.check_show, handler(self, self.OnClickIsShow))
end

function PCQuickUseTips:Enter(data)
    if not data then
        self.super.Close(self)
    end
end

function PCQuickUseTips:Exit()
    self._itemData = nil
    self._itemPool:clear()

    self._initTips = false

    if self.Timer then
        SL:UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self._itemShow then
        ItemUtil:ItemShow_Release(self._itemShow)
        self._itemShow = nil
    end
end

function PCQuickUseTips:Close()
    if not self._initTips then
        self._itemPool:pop_back()
        self._initTips = true
    end

    if self._itemPool:size() > 0 then
        local data = self._itemPool:pop_back()
        self._itemData = data
        self._itemCDTime = SL:GetValue("GAME_DATA", "UseCountdown") or 5
        self:UpdateItem(data)
        return
    end

    if self._itemPool:size() == 0 then
        self.super.Close(self)
    end
end

function PCQuickUseTips:Refresh(data)
    if not data then
        return
    end

    self._itemData = data

    -- 是否是装备
    local isEquip = SL:GetValue("ITEMTYPE", self._itemData) == SL:GetValue("ITEMTYPE_ENUM").Equip

    -- 是否左右手
    local equipPos = nil
    if isEquip then
        equipPos = SL:GetValue("EQUIP_POSLIST_BY_STDMODE", self._itemData.StdMode)
    end

    -- 是否重复(道具和非左右手装备 去重)
    for _, v in pairs(self._itemPool._data) do
        if data.ID == v.ID then
            if not equipPos or (equipPos and #equipPos == 1) then 
                self._itemPool:pop_back()
                return
            end 
        end
    end

    self._itemPool:push(data)

    self._itemCDTime = SL:GetValue("GAME_DATA", "UseCountdown") or 5
    self:UpdateItem(data)

    if not self.Timer then
        self.Timer = SL:Schedule(handler(self, self.TipsTick), 1)
    end
end

local extData = {itemTipData = {from = ItemFrom.BAG, hideButtons = true}, disableClick = true}
function PCQuickUseTips:UpdateItem(itemData)
    if not itemData then
        return
    end

    -- name
    FGUI:GTextField_setText(self._ui.text_name, itemData.Name)

    -- icon
    if self._itemShow then
        ItemUtil:ItemShow_Release(self._itemShow)
    end
    self._itemShow = ItemUtil:ItemShow_Create(itemData, self._ui.Node_item, extData)
    FGUI:setOnRollOverEvent(self._itemShow.component, function()
        FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
    end)

    FGUI:setOnRollOutEvent(self._itemShow.component, function()
        FGUIFunction:CloseItemTips()
    end)

    -- cd
    if self._itemCDTime > 0 then
        FGUI:GTextField_setText(self._ui.text_cd, "(" .. self._itemCDTime .. ")")
    else
        FGUI:GTextField_setText(self._ui.text_cd, "")
    end

    -- btn text
    local isEquip = SL:GetValue("ITEMTYPE", self._itemData) == SL:GetValue("ITEMTYPE_ENUM").Equip
    if isEquip then
        FGUI:GTextField_setText(self._ui.text_title, GET_STRING(60013003))
        FGUI:GButton_setTitle(self._ui.btn_equip, GET_STRING(60013001))
    else
        FGUI:GTextField_setText(self._ui.text_title, GET_STRING(60013004))
        FGUI:GButton_setTitle(self._ui.btn_equip, GET_STRING(60013002))
    end

    -- checkbox 
    local isSel = FGUIFunction:GetQuickUseItemShow(itemData.ID)
    FGUI:GButton_setSelected(self._ui.check_show, isSel)
    local repeatSwitch = SL:GetValue("SETTING_QUICKWINDOW_NOT_REPEATED_SHOW")
    FGUI:setVisible(self._ui.check_show, not repeatSwitch)
    FGUI:setVisible(self._ui.text_no, not repeatSwitch)
end

function PCQuickUseTips:TipsTick()
    self._itemCDTime = self._itemCDTime - 1
    if self._itemCDTime > 0 then
        FGUI:GTextField_setText(self._ui.text_cd, "(" .. self._itemCDTime .. ")")
    else
        self:Close()
    end
end

function PCQuickUseTips:OnClickEquip()
    local useCount = self._itemData.OverLap
    SL:RequestUseItem(self._itemData, nil, nil, useCount)
    self:Close()
end

function PCQuickUseTips:OnClickIsShow(context)
    local isSel = FGUI:GButton_getSelected(context.sender)
    local itemID = self._itemData.ID
    FGUIFunction:SetQuickUseItemShow(itemID, isSel)
end

return PCQuickUseTips
