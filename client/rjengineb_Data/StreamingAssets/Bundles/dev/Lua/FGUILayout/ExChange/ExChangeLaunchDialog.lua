local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ExChangeLaunchDialog = class("ExChangeLaunchDialog", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
--- 界面被创建时调用
function ExChangeLaunchDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.stageClickHandler = handler(self, self.StageClickEvent)
    self.STAGE_EVENT_TOUCH = "ExChangeLaunchDialog_CloseMoneyMoreList"
    self:GetAllFGuiData()
    self:BindClass()
    self:InitClickEvent()
end

function ExChangeLaunchDialog:CheckInitiatorIsTarget(data)
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

function ExChangeLaunchDialog:StageClickEvent(data)
    if data.eventName == self.STAGE_EVENT_TOUCH then
        local tapClose = true
        tapClose = self:CheckInitiatorIsTarget(data)
        if not tapClose then
            FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
        end
    end
end

function ExChangeLaunchDialog:GetAllFGuiData()
    self.node_curSelected = self._ui.node_curSelected
    self.text_item_name = self._ui.text_item_name
    self.com_last_deal_price = self._ui.com_last_deal_price
    self.com_min_single_price = self._ui.com_min_single_price
    self.text_tip = self._ui.text_tip
    self.text_count = self._ui.text_count
    self.text_single_price = self._ui.text_single_price
    self.text_total_price = self._ui.text_total_price
    self.btn_check_1 = self._ui.btn_check_1
    self.btn_check_2 = self._ui.btn_check_2
    self.money1 = self._ui.money1
    self.money2 = self._ui.money2
    self.btn_launch = self._ui.btn_launch
    self.com_calc = self._ui.com_calc
    self.text_cal = FGUI:GetChild(self.com_calc, "text_cal")
    self.btn_close = self._ui.btn_close
    self.btn_moneyMore = self._ui.btn_moneyMore
    self.moneyMoreList = self._ui.moneyMoreList
    self.ctrl_check1 = FGUI:getController(self.btn_check_1, "isSelected")
    self.ctrl_check2 = FGUI:getController(self.btn_check_2, "isSelected")
    self.ctrl_selected_money1 = FGUI:getController(self.money1, "isSelected")
    self.ctrl_selected_money2 = FGUI:getController(self.money2, "isSelected")
    self.ctrl_isShowMoneyMoreList = FGUI:getController(self.component, "isShowMoneyMoreList")
end

function ExChangeLaunchDialog:BindClass()
    self.ComCalc = FGUIFunction:BindClass(self.com_calc, "ExChange/comCalc")
    self.ComCalc:Create(self)
end

function ExChangeLaunchDialog:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_launch, handler(self, self.BtnLaunchClicked))
    FGUI:setOnClickEvent(self.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self.btn_check_1, handler(self, self.BtnCheck1Clicked))
    FGUI:setOnClickEvent(self.btn_check_2, handler(self, self.BtnCheck2Clicked))
    FGUI:setOnClickEvent(self.btn_moneyMore, handler(self, self.BtnMoneyMoreClicked))

    FGUI:GList_addOnClickItemEvent(self.moneyMoreList, handler(self, self.ListMoneyMoreItemClicked))
    FGUI:GList_itemRenderer(self.moneyMoreList, handler(self, self.ListMoneyMoreItemRender))
    FGUI:GList_setVirtual(self.moneyMoreList)
end

function ExChangeLaunchDialog:BtnMoneyMoreClicked()
    if FGUI:Controller_getSelectedIndex(self.ctrl_isShowMoneyMoreList) == 0 then
        FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
    else
        FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 0)
    end

    self:RefreshMoneyMoreList()
end

-- 切换数量计算器
function ExChangeLaunchDialog:BtnCheck1Clicked()
    if self.ctrl_check1.selectedIndex == 0 then
        return
    end
    local data = {}
    -- 物品是否可堆叠
    if self.itemCfg and self.itemCfg.OverLap then
        if  self.itemCfg.OverLap == 0 then
            data.min = 1
            data.max = 1
        elseif self.itemCfg.OverLap > 0 then
            data.min = 1
            data.max = self.itemCfg.OverLap
        end
    end

    local num = FGUI:GTextField_getText(self.text_count)
    if not string.isNullOrEmpty(num) then
        data.curValue = tonumber(num)
    end

    self.ctrl_check1.selectedIndex = 0
    self.ctrl_check2.selectedIndex = 1
    self.ComCalc:Reset(data)
