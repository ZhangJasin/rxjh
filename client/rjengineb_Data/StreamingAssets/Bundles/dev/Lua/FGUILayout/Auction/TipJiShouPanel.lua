local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipJiShouPanel = class("TipJiShouPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function TipJiShouPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
end

function TipJiShouPanel:InitData()
    self.ItemMoney1 = nil
    self.ItemMoney2 = nil
    self.ItemShow = nil
end

function TipJiShouPanel:GetAllFGuiData()
    self.btn_ok = self._ui.btn_ok
    self.btn_cancel = self._ui.btn_cancel
    self.text_name = self._ui.text_name
    self.text_jiShoudiJia = self._ui.text_jiShoudiJia
    self.text_price_once = self._ui.text_price_once
    self.icon_money_1 = self._ui.icon_money_1
    self.icon_money_2 = self._ui.icon_money_2
    self.item_node = self._ui.item_node
    self.btn_close = self._ui.btn_close
end

function TipJiShouPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_ok,handler(self,self.BtnOKClicked))
    FGUI:setOnClickEvent(self.btn_cancel,handler(self,self.BtnCancelClicked))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function TipJiShouPanel:BtnOKClicked()
    local cfgPm = self.data._cfgPaiMaiData
    local costType = cfgPm.nCurrency
    local costItemConfig = SL:GetValue("ITEM_DATA",tonumber(costType))
    local cursDeposit = SL:GetValue("MONEY",tonumber(costType))
    local needMoney = 0
    if cfgPm.nDepositRate and cfgPm.sDepositLimit then
        local needSDeposit = self.data._cur_jishou_diJia * (cfgPm.nDepositRate/10000)
        local arr = string.split(cfgPm.sDepositLimit,"|")
        local min = tonumber(arr[1])
        needMoney = math.min(min,needSDeposit)
    elseif cfgPm.nDepositRate and not cfgPm.sDepositLimit then
        local needSDeposit = self.data._cur_jishou_diJia * (cfgPm.nDepositRate/10000)
        needMoney = needSDeposit
    elseif not cfgPm.nDepositRate and not cfgPm.sDepositLimit then
        local arr = string.split(cfgPm.sDepositLimit,"|")
        needMoney = tonumber(arr[1])
    end
        
    -- 押金不够
    if needMoney > tonumber(cursDeposit) then
        SL:ShowSystemTips(string.format(GET_STRING(30000061),costItemConfig.Name))
        self:OnClose()
        return
    end
    -- 上架数量有没有超过
    local curSPmCount = #SL:GetValue("PAIMAI_SELF_DATA")
    local maxPmCount = SL:GetValue("GAME_DATA","MaxPaimaiCount")
    if curSPmCount >= maxPmCount then
        SL:ShowSystemTips(string.format(GET_STRING(30000068),maxPmCount))
        return
    end

    local makeIndex = self.data.BagData.MakeIndex
    local count = self.data._cur_jishou_count
    local price = self.data._cur_jishou_diJia
    local lastprice = self.data._cur_once_price
    local goldType = self.data._cur_costType
    SL:RequestAuctionAddSell(makeIndex,count,price,lastprice,goldType)
end

function TipJiShouPanel:BtnCancelClicked()
    self:OnClose()
end

function TipJiShouPanel:InitUI()
    FGUI:GTextField_setText(self.text_name,self.data.ItemData.Name)
    FGUI:GTextField_setText(self.text_jiShoudiJia, SL:GetThousandSepString(self.data._cur_jishou_diJia))
    FGUI:GTextField_setText(self.text_price_once,SL:GetThousandSepString( self.data._cur_once_price))

    self.data.ItemData.OverLap = self.data._cur_jishou_count
    self.data.ItemData.isShowCount = true
    ItemUtil:RefreshItemUIByData(self.item_node,self.data.ItemData)
    ItemUtil:SetItemCountByItemData(self.item_node,self.data.ItemData)
    local itemData = SL:GetValue("ITEM_DATA",self.data._cur_costType)
    if itemData then
        if self.ItemMoney1 then
            self.ItemMoney1:UpdateItemData(itemData)
        else
            self.ItemMoney1 = ItemMoney.new(self.icon_money_1,itemData)
        end


        if self.ItemMoney2 then
            self.ItemMoney2:UpdateItemData(itemData)
        else
            self.ItemMoney2 = ItemMoney.new(self.icon_money_2,itemData)    
        end

        self.ItemMoney1:UpdateItemCounts(false)
        self.ItemMoney2:UpdateItemCounts(false)
    end
end

function TipJiShouPanel:Enter(data)
    self:RegisterEvent()
    if data then
        self.data = data
    end

    self:InitUI()
end

function TipJiShouPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "TipJiShouPanel", handler(self, self.OnClose))
end


function TipJiShouPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "TipJiShouPanel")
end


function TipJiShouPanel:OnClose()
    self.super.Close(self)
end

function TipJiShouPanel:Exit()
    self:RemoveEvent()
end

return TipJiShouPanel