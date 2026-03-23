local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local RechargePanel = class("RechargePanel", BaseFGUILayout)

RechargePanel.PAY_TYPE = {
    ALIPAY = 1,
    HUABEI = 2,
    WEIXIN = 3
}

function RechargePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUIFunction:setWindowDrag(self.component, self._ui.bg)
    else
	    FGUIFunction:SetCloseUIWhenClickOutside(self)
    end
    
    self._productID = nil       -- 商品ID
    self._exchange = 0          -- 获得货币值
    self._payChannel = nil      -- 选择的支付渠道 微信/支付宝/花呗
    self._products = {}         -- 商品列表
    self._productCells = {}
    self._inputMin = tonumber(SL:GetValue("GAME_DATA", "minRecharge")) or 10
    self._inputMax = tonumber(SL:GetValue("GAME_DATA", "maxRecharge")) or 99999999

    self:InitRechargeUI()
    self:InitProducts()
    self:InitEvent()
end

function RechargePanel:OnClose()
	self.super.Close(self)
end

function RechargePanel:Enter()
    SL:ComponentAttach(SLDefine.SUIComponentTable.Recharge, self._ui.Node_attach)
end

function RechargePanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.Recharge)
end

function RechargePanel:InitRechargeUI()
    self:SelectChannel(self.PAY_TYPE.ALIPAY)

    FGUI:GTextField_setText(self._ui.text_servername, SL:GetValue("SERVER_NAME"))
    FGUI:GTextField_setText(self._ui.text_rolename, SL:GetValue("USER_NAME"))

    FGUI:GTextField_setText(self._ui.input_money, self._inputMin)

    -- 第三方支付不显示花呗
    local bSDKPay = SL:GetValue("IS_SDK_PAY")
    if bSDKPay then
        FGUI:setVisible(self._ui.panel_huabei, false)
        FGUI:setVisible(self._ui.label_more, false)
        FGUI:setVisible(self._ui.panel_weixin, true)
    end

    -- SDK登录不显示支付方式选择
    if SL:GetValue("IS_SDK_LOGIN") then
        FGUI:setVisible(self._ui.text_5, false)
        FGUI:setVisible(self._ui.panel_alipay, false)
        FGUI:setVisible(self._ui.panel_weixin, false)
        FGUI:setVisible(self._ui.panel_huabei, false)
        FGUI:setVisible(self._ui.label_more, false)
    end
end

function RechargePanel:InitProducts()
    -- 商品列表
    self._products = SL:GetValue("RECHARGE_PRODUCTS")


    FGUI:GList_itemRenderer(self._ui.list_coins, handler(self, self.OnInitListItem))
    FGUI:GList_setNumItems(self._ui.list_coins, #self._products)
    FGUI:GList_addOnClickItemEvent(self._ui.list_coins, handler(self, self.OnClickListItem))
    -- 默认选择
    if #self._products > 0 then
        self:SelectProduct(1)
    end
end

function RechargePanel:OnInitListItem(idx, item)
    local index = idx + 1
    local product = self._products[index]
    if product then
        local nameText = FGUI:GetChild(item, "text_name")
        local ratioText = FGUI:GetChild(item, "text_ratio")
        FGUI:GTextField_setText(nameText, product.currency_name)
        FGUI:GTextField_setText(ratioText, string.format("1:%s", product.currency_ratio))
    end
end

function RechargePanel:OnClickListItem()
   local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_coins) + 1
   self._productID = self._products[selectIdx] and self._products[selectIdx].currency_itemid

   self:UpdateExchange()
   self:UpdateDesc()
end

function RechargePanel:SelectProduct(selectIdx)
    if not selectIdx then
        return
    end

    self._productID = self._products[selectIdx] and self._products[selectIdx].currency_itemid
    FGUI:GList_setSelectedIndex(self._ui.list_coins, selectIdx - 1)

    self:UpdateExchange()
    self:UpdateDesc()
end

function RechargePanel:InitEvent()
    -- close
    FGUI:addOnClickEvent(self._ui.btn_close, handler(self, self.OnClose))

    -- channel
    FGUI:addOnClickEvent(self._ui.btn_alipay, function()
        self:SelectChannel(self.PAY_TYPE.ALIPAY)
    end)

    FGUI:addOnClickEvent(self._ui.btn_weixin, function()
        self:SelectChannel(self.PAY_TYPE.WEIXIN)
    end)

    FGUI:addOnClickEvent(self._ui.btn_huabei, function()
        self:SelectChannel(self.PAY_TYPE.HUABEI)
    end)

    FGUI:addOnClickEvent(self._ui.label_more, function()
        local show = FGUI:getVisible(self._ui.panel_huabei)
        if not show then
            FGUI:setVisible(self._ui.panel_huabei, true)
            FGUI:setVisible(self._ui.label_more, false)
        end
    end)

    -- money
    FGUI:GTextInput_addOnChanged(self._ui.input_money, handler(self, self.OnInputMoneyEvent))
    FGUI:GTextInput_addOnSubmit(self._ui.input_money, handler(self, self.OnInputMoneyEvent))

    -- submit
    FGUI:addOnClickEvent(self._ui.btn_submit, handler(self, self.OnClickSubmitPay))
end

function RechargePanel:SelectChannel(channel)
    if self._payChannel == channel then
        return
    end

    self._payChannel = channel

    FGUI:setVisible(self._ui.img_flag1, self._payChannel == self.PAY_TYPE.ALIPAY)
    FGUI:setVisible(self._ui.img_flag2, self._payChannel == self.PAY_TYPE.WEIXIN)
    FGUI:setVisible(self._ui.img_flag3, self._payChannel == self.PAY_TYPE.HUABEI)

