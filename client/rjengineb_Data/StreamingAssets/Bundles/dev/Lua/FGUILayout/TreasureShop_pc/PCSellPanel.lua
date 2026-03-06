local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSellPanel = class("PCSellPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local RES_COUNT = 24
function PCSellPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function PCSellPanel:GetAllFGuiData()
    self.list_canSell = self._ui.list_canSell
    self.btn_once_sell = self._ui.btn_once_sell
    self.checkbox_filter = self._ui.checkbox_filter
    self.combox_filter = self._ui.combox_filter
    self.list_resGet = self._ui.list_resGet
    self.ctrl_checkbox = FGUI:getController(self.checkbox_filter,"isSelected")
    self._ctrl_tabList = {}
    self._grade_max = 5
    for index = 1 , 6 do
        self["btn_tab_"..index] = self._ui["btn_tab_"..index]
        self._ctrl_tabList[index] = FGUI:getController(self["btn_tab_"..index],"isSelected")
    end
end

-- 切换页签显示
function PCSellPanel:RefreshTabChose(index)
    self._item_type = index
    for i = 1,6 do
        self._ctrl_tabList[i].selectedIndex = index == i and 0 or 1
    end
end

function PCSellPanel:TabButtonClicked(index)
    self:RefreshTabChose(index)
    self:RefreshDataAndView()
end

function PCSellPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_once_sell,handler(self,self.BtnOnceSellClicked))
    FGUI:setOnClickEvent(self.btn_tab_1,handler(self,self.BtnTab1Clicked))
    FGUI:setOnClickEvent(self.btn_tab_2,handler(self,self.BtnTab2Clicked))
    FGUI:setOnClickEvent(self.btn_tab_3,handler(self,self.BtnTab3Clicked))
    FGUI:setOnClickEvent(self.btn_tab_4,handler(self,self.BtnTab4Clicked))
    FGUI:setOnClickEvent(self.btn_tab_5,handler(self,self.BtnTab5Clicked))
    FGUI:setOnClickEvent(self.btn_tab_6,handler(self,self.BtnTab6Clicked))
    FGUI:setOnClickEvent(self.checkbox_filter,handler(self,self.CheckBoxClicked))
    FGUI:GComboBox_setOnChangeCallback(self.combox_filter,handler(self,self.ComBoxFilterSelected))
end

function PCSellPanel:ComBoxFilterSelected()
    if self.ctrl_checkbox.selectedIndex == 0 then
        -- 选出所有符合品质的物品
        self:FilterSellList()
        self:RefreshDataAndView()
    end
end

-- 选中所有品质以下的物品
function PCSellPanel:FilterSellList()
    self._preSellList = {}

    local filterGrade = self.GradeCount - self.combox_filter.selectedIndex
    for k,v in pairs(self._canSellData_list) do
        if tonumber(v.Grade) <= tonumber(filterGrade) then
            self._preSellList[v.BagData.MakeIndex] = v
        end
    end
end

function PCSellPanel:CheckBoxClicked()
    if self.ctrl_checkbox.selectedIndex == 0 then
        self.ctrl_checkbox.selectedIndex = 1
        self._preSellList = {}
    else
        self.ctrl_checkbox.selectedIndex = 0
        self:FilterSellList()
    end
    self:RefreshDataAndView()
end

function PCSellPanel:RefreshCheckBox()
    if self.ctrl_checkbox.selectedIndex == 0 then
        self:FilterSellList()
    else
        self._preSellList = {}
    end

    self:RefreshDataAndView()
end

function PCSellPanel:BtnTab1Clicked()
    self:TabButtonClicked(1)
end

function PCSellPanel:BtnTab2Clicked()
    self:TabButtonClicked(2)
end

function PCSellPanel:BtnTab3Clicked()
    self:TabButtonClicked(3)
end

function PCSellPanel:BtnTab4Clicked()
    self:TabButtonClicked(4)
end

function PCSellPanel:BtnTab5Clicked()
    self:TabButtonClicked(5)
end

function PCSellPanel:BtnTab6Clicked()
    self:TabButtonClicked(6)
end

-- 一键卖出
function PCSellPanel:BtnOnceSellClicked()
    self:SendToSell(nil)
