local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCRecyclePanel = class("PCRecyclePanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local NUM_RECYCLE_CELLS = 40

function PCRecyclePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCRecyclePanel:GetAllFGuiData()
    self.list_recycle = self._ui.list_recycle
end

function PCRecyclePanel:InitOnClickEvent()

end

function PCRecyclePanel:CleanItemCache()
    for k,v in pairs(self._item_list) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self._item_list = {}
end

function PCRecyclePanel:InitData()
    self._recycleData = {}
    self._item_list = {}
end

function PCRecyclePanel:InitUI()
    FGUI:GList_addOnClickItemEvent(self.list_recycle,handler(self,self.ItemClicked))
    FGUI:GList_setVirtual(self.list_recycle)
    FGUI:GList_itemRenderer(self.list_recycle,handler(self,self.ItemRender))
end


-- 获取字符串和是否能购买的校验
function PCRecyclePanel:ReGroupTipsBysBack(sBack,count)
    local str = GET_STRING(30000108)
    local sBackArray = string.split(sBack,"|")
    local isCanBuy = true
    for k,v in pairs(sBackArray) do
        if v then
            local array = string.split(v,"#")
            local moneyID = tonumber(array[1])
            local moneyCost = tonumber(array[2]) * count
            local itemMoneyConfig = SL:GetValue("ITEM_DATA",moneyID)
            if tonumber(SL:GetValue("MONEY",moneyID)) < moneyCost then
                isCanBuy = false
            end
            str = str .."[color=#FF0000]".. count * moneyCost.. "[/color]".. itemMoneyConfig.Name.."," 
        end
    end
    return str,isCanBuy
end

function PCRecyclePanel:ItemClicked(eventData)
    local childIdx = FGUI:GetChildIndex(self.list_recycle, eventData.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.list_recycle, childIdx)
    local data = self._recycleData[idx + 1]
    if data then
        local itemConfig = SL:GetValue("ITEM_DATA", data.Index)
        if not string.isNullOrEmpty(itemConfig.sBack) then
            local str,isCanBuy = self:ReGroupTipsBysBack(itemConfig.sBack,data.OverLap)
            local digdata = {}
            digdata.str = string.format(GET_STRING(30000115),str,itemConfig.Name or "")
            digdata.btnDesc = { GET_STRING(1001), GET_STRING(1000)}
            digdata.callback = function(type)
                if 1 == type then
                    if not isCanBuy then
                        SL:ShowSystemTips(GET_STRING(30000087))
                        return
                    end

                    if SL:GetValue("BAG_IS_FULL", true) then
                        return
                    end

                    SL:RequestRecycleItem(data.MakeIndex)
                end
            end
            SL:OpenCommonDialog(digdata)
        end
    end
end

function PCRecyclePanel:ItemRender(idx,item)
    local bg_selected = FGUI:GetChild(item,"bg_selected")
    local node_root = FGUI:GetChild(item,"node_root")
    local data = self._recycleData[idx + 1]
    if data then
        local id = FGUI:GetID(item)
        local cacheItem = self._item_list [id]
        if cacheItem then
            ItemUtil:ItemShow_Release(cacheItem)
        end
        
        local itemView = ItemUtil:ItemShow_Create(data,node_root,{disableClick = true})
        self._item_list[id] = itemView
        FGUI:setVisible(node_root,true)
    else
        FGUI:setVisible(node_root,false)
    end

    FGUI:setVisible(bg_selected,false)
end

function PCRecyclePanel:RefreshDataAndList()
    self._recycleData = SL:GetValue("NPC_STORE_SEVER_CAN_RECYCLE_DATA")
    print("_recycleData==========================")
    SL:print_t(self._recycleData)
    FGUI:GList_setNumItems(self.list_recycle,NUM_RECYCLE_CELLS)
end

function PCRecyclePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_RES, "PCRecyclePanel", handler(self, self.RefreshDataAndList))
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_LIST_RES, "PCRecyclePanel", handler(self, self.RefreshDataAndList))
end

function PCRecyclePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_RES, "PCRecyclePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_LIST_RES, "PCRecyclePanel")
end

function PCRecyclePanel:Enter()
    self:RegisterEvent()
    SL:RequestRecycleList()
end

function PCRecyclePanel:Exit()
    self:RemoveEvent()
end

return PCRecyclePanel