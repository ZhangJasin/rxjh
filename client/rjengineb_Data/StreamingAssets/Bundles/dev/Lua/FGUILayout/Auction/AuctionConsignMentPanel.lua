local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local AuctionConsignMentPanel = class("AuctionConsignMentPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function AuctionConsignMentPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitData()
    self:InitUI()
end

function AuctionConsignMentPanel:InitUI()
    FGUI:GList_itemRenderer(self.list_consignment,handler(self,self.ListViewCellsItemRenderer))
    FGUI:GList_setVirtual(self.list_consignment)
end

function AuctionConsignMentPanel:InitData()
    self.MaxPaimaiCount = SL:GetValue("GAME_DATA", "AuctionCountMax") or 8
    self.mySellsData = {}
    self.scheduleSet = {}
    self.cellList = {}
end

function AuctionConsignMentPanel:ListViewCellsItemRenderer(idx,cell)
    local index = idx + 1
    local data = self.mySellsData[index]
    local item_node = FGUI:GetChild(cell,"item_node")
    local text_item_name = FGUI:GetChild(cell,"text_item_name")
    local text_price_jp = FGUI:GetChild(cell,"text_price_jp")
    local text_price_once = FGUI:GetChild(cell,"text_price_once")
    local text_time = FGUI:GetChild(cell,"text_time")
    local item_money1 = FGUI:GetChild(cell,"item_money1")
    local item_money2 = FGUI:GetChild(cell,"item_money2")
    local btn_down = FGUI:GetChild(cell,"btn_down")
    local status_jp = FGUI:GetChild(cell,"status_jp")
    local id = FGUI:GetID(cell)
    if data then
        if self.scheduleSet[id] then
            SL:UnSchedule(self.scheduleSet[id])
            self.scheduleSet[id] = nil
        end

        local callBack = function()
            local curTime = SL:GetValue("SERVER_TIME")
            if data.endtime - curTime <= 0 then
                if self.scheduleSet[id] then
                    SL:UnSchedule(self.scheduleSet[id])
                    self.scheduleSet[id] = nil
                end
            else
                FGUI:GTextField_setText(text_time,SecondToHMS(math.ceil(data.endtime - curTime) ,true, false))
            end
        end
        callBack()
        self.scheduleSet[id] = SL:Schedule(callBack, 1)

        if not string.isNullOrEmpty(data.currname) then
            FGUI:GTextField_setText(status_jp,data.currname)
        else
            FGUI:GTextField_setText(status_jp,GET_STRING(30000204))
        end

        local itemData = SL:GetValue("ITEM_DATA",data.useritem.Index)
        FGUI:GTextField_setText(text_item_name,itemData.Name)
        FGUI:GTextField_setText(text_price_jp,data.currprice ~= 0 and SL:GetThousandSepString(data.currprice) or SL:GetThousandSepString(data.price))
        FGUI:GTextField_setText(text_price_once,SL:GetThousandSepString(data.lastprice))

        local moneyData = SL:GetValue("ITEM_DATA",data.type)
        ItemUtil:RefreshItemUIByData(item_money1,moneyData)
        ItemUtil:SetItemGradeVisible(item_money1,false)
        ItemUtil:SetItemCountVisible(item_money1,false)
        ItemUtil:RefreshItemUIByData(item_money2,moneyData)
        ItemUtil:SetItemGradeVisible(item_money2,false)
        ItemUtil:SetItemCountVisible(item_money2,false)

        if self.cellList[id] then
            ItemUtil:ItemShow_Release(self.cellList[id])
        end

        self.cellList[id] =  ItemUtil:ItemShow_Create(data.useritem,item_node)
        if self.cellList[id].hideArrow then
            self.cellList[id]:hideArrow()
        end
        local function BtnDownClicked()
            SL:RequestAuctionBackSell(data.useritem.MakeIndex)
        end
        FGUI:setOnClickEvent(btn_down,BtnDownClicked)
    end
end

function AuctionConsignMentPanel:CleanCache()
    for k,v in pairs(self.cellList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self.cellList = {}
    self._ui = nil
end

function AuctionConsignMentPanel:RefreshCount()
    FGUI:GTextField_setText(self.text_num,GET_STRING(30000067) .. table.nums(self.mySellsData) .. "/"..self.MaxPaimaiCount)
end

function AuctionConsignMentPanel:GetAllFGuiData()
    self.list_consignment = self._ui.list_consignment
    self.btn_consignment = self._ui.btn_consignment
    self.btn_help = self._ui.btn_help
    self.text_num = self._ui.text_num
    self.ctrl_isHaveShangJia = FGUI:getController(self.component,"isHaveShangJia")
end

function AuctionConsignMentPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_consignment,handler(self,self.btnConSignmentClicked))
    FGUI:setOnClickEvent(self.btn_help,handler(self,self.btnHelpClicked))
end

-- 帮助按钮点击
function AuctionConsignMentPanel:btnHelpClicked()
    local data = {}
    data.title = GET_STRING(30000098)
    data.str = GET_STRING(30000099)
    SL:OpenCommonHelpDialog(data)
end

-- 寄售按钮点击
function AuctionConsignMentPanel:btnConSignmentClicked()
    FGUI:Open("Auction","TipConsignmentPanel")
end

function AuctionConsignMentPanel:Enter()
    self:RegisterEvent()
    self:RequestQueryMySell()
    SL:ComponentAttach(SLDefine.SUIComponentTable.AuctionConsignment, self._ui.Node_attach)
end

function AuctionConsignMentPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.AuctionConsignment)
    self:RemoveEvent()
end

function AuctionConsignMentPanel:RefreshData()
    print("刷新我上架的物品")
    self.mySellsData = SL:GetValue("PAIMAI_SELF_DATA")
    local nums = table.nums(self.mySellsData)
    FGUI:Controller_setSelectedIndex(self.ctrl_isHaveShangJia,nums > 0 and 1 or 0)
    FGUI:GList_setNumItems(self.list_consignment,nums )
    self:RefreshCount()
end

function AuctionConsignMentPanel:RequestQueryMySell()
    SL:RequestAuctionMySells()
end

function AuctionConsignMentPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MY_AUCTION_MY_SELLS, "AuctionConsignMentPanel", handler(self,self.RefreshData))
end

function AuctionConsignMentPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MY_AUCTION_MY_SELLS, "AuctionConsignMentPanel")
end

return AuctionConsignMentPanel