end

-- 切换单价计算器
function ExChangeLaunchDialog:BtnCheck2Clicked()
    if self.ctrl_check2.selectedIndex == 0 then
        return
    end

    local data = {}
    local num  = FGUI:GTextField_getText(self.text_single_price)
    if not string.isNullOrEmpty(num) then
        data.curValue = tonumber(num)
    end

    self.ctrl_check2.selectedIndex = 0
    self.ctrl_check1.selectedIndex = 1
    
    data.min = self.PMCfg.nPriceLimit or 1
    self.ComCalc:Reset(data)
end

-- 刷新计算结果
function ExChangeLaunchDialog:RefreshCalcResult()
    if self.ctrl_check1.selectedIndex == 0 then
        FGUI:GTextField_setText(self.text_count, FGUI:GTextField_getText(self.text_cal))
    end

    if self.ctrl_check2.selectedIndex == 0 then
        FGUI:GTextField_setText(self.text_single_price, FGUI:GTextField_getText(self.text_cal))
    end

    local count = FGUI:GTextField_getText(self.text_count)
    local singlePrice = FGUI:GTextField_getText(self.text_single_price)

    if string.isNullOrEmpty(count) then
        return
    end

    if string.isNullOrEmpty(singlePrice) then
        return
    end

    local count = tonumber(count)
    local singlePrice = tonumber(singlePrice)

    FGUI:GTextField_setText(self.text_total_price, count * singlePrice)
end

function ExChangeLaunchDialog:OnClose()
    self.super.Close(self)
end

-- 获取押金
function ExChangeLaunchDialog:GetDesposit(totalPrice)
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


function ExChangeLaunchDialog:BtnLaunchClicked()
    local _launchCount = FGUI:GTextField_getText(self.text_count)
    if not tonumber(_launchCount) then
        return
    end
    _launchCount = tonumber(_launchCount)

    local _single_price = FGUI:GTextField_getText(self.text_single_price)
    if not tonumber(_single_price) then
        return
    end
    _single_price = tonumber(_single_price)

    local maxLaunchCount = SL:GetValue("GAME_DATA","MaxPaimaiCount")
    local myLaunchCount = table.nums(SL:GetValue("EXCHANGE_MY_SELLS"))
    -- 上架数量校验
    if myLaunchCount >= maxLaunchCount then
        SL:ShowSystemTips(string.format(GET_STRING(32000008),maxLaunchCount))
        return
    end

    local totalPrice = _launchCount * _single_price
    local curGoldId = self.PMCfg[self._cur_select_index].nCurrency
    local curGoldData = SL:GetValue("ITEM_DATA",tonumber(curGoldId))
    local needPrice = self:GetDesposit(totalPrice)

    if needPrice > tonumber(SL:GetValue("MONEY",curGoldId)) then
        SL:ShowSystemTips(string.format(GET_STRING(32000009),curGoldData.Name))
        return
    end

    local makeindex = self.itemData.MakeIndex
    local launchCount = _launchCount
    local singlePrice = _single_price
    local goldType = curGoldId
    SL:RequestLaunchMyItem(makeindex,launchCount,singlePrice,goldType)
end

function ExChangeLaunchDialog:RefreshView()
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

    -- 是否显示单价计算器切换框
    local isCanOverLap = self.itemCfg and self.itemCfg.OverLap and self.itemCfg.OverLap > 0
    FGUI:setVisible(self.btn_check_1,isCanOverLap)

    if isCanOverLap then
        self:BtnCheck1Clicked()
    else
        self:BtnCheck2Clicked()
    end


    FGUI:GTextField_setText(self.text_count,1)
    FGUI:GTextField_setText(self.text_single_price,1)
    FGUI:GTextField_setText(self.text_total_price,1)
    -- 关闭列表
    FGUI:Controller_setSelectedIndex(self.ctrl_isShowMoneyMoreList, 1)
    self:SelectMoney(1)
