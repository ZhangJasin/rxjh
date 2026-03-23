local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCExChangeLaunchDialog = class("PCExChangeLaunchDialog", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
--- 界面被创建时调用
function PCExChangeLaunchDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.stageClickHandler = handler(self, self.StageClickEvent)
    self.STAGE_EVENT_TOUCH = "PCExChangeLaunchDialog_CloseMoneyMoreList"
    self:GetAllFGuiData()
    self:InitClickEvent()
end

function PCExChangeLaunchDialog:CheckInitiatorIsTarget(data)
    local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
    if eventInitiator and eventInitiator.gameObject then
        if "checkBoxText" == eventInitiator.gameObject.name then
            return true
        else
            return false
        end
    end
    return true
end

function PCExChangeLaunchDialog:StageClickEvent(data)
    if data.eventName == self.STAGE_EVENT_TOUCH then
        local tapClose = true
        tapClose = self:CheckInitiatorIsTarget(data)
        if not tapClose then
            FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
        end
    end
end

function PCExChangeLaunchDialog:GetAllFGuiData()
    self.node_curSelected = self._ui.node_curSelected
    self.text_item_name = self._ui.text_item_name
    self.com_last_deal_price = self._ui.com_last_deal_price
    self.com_min_single_price = self._ui.com_min_single_price
    self.com_total_price = self._ui.com_total_price
    self.com_single_price = self._ui.com_single_price
    self.com_count = self._ui.com_count
    self.text_tip = self._ui.text_tip

    self.input_count = FGUI:GetChild(self.com_count,"input_text")
    self.input_single_price = FGUI:GetChild(self.com_single_price,"input_text")
    self.text_total_price = FGUI:GetChild(self.com_total_price,"text")

    self.money1 = self._ui.money1
    self.money2 = self._ui.money2

    self.btn_launch = self._ui.btn_launch
    self.btn_close = self._ui.btn_close
    self.btn_moneyMore = self._ui.btn_moneyMore
    self.moneyMoreList = self._ui.moneyMoreList

    self.ctrl_selected_money1 = FGUI:getController(self.money1, "isSelected")
    self.ctrl_selected_money2 = FGUI:getController(self.money2, "isSelected")
    self.ctrl_isShowMoneyMoreList = FGUI:getController(self.component, "isShowMoneyMoreList")
end

function PCExChangeLaunchDialog:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_launch, handler(self, self.BtnLaunchClicked))
    FGUI:setOnClickEvent(self.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self.btn_moneyMore, handler(self, self.BtnMoneyMoreClicked))

    FGUI:GList_addOnClickItemEvent(self.moneyMoreList, handler(self, self.ListMoneyMoreItemClicked))
    FGUI:GList_itemRenderer(self.moneyMoreList, handler(self, self.ListMoneyMoreItemRender))
    FGUI:GList_setVirtual(self.moneyMoreList)

    FGUI:GTextInput_setOnChanged(self.input_count,handler(self,self.InputCountTextChanged))
    FGUI:GTextInput_setOnChanged(self.input_single_price,handler(self,self.InputSinglePriceChanged))
end

function PCExChangeLaunchDialog:InputCountTextChanged()
    local str = FGUI:GTextInput_getText(self.input_count)
    if string.isNullOrEmpty(str) then
        return
    end

    local num = tonumber(str)
    if not num then
        num = 1
    end

    self._count = num
    self:RefreshCom()
end

function PCExChangeLaunchDialog:InputSinglePriceChanged()
    local str = FGUI:GTextInput_getText(self.input_single_price)
    if string.isNullOrEmpty(str) then
        return
    end

    local num = tonumber(str)
    if not num then
        num = 1
    end

    self._single_price = num
    self:RefreshCom()
end

function PCExChangeLaunchDialog:RefreshCom()
    local curGoldId = tonumber(self.PMCfg[self._cur_select_index].nCurrency)
    self:SetComValue(self.com_total_price, nil,self._count * self._single_price,curGoldId)
    self:SetComValue(self.com_single_price, nil, self._single_price , curGoldId)
    self:SetComValue(self.com_count, nil, self._count , curGoldId)
end


function PCExChangeLaunchDialog:BtnMoneyMoreClicked()
    if FGUI:Controller_getSelectedIndex(self.ctrl_isShowMoneyMoreList) == 0 then
        FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
    else
        FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 0)
    end

    self:RefreshMoneyMoreList()
end

function PCExChangeLaunchDialog:OnClose()
    self.super.Close(self)
end

