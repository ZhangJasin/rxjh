local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCCommonItemSplitDialog = class("PCCommonItemSplitDialog", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- 使用方法
--[[
	-- local data = {}
	-- data.itemData = {
	--     Grade = 3,
	--     isShowCount = 100,
	--     OverLap = 10,
	--     Looks = 3535,
	--     Name = "道具"
	-- }
	
	-- data.dialogType = 0  单按钮 1 双按钮
	
	--    isOk = 0 单按钮回调
	--    isOk = 0 isOK = 1 双按钮回调
	--    isOk = 2 关闭按钮回调
	-- data.btnClicked = function(isOK,num)
	--     if isOK == 0 then
	--     elseif isOK == 1 then
	--         FGUI:Close("Common", "PCCommonItemSplitDialog")
	--     elseif isOk == 2 then    -- 关闭按钮
	--         FGUI:Close("Common", "PCCommonItemSplitDialog")
	--     end
	
	--     print("当前数量 =============" .. num)
	-- end
	
	
	-- data.maxNum = 100
	-- data.title = "装备拆分"
	-- data.minNum = 10
	-- SL:OpenCommonItemSplitDialog(data)
--]]

-- 角色方案面板
function PCCommonItemSplitDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:GetAllFGuiData()
    self:InitUI()
end

function PCCommonItemSplitDialog:InitData()
    self.num = 0
end

function PCCommonItemSplitDialog:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.btn_minus = self._ui.btn_minus
    self.btn_add = self._ui.btn_add
    self.btn_max = self._ui.btn_max
    self.btn_first = self._ui.btn_first
    self.btn_second = self._ui.btn_second
    self.btn_single = self._ui.btn_single
    self.text_tip = self._ui.text_tip
    self.mask = self._ui.mask
    self.iconNode = self._ui.iconNode
    self.inputCount = FGUI:GetChild(self._ui.input_count,"input_count")
end

function PCCommonItemSplitDialog:InitUI()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.onClose))
    FGUI:setOnClickEvent(self.mask, handler(self, self.onClose))
    FGUI:setOnClickEvent(self.btn_minus,handler(self,self.onBtnMinusClicked))
    FGUI:setOnClickEvent(self.btn_add,handler(self,self.onBtnAddClicked))
    FGUI:setOnClickEvent(self.btn_max,handler(self,self.onBtnMaxClicked))
    FGUI:setOnClickEvent(self.btn_first,handler(self,self.onBtnFirstClicked))
    FGUI:setOnClickEvent(self.btn_second,handler(self,self.onBtnSecondClicked))
    FGUI:setOnClickEvent(self.btn_single,handler(self,self.onBtnSingleClicked))
    FGUI:setOnFocusOut(self.inputCount,handler(self,self.InputCountClicked))

    self.dialogTypeController = FGUI:getController(self.component,"dialogType")
end

function PCCommonItemSplitDialog:InputCountClicked()
    local text = FGUI:GTextInput_getText(self.inputCount)
    if text then
        self.num = tonumber(text)
        self:CheckNum()
    end
end

function PCCommonItemSplitDialog:CheckNum()
    if self.minNum then
        if self.num < self.minNum then
            self.num = self.minNum
            self:RefreshCount()
            return
        end
    end

    if self.num < 1 then
        self.num = 1
        self:RefreshCount()
        return
    end

    if self.num > self.maxNum then
        self.num = self.maxNum
        self:RefreshCount()
        return
    end

    self:RefreshCount()
end

function PCCommonItemSplitDialog:onBtnCloseClicked()
    self.super.Close(self)
end

function PCCommonItemSplitDialog:onBtnMinusClicked()
    self.num = self.num - 1
    if self.num <= 1 then
        self.num = 1
    end
    self:RefreshCount()
end

function PCCommonItemSplitDialog:onBtnAddClicked()
    self.num = self.num + 1
    if self.num >= self.maxNum then
        self.num = self.maxNum
    end
    self:RefreshCount()
end

function PCCommonItemSplitDialog:onBtnMaxClicked()
    self.num = self.maxNum
    self:RefreshCount()
end

function PCCommonItemSplitDialog:onBtnCancelClicked()
    if self._data.cancelCallback then
        self._data.cancelCallback()
    end
    self.super.Close(self)
end

function PCCommonItemSplitDialog:onBtnFirstClicked()
    if self._data.btnClicked then
        self._data.btnClicked(0, self.num)
    end
    self.super.Close(self)
end

function PCCommonItemSplitDialog:onBtnSecondClicked()
    if self._data.btnClicked then
        self._data.btnClicked(1, self.num)
    end
end