end

function RechargePanel:OnInputMoneyEvent()
    local inputNum = tonumber(FGUI:GTextField_getText(self._ui.input_money)) or self._inputMin
    inputNum = math.floor(inputNum)
    if inputNum < self._inputMin then
        SL:ShowSystemTips(string.format("最低充值%s元", self._inputMin))
        inputNum = math.max(inputNum, self._inputMin)
    end

    if inputNum > self._inputMax then
        SL:ShowSystemTips(string.format("最高充值%s元", self._inputMax))
        inputNum = math.min(inputNum, self._inputMax)
    end

    FGUI:GTextField_setText(self._ui.input_money, inputNum)
    self:UpdateExchange()
end

function RechargePanel:UpdateExchange()
    -- 选择货币
    if not self._productID then
        FGUI:GTextField_setText(self._ui.text_exchange, "")
        return
    end

    -- 有货币信息
    local product = SL:GetValue("RECHARGE_PRODUCT_BY_ID", self._productID)
    if not product then
        FGUI:GTextField_setText(self._ui.text_exchange, "")
        return
    end
    
    -- 输入是否有效
    local inputNum = tonumber(FGUI:GTextField_getText(self._ui.input_money)) or 0
    if inputNum <= 0 then
        FGUI:GTextField_setText(self._ui.text_exchange, "")
        return nil
    end

    -- 实际获得
    local exchange = 0

    -- 充值
    if product.currency_ratio and tonumber(product.currency_ratio) then
        exchange = exchange + inputNum * tonumber(product.currency_ratio)
    end

    -- 赠送
    if product.present_ratio and tonumber(product.present_ratio) and tonumber(product.present_ratio) > 0 then
        exchange = exchange + exchange * (tonumber(product.present_ratio) / 100)
    end

    -- 单笔赠送
    if product.per_pay_present then
        -- 从大到小排序
        local items = clone(product.per_pay_present)
        table.sort(items, function(a, b)
            return tonumber(a.pay) > tonumber(b.pay)
        end)

        for _, v in ipairs(items) do
            if inputNum >= tonumber(v.pay) then
                exchange = exchange + tonumber(v.present) * tonumber(product.currency_ratio)
                break
            end
        end
    end

    -- 获得货币
    self._exchange = exchange
    local currencyStr = string.format("元=%s", exchange) .. product.currency_name
    -- 额外赠送
    local extraStr = ""
    if product.present_deploy and #product.present_deploy > 0 then
        local str = ""
        for _, v in ipairs(product.present_deploy) do
            str = str .. string.format("%s*%s", v.name, v.ratio * inputNum)
            str = str .. "    "
        end
        extraStr = extraStr .. str
    end
    local showStr = currencyStr .. "    " .. extraStr
    FGUI:GTextField_setText(self._ui.text_exchange, showStr)
end

function RechargePanel:UpdateDesc()
    -- 选择货币
    if not self._productID then
        FGUI:GRichTextField_setText(self._ui.rich_desc, "")
        return
    end
    
    -- 有货币信息
    local product = SL:GetValue("RECHARGE_PRODUCT_BY_ID", self._productID)
    if not product then
        FGUI:GRichTextField_setText(self._ui.rich_desc, "")
        return
    end

    local desc = {}

    -- 额外赠送
    if product.present_deploy and #product.present_deploy > 0 then
        local str = ""
        for i, v in ipairs(product.present_deploy) do
            str = str .. string.format("%s 1:%s", v.name, v.ratio)
            str = str .. "    "
            str = str .. (i % 5 == 0 and "<br>" or "")
        end
        table.insert(desc, string.format("额外赠送：%s", str))
    end

    -- 赠送比例
    if product.present_ratio and tonumber(product.present_ratio) and tonumber(product.present_ratio) > 0 then
        local str = string.format("%s%%", product.present_ratio)
        table.insert(desc, string.format("赠送比例：%s", str))
    end

    -- 单笔充值
    if product.per_pay_present and #product.per_pay_present > 0 then
        local str = ""
        for i, v in ipairs(product.per_pay_present) do
            str = str .. string.format("充%s送%s", v.pay, v.present)
            str = str .. "    "
            str = str .. (i % 5 == 0 and "<br>" or "")
        end
        table.insert(desc, string.format("单笔充值：%s", str))
    end

    if #desc > 0 then
        local str = "本服充值赠送说明"
        str = str .. "<br>"
        str = str .. "<br>"
        for _, v in ipairs(desc) do
            str = str .. v
            str = str .. "<br>"
            str = str .. "<br>" .. "<br>"
        end

        FGUI:GRichTextField_setText(self._ui.rich_desc, str)
    end
end

function RechargePanel:OnClickSubmitPay()
    FGUI:delayTouchEnabled(self._ui.btn_submit, 1)

    -- 输入金额
    local input = FGUI:GTextField_getText(self._ui.input_money)
    input = tonumber(input) or 0
    if input <= 0 then
        SL:ShowSystemTips("请输入有效充值金额")
        return false
    end

    -- 是否有商品
    local product = SL:GetValue("RECHARGE_PRODUCT_BY_ID", self._productID)
    if not product then
        SL:ShowSystemTips("不是有效商品")
        return false
    end

    SL:RequestPay(self._payChannel, product.currency_itemid, input, nil, self._exchange)
end

return RechargePanel