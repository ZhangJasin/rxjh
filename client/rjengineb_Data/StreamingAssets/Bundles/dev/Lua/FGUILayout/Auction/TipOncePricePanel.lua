local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipOncePricePanel = class("TipOncePricePanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
function TipOncePricePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self:InitData()
    self:GetAllFGuiData()
    self:InitClickEvent()
end

function TipOncePricePanel:InitData()
    self.itemShow = nil
end
function TipOncePricePanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.text_price = self._ui.text_price
    self.btn_cancel = self._ui.btn_cancel
    self.btn_givePrice = self._ui.btn_givePrice
    self.icon_Money1 = self._ui.icon_Money1
    self.item_node = self._ui.item_node
    self.mask = self._ui.mask
    self.text_name = self._ui.text_name
end

function TipOncePricePanel:Destory()
    self:CleanCache()
end

function TipOncePricePanel:CleanCache()
    if self.itemShow then
        ItemUtil:ItemShow_Release(self.itemShow)
    end
end

function TipOncePricePanel:InitClickEvent()
    FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_cancel,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_givePrice,handler(self,self.BtnPriceGiveClicked))
end

function TipOncePricePanel:RefreshUI()
    self:CleanCache()

    local itemData = SL:GetValue("ITEM_DATA",self.data.index)
    self.itemShow = ItemUtil:ItemShow_Create(self.data.useritem,self.item_node)
    
    FGUI:GTextField_setText(self.text_name,itemData.Name)
    FGUI:GTextField_setText(self.text_price,SL:GetThousandSepString(self.data.lastprice))

    local moneyData = SL:GetValue("ITEM_DATA",self.data.type)
    ItemUtil:RefreshItemUIByData(self.icon_Money1,moneyData)
    ItemUtil:SetItemGradeVisible(self.icon_Money1,false)
end


function TipOncePricePanel:BtnPriceGiveClicked()
    -- 一口价
    SL:RequestAuctionJoinAuction(self.data.useritem.MakeIndex, self.data.lastprice,self.data.useritem.OverLap)
end

function TipOncePricePanel:Enter(data)
    if data then
        self.data = data
    end
    self:RegisterEvent()
    self:RefreshUI()
end

function TipOncePricePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "TipOncePricePanel", handler(self,self.OnClose))
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_BUY_FAIL_TIPS, "TipOncePricePanel", handler(self,self.OnClose))
end

function TipOncePricePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "TipOncePricePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_BUY_FAIL_TIPS, "TipOncePricePanel")
end


function TipOncePricePanel:Exit()
    self:RemoveEvent()
end

function TipOncePricePanel:OnClose()
    self.super.Close(self)
end


return TipOncePricePanel