end

function ExChangeLaunchDialog:SelectMoney(index)
    self._cur_select_index = index
    self._cur_money_select_id = self.PMCfg[index].nCurrency

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
function ExChangeLaunchDialog:RefreshShouXuFei()
    if self.PMCfg[self._cur_select_index].nTaxRate then
        FGUI:GTextField_setText(self.text_tip, string.format(GET_STRING(32000006), self.PMCfg[self._cur_select_index].nTaxRate / 100 .. "%"))
    else
        FGUI:GTextField_setText(self.text_tip,"")
    end
end

function ExChangeLaunchDialog:RefreshMoneyMoreList()
    local len = table.nums(self._cur_money_more_strs)
    if len <= 0 then
        return
    end
    FGUI:GList_setNumItems(self.moneyMoreList, len)
    FGUI:setHeight(self.moneyMoreList, len * 33 + (len - 1) * 5 + 9)
end

function ExChangeLaunchDialog:ListMoneyMoreItemRender(idx, item)
    local index = idx + 3
    local ctrl_isSelected = FGUI:getController(item, "isSelected")
    FGUI:Controller_setSelectedIndex(ctrl_isSelected, index == self._cur_select_index and 0 or 1)
    local title = FGUI:GetChild(item, "title")
    FGUI:GTextField_setText(title, self._cur_money_more_strs[idx + 1])
end

function ExChangeLaunchDialog:ListMoneyMoreItemClicked(eventData)
    local childIdx = FGUI:GetChildIndex(self.moneyMoreList, eventData.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.moneyMoreList, childIdx)
    self:SelectMoney(idx + 3)
end

-- 设置组件值
function ExChangeLaunchDialog:SetComValue(com, labelValue, textValue, moneyID)
    if not com then
        return
    end

    local label_com = FGUI:GetChild(com, "label")
    local text_com = FGUI:GetChild(com, "text")
    local money_com = FGUI:GetChild(com, "icon_money")
    FGUI:GTextField_setText(label_com, labelValue)
    FGUI:GTextField_setText(text_com, textValue)
    FGUI:setVisible(money_com, moneyID ~= 0)
    if moneyID ~= 0 then
        local moneyData = SL:GetValue("ITEM_DATA", moneyID)
        ItemUtil:RefreshItemUIByData(money_com, moneyData)
        ItemUtil:SetItemGradeVisible(money_com, false)
        ItemUtil:SetItemCountVisible(money_com, false)
    end
end

--- 界面打开时调用
function ExChangeLaunchDialog:Enter(data)
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

    self.ComCalc:Enter()
    self:RefreshView()
end

function ExChangeLaunchDialog:CleanItemCache()
    if self.selectItem then
        ItemUtil:ItemShow_Release(self.selectItem)
    end
    self.selectItem = nil
end

function ExChangeLaunchDialog:RefreshPrice(data)
    if data and data.lastprice and data.lastprice ~=0 then
        self:SetComValue(self.com_last_deal_price, GET_STRING(32000001), data.lastprice , data.lastcurrency)
    else
        self:SetComValue(self.com_last_deal_price, GET_STRING(32000001), GET_STRING(32000007),0)
    end

    self:SetComValue(self.com_min_single_price, GET_STRING(32000003),self.PMCfg.nPriceLimit or 1,0)
end

function ExChangeLaunchDialog:OnClose()
    self.super.Close(self)
end

function ExChangeLaunchDialog:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_LAUNCH_REV, "ExChangeLaunchDialog", handler(self, self.OnClose))
    SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_SELL_TALLY, "ExChangeLaunchDialog", handler(self, self.RefreshPrice))
end

function ExChangeLaunchDialog:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_SELL_TALLY, "ExChangeLaunchDialog")
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_LAUNCH_REV, "ExChangeLaunchDialog")
end

--- 界面关闭时调用
function ExChangeLaunchDialog:Exit()
    self:RemoveEvent()
    FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_TOUCH)
    self.ComCalc:Exit()
    self:CleanItemCache()
end

return ExChangeLaunchDialog