-- 获取押金
function PCExChangeLaunchDialog:GetDesposit(totalPrice)
    local desposit = math.floor(totalPrice * self.PMCfg[self._cur_select_index].nDepositRate / 10000)
    local arr = string.split(self.PMCfg[self._cur_select_index].sDepositLimit,"|")
    local minDesp = tonumber(arr[1])
    local maxDesp = tonumber(arr[2])
    if desposit < minDesp then
        return minDesp
    end

    if desposit > maxDesp then
        return maxDesp
    end

    return desposit
end


function PCExChangeLaunchDialog:BtnLaunchClicked()
    local maxLaunchCount = SL:GetValue("GAME_DATA","MaxPaimaiCount")
    local myLaunchCount = table.nums(SL:GetValue("EXCHANGE_MY_SELLS"))
    -- 上架数量校验
    if myLaunchCount >= maxLaunchCount then
        SL:ShowSystemTips(string.format(GET_STRING(32000008),maxLaunchCount))
        return
    end

    local totalPrice =  self._count * self._single_price
    local curGoldId = self.PMCfg[self._cur_select_index].nCurrency
    local curGoldData = SL:GetValue("ITEM_DATA",tonumber(curGoldId))
    local needPrice = self:GetDesposit(totalPrice)

    if needPrice > tonumber(SL:GetValue("MONEY",curGoldId)) then
        SL:ShowSystemTips(string.format(GET_STRING(32000009),curGoldData.Name))
        return
    end

    local makeindex = self.itemData.MakeIndex
    local launchCount = self._count
    local singlePrice = self._single_price
    local goldType = curGoldId
    SL:RequestLaunchMyItem(makeindex,launchCount,singlePrice,goldType)
end

function PCExChangeLaunchDialog:RefreshView()
    if self.selectItem then
        ItemUtil:ItemShow_Release(self.selectItem)
    end

    -- 设置物品图标
    self.selectItem = ItemUtil:ItemShow_Create(self.itemData, self.node_curSelected, {disableClick = true})
    -- 设置名字
    FGUI:GTextField_setText(self.text_item_name, self.itemData.Name or "")
    -- 设置数值
    self:SetComValue(self.com_last_deal_price, GET_STRING(32000001), 0,0)
    self:SetComValue(self.com_min_single_price, GET_STRING(32000003), 0,0)

    -- 设置手续显示
    FGUI:GTextField_setText(self.text_tip, "")
    FGUI:setVisible(self.money1, false)
    FGUI:setVisible(self.money2, false)
    FGUI:setVisible(self.btn_moneyMore, false)

    self._cur_money_select_data = {}
    self._cur_select_index = -1
    self._cur_money_more_strs = {}
    for index, v in pairs(self.PMCfg) do
        local moneyID = tonumber(v.nCurrency)
        local moneyData = SL:GetValue("ITEM_DATA", moneyID)
        self._cur_money_select_data[moneyID] = v
        if index <= 2 then
            FGUI:setOnClickEvent(
                self["money" .. index], function()
                    self:SelectMoney(index)
                end
            )
            FGUI:GLabel_setTitle(self["money" .. index], moneyData.Name)
            FGUI:setVisible(self["money" .. index], true)
        else
            table.insert(self._cur_money_more_strs, moneyData.Name)
            FGUI:setVisible(self.btn_moneyMore, true)
        end
    end

    -- 关闭列表
    FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
    self:SelectMoney(1)
    self:RefreshCom()
end

function PCExChangeLaunchDialog:SelectMoney(index)
    self._cur_select_index = index
    self._cur_money_select_id = self.PMCfg[index].nCurrency
    self:RefreshCom()
    FGUI:Controller_setSelectedIndex(self.ctrl_selected_money1, index == 1 and 0 or 1)
    FGUI:Controller_setSelectedIndex(self.ctrl_selected_money2, index == 2 and 0 or 1)

    if self._cur_select_index <= 2 then
        FGUI:GButton_setTitle(self.btn_moneyMore, GET_STRING(32000005))
    else
        local moneyData = SL:GetValue("ITEM_DATA", tonumber(self._cur_money_select_id))
        local moneyName = moneyData.Name
        FGUI:GButton_setTitle(self.btn_moneyMore, moneyName)
    end

    self:RefreshMoneyMoreList()
    self:RefreshShouXuFei()
end

-- 刷新手续非比例
function PCExChangeLaunchDialog:RefreshShouXuFei()
    if self.PMCfg[self._cur_select_index].nTaxRate then
        FGUI:GTextField_setText(self.text_tip, string.format(GET_STRING(32000006), self.PMCfg[self._cur_select_index].nTaxRate / 100 .. "%"))
    else
        FGUI:GTextField_setText(self.text_tip,"")
    end
