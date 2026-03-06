
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipLastJiShouPanel = class("TipLastJiShouPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function TipLastJiShouPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
end

function TipLastJiShouPanel:InitData()
end

function TipLastJiShouPanel:GetAllFGuiData()
    self.btn_ok = self._ui.btn_ok
    self.btn_cancel = self._ui.btn_cancel
    self.text_content = self._ui.text_content
    self.text_jishou_count = self._ui.text_jishou_count
    self.text_jiShoudiJia = self._ui.text_jiShoudiJia
    self.text_price_once = self._ui.text_price_once
    self.icon_money_1 = self._ui.icon_money_1
    self.icon_money_2 = self._ui.icon_money_2
    self.btn_close = self._ui.btn_close
end

function TipLastJiShouPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_ok,handler(self,self.BtnOKClicked))
    FGUI:setOnClickEvent(self.btn_cancel,handler(self,self.BtnCancelClicked))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function TipLastJiShouPanel:BtnOKClicked()
    local makeIndex = self.data.BagData.MakeIndex
    local count = self.historyData.count
    local price = self.historyData.price
    local lastprice = self.historyData.lastprice
    local goldType = self.historyData.type
    SL:RequestAuctionAddSell(makeIndex,count,price,lastprice,goldType)
end

function TipLastJiShouPanel:BtnCancelClicked()
    self:OnClose()
end

function TipLastJiShouPanel:RefreshUI()
    self.historyData =  SL:GetValue("PAIMAI_ADD_HISTORY_LOG",self.data.ItemData.ID)
    local MoneyData = SL:GetValue("ITEM_DATA",self.historyData.type)
    ItemUtil:RefreshItemUIByData(self.icon_money_1,MoneyData)
    ItemUtil:SetItemGradeVisible(self.icon_money_1,false)
    ItemUtil:SetItemCountVisible(self.icon_money_1,false)
    ItemUtil:RefreshItemUIByData(self.icon_money_2,MoneyData)
    ItemUtil:SetItemGradeVisible(self.icon_money_2,false)
    ItemUtil:SetItemCountVisible(self.icon_money_1,false)
    FGUI:GTextField_setText(self.text_content,string.format(GET_STRING(30000078),self.data.ItemData.Name))
    FGUI:GTextField_setText(self.text_jishou_count,self.historyData.count)
    FGUI:GTextField_setText(self.text_jiShoudiJia,SL:GetThousandSepString(self.historyData.price))
    FGUI:GTextField_setText(self.text_price_once,SL:GetThousandSepString(self.historyData.lastprice))
end

function TipLastJiShouPanel:Enter(data)
    if data then
        self.data = data
    end
    self:RegisterEvent()
    self:RefreshUI()
end

function TipLastJiShouPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "TipLastJiShouPanel", handler(self, self.OnClose))
end

function TipLastJiShouPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "TipLastJiShouPanel")
end

function TipLastJiShouPanel:OnClose()
    self.super.Close(self)
end

function TipLastJiShouPanel:Exit()
    self:RemoveEvent()
end

return TipLastJiShouPanel