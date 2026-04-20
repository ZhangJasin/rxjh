local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local compoundMain_PC = class("compoundMain_PC", BaseFGUILayout)
local compoundMain_PCData = SL:RequireFile("FGUILayout/A_Compound_PC/compoundMain_PCData")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local FGUI = SL:RequireFile("FGUI/FGUI")
local Message = SL:RequireFile("Net/Message")

local Compound = require("game_config/cfgcsv/Compound")
-- 使用系统自带Item配置表
local ItemConfig = SL:GetValue("ITEM_CONFIG") or require("game_config/cfgcsv/Item")

local SUBSCRIBE_TOKENS = {}

function compoundMain_PC:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._data = compoundMain_PCData:getInstance()
    
    FGUI:SetCloseUIWhenClickOutside(self)
    
    -- 关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("A_Compound_PC", "compoundMain_PC")
    end)
    
    -- 一级分组列表
    FGUI:GList_addOnClickItemEvent(self._ui.list_group1, function(context)
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.list_group1)
        local group1List = self._data:GetGroup1List()
        if group1List[selectedIndex + 1] then
            self._data:SelectGroup1(group1List[selectedIndex + 1])
        end
    end)
    
    -- 二级分组列表
    FGUI:GList_addOnClickItemEvent(self._ui.list_group2, function(context)
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.list_group2)
        local group2List = self._data:GetGroup2List(self._data._currentGroup1)
        if group2List[selectedIndex + 1] then
            self._data:SelectGroup2(group2List[selectedIndex + 1])
        end
    end)
    
    -- 合成按钮
    FGUI:setOnClickEvent(self._ui.btn_compound, function()
        self:OnCompoundClick()
    end)
    
    self:_initListRenderers()
end

function compoundMain_PC:_initListRenderers()
    -- 一级分组列表渲染
    FGUI:GList_setItemRenderer(self._ui.list_group1, function(item, index)
        local group1List = self._data:GetGroup1List()
        local text = group1List[index + 1] or ""
        FGUI:GTextField_setText(item.title, text)
        
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.list_group1)
        FGUI:GObject_setVisible(item.sel, selectedIndex == index)
    end)
    
    -- 二级分组列表渲染
    FGUI:GList_setItemRenderer(self._ui.list_group2, function(item, index)
        local group2List = self._data:GetGroup2List(self._data._currentGroup1)
        local text = group2List[index + 1] or ""
        FGUI:GTextField_setText(item.title, text)
        
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.list_group2)
        FGUI:GObject_setVisible(item.sel, selectedIndex == index)
    end)
end

function compoundMain_PC:Enter(data)
    self:_subscribeEvents()
    self:RefreshUI()
end

function compoundMain_PC:Refresh(data)
    self:RefreshUI()
end

function compoundMain_PC:Exit()
    self:_unsubscribeEvents()
end

function compoundMain_PC:Destroy()
    self:_unsubscribeEvents()
end

function compoundMain_PC:_subscribeEvents()
    for _, token in ipairs(SUBSCRIBE_TOKENS) do
        self._data:Unsubscribe(token)
    end
    SUBSCRIBE_TOKENS = {}
    
    local token1 = self._data:Subscribe("compound_group1_changed", handler(self, self.OnGroup1Changed))
    table.insert(SUBSCRIBE_TOKENS, token1)
    
    local token2 = self._data:Subscribe("compound_group2_changed", handler(self, self.OnGroup2Changed))
    table.insert(SUBSCRIBE_TOKENS, token2)
end

function compoundMain_PC:_unsubscribeEvents()
    for _, token in ipairs(SUBSCRIBE_TOKENS) do
        self._data:Unsubscribe(token)
    end
    SUBSCRIBE_TOKENS = {}
end

function compoundMain_PC:OnGroup1Changed(data)
    self:RefreshGroup2List()
    self:RefreshCompoundInfo()
end

function compoundMain_PC:OnGroup2Changed(data)
    self:RefreshCompoundInfo()
end

function compoundMain_PC:RefreshUI()
    self:RefreshGroup1List()
    self:RefreshGroup2List()
    self:RefreshCompoundInfo()
end

