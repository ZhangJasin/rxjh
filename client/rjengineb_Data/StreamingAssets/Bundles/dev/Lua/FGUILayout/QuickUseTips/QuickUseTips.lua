local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local QuickUseTips = class("QuickUseTips", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function QuickUseTips:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
end

function QuickUseTips:InitData()
    self._itemPool = Queue.new()
    self._itemData = nil
    self._initTips = false
end

function QuickUseTips:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_equip, handler(self, self.OnClickEquip))
    FGUI:setOnClickEvent(self._ui.check_show, handler(self, self.OnClickIsShow))
end

function QuickUseTips:Enter(data)
    if not data then
        self.super.Close(self)
    end
end

function QuickUseTips:Exit()
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

function QuickUseTips:Close()
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

function QuickUseTips:Refresh(data)
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

    -- 是否重复
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

local extData = {itemTipData = {from = ItemFrom.BAG, hideButtons = true}}
function QuickUseTips:UpdateItem(itemData)
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
end

function QuickUseTips:TipsTick()
    self._itemCDTime = self._itemCDTime - 1
    if self._itemCDTime > 0 then
        FGUI:GTextField_setText(self._ui.text_cd, "(" .. self._itemCDTime .. ")")
    else
        self:Close()
    end
end

function QuickUseTips:OnClickEquip()
    local useCount = self._itemData.OverLap
    SL:RequestUseItem(self._itemData, nil, nil, useCount)
    self:Close()
end

function QuickUseTips:OnClickIsShow(context)
    local isSel = FGUI:GButton_getSelected(context.sender)
    local itemID = self._itemData.ID
    SL:SetQuickUseItemShow(itemID, isSel)
end

return QuickUseTips