end

function PCSellPanel:SendToSell(num)
    if table.isNullOrEmpty(self._preSellList) then
        return
    end

    local makeIndexListStr = ""
    if not num then
        for k,v in pairs(self._preSellList) do
            makeIndexListStr = k .. "|".. makeIndexListStr
        end
    else
        -- 单卖
        for k,v in pairs(self._preSellList) do
            makeIndexListStr = k .. "#".. num
        end 
    end
    SL:RequestNPCStoreSell(self.serverGroupID,makeIndexListStr)
end

function PCSellPanel:InitData()
    -- tabcontrollList
    self._ctrl_tabList = {}

    self._item_list = {}

    self._item_res_list = {}
end

function PCSellPanel:RefreshData()
    -- 预售列表
    self._preSellList = {}
    -- 能被卖的物品
    self._canSellData_list = {}
    -- 获取开放格子数量
    self._bag_open_counts = SL:GetValue("BAG_OPEN_SIZE")
    -- 总花费
    self._total_cost =  0
end

function PCSellPanel:RefreshDataAndView()
    print("刷新列表---------------")
    self._canSellData_list = self:TabFilterData()
    --SL:print_t(self._canSellData_list)
    FGUI:GList_setNumItems(self.list_canSell,self._bag_open_counts)
    self:RefreshResGetList()
end

-- 过滤数据
function PCSellPanel:TabFilterData()
    local data = SL:GetValue("NPC_STORE_CAN_SELL_DATA_BY_GROUP_ID",self.serverGroupID)
    local filterData = {}

    for k,v in pairs(data) do
        if self._item_type == 1 or v.itemType  == self._item_type then
            table.insert(filterData,v)
        end
    end
    return filterData
end

function PCSellPanel:InitUI()
    FGUI:GList_itemRenderer(self.list_canSell,handler(self,self.SellItemRender))
    FGUI:GList_setVirtual(self.list_canSell)

    FGUI:GList_itemRenderer(self.list_resGet,handler(self,self.ResGetItemRender))
    FGUI:GList_setVirtual(self.list_resGet)
    

    local data = SL:GetValue("ITEM_ALL_GRADE_NAME")
    self.GradeCount = table.count(data)
    local colorStrs = {}
    local tableLength = table.count(data)
    for k,v in pairs(data) do
        if k == 1 then
            colorStrs[tableLength - k + 1] = v.name
        else
            colorStrs[tableLength - k + 1] = string.format(GET_STRING(30000062),"[color="..v.color.."]"..v.name .."[/color]")
        end
    end

    FGUI:GComboBox_setItems(self.combox_filter, colorStrs)
    FGUI:GComboBox_setVisibleItemCount(self.combox_filter,table.count(data))
end

function PCSellPanel:CleanItemCache()
    for k,v in pairs(self._item_list) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    for k,v in pairs(self._item_res_list) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end


    self._item_list = {}
    self._item_res_list = {}
end

-- 刷新可以获取的资源列表
function PCSellPanel:RefreshResGetList()
    self.Res = {}
    self.ResMoneyIDs = {}
    print("RefreshResGetList")
    --SL:print_t(self._preSellList)

    for k,v in pairs(self._preSellList) do
        if v and v.Price then
            for moneyID,moneyCount in pairs(v.Price) do
                if not self.Res[moneyID] then
                    self.Res[moneyID] = v.BagData.OverLap * moneyCount
                else
                    self.Res[moneyID] = self.Res[moneyID] + v.BagData.OverLap * moneyCount
                end
            end
        end
    end

    self.ResMoneyIDs = table.keys(self.Res or {})
    FGUI:GList_setNumItems(self.list_resGet,RES_COUNT)
end

function PCSellPanel:ResGetItemRender(idx,item)
    local index = idx + 1
    local node_root = FGUI:GetChild(item,"node_root")
    local id = FGUI:GetID(item)
    local moneyID = self.ResMoneyIDs[index]
    local moneyCount = self.Res[moneyID]
    if self.Res[moneyID] then
        local cacheItem = self._item_res_list[id]
        if cacheItem then
            ItemUtil:ItemShow_Release(cacheItem)
        end

        local moneyData = SL:GetValue("ITEM_DATA",moneyID)
        self._item_res_list[id] = ItemUtil:ItemShow_Create(moneyData,node_root,{disableClick = true,
        OverLap = moneyCount})
        FGUI:setVisible(node_root,true)
    else
        FGUI:setVisible(node_root,false)    
    end