function PCCommonItemSplitDialog:onBtnSingleClicked()
    if self._data.btnClicked then
        self._data.btnClicked(1, self.num)
    end
end

function PCCommonItemSplitDialog:onClose()
    if self._data.btnClicked then
        self._data.btnClicked(2, self.num)
    end
    self.super.Close(self)
end

-- 刷新数量
function PCCommonItemSplitDialog:RefreshCount()
    FGUI:GTextInput_setText(self.inputCount,self.num)
    self:RefreshTotalPriceShow()
end

function PCCommonItemSplitDialog:Enter(_data)
    if _data then
        self._data = _data
    end

    -- 更新组件名字
    FGUI:GTextField_setText(self._ui.text_name,self._data.itemData.Name)
    
    -- 面板类型
    self.dialogTypeController.selectedIndex = self._data.dialogType or 0

    -- 面板标题
    if self._data.title then    
        FGUI:GTextField_setText(self._ui.text_title,self._data.title or "")
    end

    -- 最大数量
    if self._data.maxNum then
        self.maxNum = self._data.maxNum
    else
        self.maxNum = 10
    end

    if self._data.btnNames then
        if #self._data.btnNames == 2 then
            local btn_first_Text = FGUI:GetChild(self._ui.btn_first,"text_content")
            FGUI:GTextField_setText(btn_first_Text,self._data.btnNames[1] or GET_STRING(1000))
            local btn_second_Text = FGUI:GetChild(self._ui.btn_second,"text_content") 
            FGUI:GTextField_setText(btn_second_Text,self._data.btnNames[2] or GET_STRING(1001))
        elseif #self._data.btnNames == 1 then
            local btn_single_Text = FGUI:GetChild(self._ui.btn_single,"text_content")
            FGUI:GTextField_setText(btn_single_Text,self._data.btnNames[1] or GET_STRING(1001))
        end
    end


    self.num = self._data.minNum or 1
    
    self:RefreshCount()
    self:RefreshItemNode()
end

-- 刷新总价显示
function PCCommonItemSplitDialog:RefreshTotalPriceShow()
    -- 是否显示文字
    if self._data and not string.isNullOrEmpty(self._data.costType) then
		local totalPrice = self.num * self._data.singlePrice
        local isMoneyEnough,costType,currentMoney,costList = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE",self._data.costType,totalPrice)
        if isMoneyEnough then
			FGUI:GTextField_setText(self.text_tip,string.format(GET_STRING(30000063),"[color=#00FF00]"..self._data.singlePrice * self.num.. "[/color]"..self._data.costName))
		else
			FGUI:GTextField_setText(self.text_tip,string.format(GET_STRING(30000063),"[color=#FF0000]"..self._data.singlePrice * self.num.. "[/color]"..self._data.costName))
		end
					
		FGUI:setVisible(self.text_tip,true)
    else
        FGUI:setVisible(self.text_tip,false)
    end

    -- NPC商店物品卖出
    if self._data.multPrice  and next(self._data.multPrice) then
        local str = ""
        local count = 1
        local totalCount = #self._data.multPrice
        for k,v in pairs(self._data.multPrice) do
            if v then
                local moneyID = tonumber(k)
                local itemMoneyConfig = SL:GetValue("ITEM_DATA",moneyID)
                if count == totalCount then
                    str = str .."[color=#FF0000]".. self.num * v.. "[/color]".. itemMoneyConfig.Name
                else
                    str = str .."[color=#FF0000]".. self.num * v.. "[/color]".. itemMoneyConfig.Name..","
                end
                count = count + 1
            end
        end
        FGUI:GTextField_setText(self.text_tip,string.format(GET_STRING(30000063),str))
        FGUI:setVisible(self.text_tip,self._data.multPrice and next(self._data.multPrice))
    end
end

function PCCommonItemSplitDialog:Destory()
    self:CleanCache()
end

function PCCommonItemSplitDialog:CleanCache()
    if self.itemShow then
        ItemUtil:ItemShow_Release(self.itemShow)
    end
end

function PCCommonItemSplitDialog:RefreshItemNode()
    self:CleanCache()
    self.itemShow = ItemUtil:ItemShow_Create(self._data.itemData,self.iconNode,{OverLap = self._data.OverLap,hideTip = true})
    if self.itemShow and self.itemShow.component then
        FGUI:setOnRollOverEvent(self.itemShow.component ,function()
            local tipData = {}
            tipData.itemData = self._data.itemData
            tipData.hideCompare = true
            tipData.hideButtons = true
            FGUIFunction:OpenItemTips(tipData)
        end)

        FGUI:setOnRollOutEvent(self.itemShow.component ,function()
            FGUIFunction:CloseItemTips()
        end)
    end
end

return PCCommonItemSplitDialog