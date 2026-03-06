local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TopCurrencyPanel = class("TopCurrencyPanel", BaseFGUILayout)

function TopCurrencyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self.datas = {}
    self.itemMap = {}

    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setMaxWidth(self._ui.List_currency, SL:GetValue("SCREEN_WIDTH") - 390)
    else
        FGUI:setMaxWidth(self._ui.List_currency, SL:GetValue("SCREEN_WIDTH"))
    end
    FGUI:GList_itemRenderer(self._ui.List_currency, handler(self, self.OnListCurrencyRenderer))
end

function TopCurrencyPanel:Enter()
	self:RegisterEvent()
end

function TopCurrencyPanel:Refresh(idStr)
    self:InitListStr(idStr)
    table.clear(self.itemMap)
    FGUI:GList_setNumItems(self._ui.List_currency, #self.datas)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:GList_resizeToFit(self._ui.List_currency)
    end
end

function TopCurrencyPanel:Exit()
	self:RemoveEvent()

end

function TopCurrencyPanel:Destroy()
    self._ui = nil	
end

----------------------------------------------------------------------------

function TopCurrencyPanel:InitListStr(idStr)
    table.clear(self.datas)
    local strs = string.split(idStr, "#")
    for k, str in pairs(strs) do
        local id = tonumber(str)
        if id then
            table.insert(self.datas, id)
        end
    end
end

function TopCurrencyPanel:OnListCurrencyRenderer(index, item)
    local id = self.datas[index + 1]
    if not id then return end
    local itemUI = FGUI:ui_delegate(item)
    self.itemMap[id] = itemUI
    local itemData = SL:GetValue("ITEM_DATA", id)
    local count = SL:GetValue("ITEM_COUNT", id)
    local countStr = SL:GetSimpleNumber(count, 2)

    FGUI:GLoader_setUrl(itemUI.Loader_icon, SL:GetValue("ITEM_ICON_PATH_BY_ITEM_ID", id))
    FGUI:GTextField_setText(itemUI.Text_count, countStr)
    FGUI:setVisible(itemUI.Image_lock, SL:GetMetaValue("ITEM_IS_BIND", itemData))
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setOnRollOverEvent(item, handler(self, self.OnRollOverItem, itemData))
        FGUI:setOnRollOutEvent(item, handler(self, self.OnRollOutItem))
    else
        FGUI:setOnClickEvent(item, handler(self, self.OnClickItem, itemData))
    end
end

function TopCurrencyPanel:OnClickItem(itemData, eventData)
    FGUIFunction:OpenItemTips({itemData = itemData,hideButtons = true})
end

function TopCurrencyPanel:OnRollOverItem(itemData, eventData)
    FGUIFunction:OpenItemTips({itemData = itemData,hideButtons = true})
end

function TopCurrencyPanel:OnRollOutItem(eventData)
    FGUIFunction:CloseItemTips()
end

function TopCurrencyPanel:OnCurrencyChange(moneyID, moneyValue)
    local itemUI = self.itemMap[moneyID]
    if not itemUI then return end
    local count = moneyValue or SL:GetValue("ITEM_COUNT", moneyID)
    local countStr = SL:GetSimpleNumber(count, 2)
    FGUI:GTextField_setText(itemUI.Text_count, countStr)
end

-----------------------------------注册事件--------------------------------------
function TopCurrencyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_CHANGE, "TopCurrencyPanel",  handler(self,self.OnCurrencyChange))
end

function TopCurrencyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MONEY_CHANGE, "TopCurrencyPanel")
end


return TopCurrencyPanel