end
function PCSellPanel:SellItemRender(idx, item)
    local index = idx + 1
    local node_root = FGUI:GetChild(item,"node_root")
    local bg_selected = FGUI:GetChild(item,"bg_selected")
    local id = FGUI:GetID(item)
    local data = self._canSellData_list[index]
    if data then
        local cacheItem = self._item_list [id]
        if cacheItem then
            ItemUtil:ItemShow_Release(cacheItem)
        end
        local itemView = ItemUtil:ItemShow_Create(data.BagData,node_root,{disableClick = true})
        self._item_list[id] = itemView
        local pressCall = function()
            self:SellItemClicked(item)
        end

        local longPressCall = function()
            -- if data.BagData.OverLap > 1 then
                self:SellOnItem(data)
            -- else
                -- self:SellItemClicked(item)
            -- end
        end
        ItemUtil:SetLongPressOrClick(item,pressCall,longPressCall,1)
        FGUI:setVisible(node_root,true)
        FGUI:setVisible(bg_selected,self._preSellList[data.BagData.MakeIndex])
    else
        FGUI:setVisible(bg_selected,false)
        FGUI:setVisible(node_root,false)
    end
end

function PCSellPanel:SellOnItem(data)
    local _data = {}
    _data.dialogType = 1
    _data.title = GET_STRING(30000055)
    _data.itemData = SL:GetValue("ITEM_DATA", data.BagData.Index)
    _data.minNum = 1
    _data.multPrice = data.Price    -- 多种货币
    _data.costName = SL:GetValue("ITEM_DATA",SL:GetValue("GAME_DATA", "NPCStoreMoneySell") or 1).Name
    _data.maxNum = data.BagData.OverLap
    _data.OverLap = data.BagData.OverLap
    _data.btnNames = {GET_STRING(1000),GET_STRING(30000055)}
    _data.btnClicked = function(isOk,num)
        if isOk == 0 then
            FGUI:Close("Common_pc", "PCCommonItemSplitDialog")
        elseif isOk == 1 then
            self._preSellList = {}
            self._preSellList[data.BagData.MakeIndex] = data
            self:SendToSell(num)
            FGUI:Close("Common_pc", "PCCommonItemSplitDialog")
        elseif isOk == 2 then
            FGUI:Close("Common_pc", "PCCommonItemSplitDialog")
        end
    end
    FGUIFunction:OpenCommonItemSplitDialog(_data)
end

function PCSellPanel:SellItemClicked(item)
    local bg_selected = FGUI:GetChild(item,"bg_selected")
    local childIdx = FGUI:GetChildIndex(self.list_canSell, item)
    local idx = FGUI:GList_childIndexToItemIndex(self.list_canSell, childIdx)
    local data = self._canSellData_list[idx + 1]
    if data and data.BagData then
        if self._preSellList[data.BagData.MakeIndex] then
            -- 去除
            self._preSellList[data.BagData.MakeIndex] = nil
            FGUI:setVisible(bg_selected,false)
        else
            -- 添加
            self._preSellList[data.BagData.MakeIndex] = data
            FGUI:setVisible(bg_selected,true)
        end
        
        self:RefreshResGetList()
    end
end

-- 刷新数量

function PCSellPanel:SellSuccess()
    self:RefreshData()
    self:RefreshDataAndView()
end


function PCSellPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_SELL_RES, "PCSellPanel", handler(self, self.SellSuccess))
end

function PCSellPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_SELL_RES,"PCSellPanel")
end

function PCSellPanel:Enter(serverGroupID)
    if serverGroupID then
        self.serverGroupID = serverGroupID
    end
    self:RegisterEvent()
    self:RefreshData()
    self:TabButtonClicked(1)
    self:RefreshDataAndView()
    self:RefreshCheckBox()
end

function PCSellPanel:Exit()
    self:RemoveEvent()
end

return PCSellPanel