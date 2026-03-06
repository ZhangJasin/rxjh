local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipJingjiaPanel = class("TipJingjiaPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function TipJingjiaPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self:InitData()
    self:GetAllFGuiData()
    self:InitClickEvent()
end

function TipJingjiaPanel:InitData()
    self._itemShow = nil
    -- 总百分比加成
    self._bonus  = 0
end

function TipJingjiaPanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.text_price = self._ui.text_price
    self.btn_cancel = self._ui.btn_cancel
    self.btn_givePrice = self._ui.btn_givePrice
    self.icon_Money1 = self._ui.icon_Money1
    self.icon_Money2 = self._ui.icon_Money2
    self.mask = self._ui.mask
    self.text_price_player_give = self._ui.text_price_player_give
    self.text_name = self._ui.text_name
    self.item_node = self._ui.item_node
    self.cbx_select_price = self._ui.cbx_select_price
end

function TipJingjiaPanel:Destory()
    self:CleanCache()
end

function TipJingjiaPanel:CleanCache()
    if self._itemShow then
        ItemUtil:ItemShow_Release(self._itemShow)
    end
end

function TipJingjiaPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_cancel,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_givePrice,handler(self,self.BtnPriceGiveClicked))
    FGUI:GComboBox_setOnChangeCallback(self.cbx_select_price,handler(self,self.CBXPriceChanged))
end

function TipJingjiaPanel:CBXPriceChanged()
    local select = FGUI:GComboBox_getSelectedIndex(self.cbx_select_price) + 1
    self._bonus = 1 + self.BiddingGear[select]*0.0001
    FGUI:GTextField_setText(self.text_price_player_give, SL:GetThousandSepString(math.floor(self.curJoinPrice * self._bonus)))
end

function TipJingjiaPanel:RefreshUI()
    self:CleanCache()

    local itemData = SL:GetValue("ITEM_DATA",self.data.index)
    self._itemShow = ItemUtil:ItemShow_Create(self.data.useritem,self.item_node)

    local paiMaiConfig = SL:GetValue("PAIMAI_CONFIG",itemData.nPaimaiConfig)
    print(paiMaiConfig.BiddingGear)
    self.BiddingGear = string.split(paiMaiConfig.BiddingGear,"#")

    local strs = {}
    for k,v in ipairs(self.BiddingGear) do
        strs[k] = string.format(GET_STRING(30000081),math.floor(tonumber(v)*0.01) .. "%")
    end 
    FGUI:GComboBox_setItems(self.cbx_select_price, strs)

    FGUI:GTextField_setText(self.text_name,itemData.Name)
    FGUI:GTextField_setText(self.text_price,SL:GetThousandSepString(self.curJoinPrice))

    local moneyData = SL:GetValue("ITEM_DATA",self.data.type)
    ItemUtil:RefreshItemUIByData(self.icon_Money1,moneyData)
    ItemUtil:RefreshItemUIByData(self.icon_Money2,moneyData)
    ItemUtil:SetItemGradeVisible(self.icon_Money1,false)
    ItemUtil:SetItemGradeVisible(self.icon_Money2,false)
  
    self:CBXPriceChanged()
end

-- 出价
function TipJingjiaPanel:BtnPriceGiveClicked()
    SL:RequestAuctionJoinAuction(self.data.useritem.MakeIndex,math.floor(self.curJoinPrice * self._bonus) ,self.data.useritem.OverLap)
end

function TipJingjiaPanel:Enter(data)
    if data then
        self.data = data
    end
    
    self.curJoinPrice = self.data.currprice ~= 0 and self.data.currprice or self.data.price
    self:RegisterEvent()
    self:RefreshUI()
end

function TipJingjiaPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "TipJingjiaPanel", handler(self,self.OnClose))
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_BUY_FAIL_TIPS, "TipJingjiaPanel", handler(self,self.OnClose))
end

function TipJingjiaPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "TipJingjiaPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_BUY_FAIL_TIPS, "TipJingjiaPanel")
end

function TipJingjiaPanel:Exit()
    self:RemoveEvent()
end

function TipJingjiaPanel:OnClose()
    self.super.Close(self)
end


return TipJingjiaPanel