end

function PCExChangeLaunchDialog:RefreshMoneyMoreList()
    local len = table.nums(self._cur_money_more_strs)
    if len <= 0 then
        return
    end
    FGUI:GList_setNumItems(self.moneyMoreList, len)
    FGUI:setHeight(self.moneyMoreList, len * 19 + (len - 1) * 5 + 9)
end

function PCExChangeLaunchDialog:ListMoneyMoreItemRender(idx, item)
    local index = idx + 3
    local ctrl_isSelected = FGUI:getController(item, "isSelected")
    FGUI:Controller_setSelectedIndex(ctrl_isSelected, index == self._cur_select_index and 0 or 1)
    local title = FGUI:GetChild(item, "title")
    FGUI:GTextField_setText(title, self._cur_money_more_strs[idx + 1])
end

function PCExChangeLaunchDialog:ListMoneyMoreItemClicked(eventData)
    local childIdx = FGUI:GetChildIndex(self.moneyMoreList, eventData.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.moneyMoreList, childIdx)
    self:SelectMoney(idx + 3)
end

-- 设置组件值
function PCExChangeLaunchDialog:SetComValue(com, labelValue, textValue, moneyID)
    if not com then
        return
    end

    if labelValue then
        local title = FGUI:GetChild(com, "title")
        FGUI:GTextField_setText(title, labelValue)
    end

    local ctrl_mode = FGUI:getController(com,"mode")
    if ctrl_mode.selectedIndex == 0 then
        local input_text = FGUI:GetChild(com, "input_text")
        FGUI:GTextInput_setText(input_text,textValue)
    else
        local text = FGUI:GetChild(com, "text")
        FGUI:GTextField_setText(text,textValue)
    end

    local money_com = FGUI:GetChild(com, "icon_money")
    FGUI:setVisible(money_com, moneyID ~= 0)
    if moneyID ~= 0 then
        local moneyData = SL:GetValue("ITEM_DATA", moneyID)
        ItemUtil:RefreshItemUIByData(money_com, moneyData)
        ItemUtil:SetItemGradeVisible(money_com, false)
        ItemUtil:SetItemCountVisible(money_com, false)
    end
end

--- 界面打开时调用
function PCExChangeLaunchDialog:Enter(data)
    self:RegisterEvent()
    FGUI:StageEvent_AddListener(self.STAGE_EVENT_TOUCH, self.stageClickHandler)
    self.itemData = data
    if not self.itemData then
        return
    end

    local itemCfg = SL:GetValue("ITEM_DATA", self.itemData.Index)
    if not itemCfg then
        return
    end
    self.itemCfg = itemCfg

    local PMCfg = SL:GetValue("PAIMAI_CONFIG", itemCfg.nPaimaiConfig)
    if not PMCfg then
        return
    end

    self.PMCfg = PMCfg
    SL:RequestExReqItemStally(self.PMCfg[1].nPage, self.itemData.Index)

    self:InitData()
    self:RefreshView()
end

-- 初始化数据
function PCExChangeLaunchDialog:InitData()
    self._single_price = 1
    self._count = 1
end

function PCExChangeLaunchDialog:CleanItemCache()
    if self.selectItem then
        ItemUtil:ItemShow_Release(self.selectItem)
    end
    self.selectItem = nil
end

function PCExChangeLaunchDialog:RefreshPrice(data)
    if data and data.lastprice and data.lastprice ~=0 then
        self:SetComValue(self.com_last_deal_price, GET_STRING(32000001), data.lastprice , data.lastcurrency)
    else
        self:SetComValue(self.com_last_deal_price, GET_STRING(32000001), GET_STRING(32000007),0)
    end

    self:SetComValue(self.com_min_single_price, GET_STRING(32000003),self.PMCfg.nPriceLimit or 1,0)
end

function PCExChangeLaunchDialog:OnClose()
    self.super.Close(self)
end

function PCExChangeLaunchDialog:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_LAUNCH_REV, "PCExChangeLaunchDialog", handler(self, self.OnClose))
    SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_SELL_TALLY, "PCExChangeLaunchDialog", handler(self, self.RefreshPrice))
end

function PCExChangeLaunchDialog:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_SELL_TALLY, "PCExChangeLaunchDialog")
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_LAUNCH_REV, "PCExChangeLaunchDialog")
end

--- 界面关闭时调用
function PCExChangeLaunchDialog:Exit()
    self:RemoveEvent()
    FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_TOUCH)
    self:CleanItemCache()
end

return PCExChangeLaunchDialog