function compoundMain_PC:RefreshGroup1List()
    local group1List = self._data:GetGroup1List()
    FGUI:GList_setNumItems(self._ui.list_group1, #group1List)
    
    local currentIndex = 0
    for i, g1 in ipairs(group1List) do
        if g1 == self._data._currentGroup1 then
            currentIndex = i - 1
            break
        end
    end
    FGUI:GList_setSelectedIndex(self._ui.list_group1, currentIndex)
    FGUI:GList_RefreshVirtualList(self._ui.list_group1)
end

function compoundMain_PC:RefreshGroup2List()
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    FGUI:GList_setNumItems(self._ui.list_group2, #group2List)
    
    local currentIndex = 0
    for i, g2 in ipairs(group2List) do
        if g2 == self._data._currentGroup2 then
            currentIndex = i - 1
            break
        end
    end
    FGUI:GList_setSelectedIndex(self._ui.list_group2, currentIndex)
    FGUI:GList_RefreshVirtualList(self._ui.list_group2)
end

function compoundMain_PC:RefreshCompoundInfo()
    local config = self._data:GetCurrentCompoundConfig()
    if not config then
        return
    end
    
    self:RefreshCostItems(config)
    self:RefreshTargetItem(config)
    self:RefreshCurrencyCost(config)
    
    FGUI:GTextField_setText(self._ui.txt_success_rate, string.format("成功率:%d%%", config.SuccessRate))
end

function compoundMain_PC:RefreshCostItems(config)
    local costItems = self._data:GetCostItems(config)
    
    local container = self._ui.cost_items_container
    FGUI:GObject_removeChildren(container)
    
    for i, itemData in ipairs(costItems) do
        local item = self:_createCostItem(itemData, i)
        if item then
            FGUI:GObject_setXY(item, 0, (i - 1) * 120)
            FGUI:GObject_setWidth(item, FGUI:GObject_getWidth(container))
        end
    end
end

function compoundMain_PC:_createCostItem(itemData, index)
    local item = FGUI:GComponent_createFromURL("ui://A_Compound_PC/CostItem")
    if not item then
        return nil
    end
    
    local itemID = itemData.itemID
    local needCount = itemData.count
    local haveCount = self:_GetItemCount(itemID)
    
    local iconPath = self:_GetItemIconPath(itemID)
    if iconPath then
        FGUI:GImage_setURL(FGUI:GComponent_getChild(item, "icon"), iconPath)
    end
    
    FGUI:GTextField_setText(FGUI:GComponent_getChild(item, "txt_need"), string.format("%d", needCount))
    FGUI:GTextField_setText(FGUI:GComponent_getChild(item, "txt_have"), string.format("%d/%d", haveCount, needCount))
    
    if haveCount >= needCount then
        FGUI:GTextField_setColor(FGUI:GComponent_getChild(item, "txt_have"), 0x00FF00)
    else
        FGUI:GTextField_setColor(FGUI:GComponent_getChild(item, "txt_have"), 0xFF0000)
    end
    
    return item
end

function compoundMain_PC:RefreshTargetItem(config)
    local targetItemID = config.TargetItemID
    local targetCount = config.TargetItemCount
    
    local iconPath = self:_GetItemIconPath(targetItemID)
    if iconPath then
        FGUI:GImage_setURL(FGUI:GComponent_getChild(self._ui, "target_icon"), iconPath)
    end
    
    FGUI:GTextField_setText(FGUI:GComponent_getChild(self._ui, "target_count"), string.format("×%d", targetCount))
end

function compoundMain_PC:RefreshCurrencyCost(config)
    local currencyType = config.CostCurrencyType
    local currencyCount = config.CostCurrencyCount
    
    if currencyType == 0 or currencyCount == 0 then
        FGUI:GObject_setVisible(self._ui.currency_cost_panel, false)
        return
    end
    
    FGUI:GObject_setVisible(self._ui.currency_cost_panel, true)
    
    local currencyIcons = {
        [1] = "ui://Common_PC/gold_icon",
        [2] = "ui://Common_PC/silver_icon",
        [3] = "ui://Common_PC/diamond_icon",
    }
    
    local iconURL = currencyIcons[currencyType] or ""
    if iconURL ~= "" then
        FGUI:GImage_setURL(FGUI:GComponent_getChild(self._ui.currency_cost_panel, "icon"), iconURL)
    end
    
    local playerCurrency = self:_GetPlayerCurrency(currencyType)
    FGUI:GTextField_setText(FGUI:GComponent_getChild(self._ui.currency_cost_panel, "txt_cost"), 
        string.format("%d/%d", playerCurrency, currencyCount))
end

function compoundMain_PC:OnCompoundClick()
    local compoundID = self._data:GetCurrentCompoundID()
    if compoundID <= 0 then
        return
    end
    
    local config = self._data:GetCurrentCompoundConfig()
    if not config then
        return
    end
    
    local costItems = self._data:GetCostItems(config)
    for _, itemData in ipairs(costItems) do
        local haveCount = self:_GetItemCount(itemData.itemID)
        if haveCount < itemData.count then
            FGUI:ShowTips(string.format("材料不足:需要%d个", itemData.count))
            return
        end
    end
    
    if config.CostCurrencyType > 0 and config.CostCurrencyCount > 0 then
        local playerCurrency = self:_GetPlayerCurrency(config.CostCurrencyType)
        if playerCurrency < config.CostCurrencyCount then
            FGUI:ShowTips("货币不足")
            return
        end
    end
    
    self._data:RequestCompound(compoundID)
end

function compoundMain_PC:_GetItemCount(itemID)
    local bagData = SL:GetValue("BAG_DATA")
    if bagData and bagData[itemID] then
        return bagData[itemID].count or 0
    end
    return 0
end

function compoundMain_PC:_GetItemIconPath(itemID)
    if ItemConfig[itemID] then
        return ItemConfig[itemID].icon
    end
    return nil
end

function compoundMain_PC:_GetPlayerCurrency(currencyType)
    local playerData = SL:GetValue("PLAYER_DATA")
    if not playerData then
        return 0
    end
    
    if currencyType == 1 then
        return playerData.gold or 0
    elseif currencyType == 2 then
        return playerData.silver or 0
    elseif currencyType == 3 then
        return playerData.diamond or 0
    end
    return 0
end

return compoundMain_PC
