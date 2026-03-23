local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCExChangeBuyDialog = class("PCExChangeBuyDialog", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

--- 界面被创建时调用
function PCExChangeBuyDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:GetAllFGuiData()
    self:InitClickEvent()
end

function PCExChangeBuyDialog:InitData()
    self.curItemNode = nil
end

function PCExChangeBuyDialog:GetAllFGuiData()
    self.item_node = self._ui.item_node
    self.text_name = self._ui.text_name
    self.input_count = self._ui.input_count
    self.text_count = FGUI:GetChild(self.input_count,"text_count")
    self.btn_minus = self._ui.btn_minus
    self.btn_add = self._ui.btn_add
    self.btn_max = self._ui.btn_max
    self.btn_cancel = self._ui.btn_cancel
    self.btn_ok = self._ui.btn_ok
    self.mask = self._ui.mask
    self.money_need = self._ui.money_need
    self.money_need_count = self._ui.money_need_count
    self.btn_close = self._ui.btn_close
end

function PCExChangeBuyDialog:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_minus, handler(self, self.BtnMinusClicked))
	FGUI:setOnClickEvent(self.btn_add, handler(self, self.BtnAddClicked))
	FGUI:setOnClickEvent(self.btn_cancel, handler(self, self.BtnCancelClicked))
	FGUI:setOnClickEvent(self.btn_ok, handler(self, self.BtnOkClicked))
    FGUI:setOnClickEvent(self.btn_max,handler(self,self.BtnMaxClicked))
    FGUI:GTextInput_setOnChanged(self.text_count,handler(self,self.inputCountClicked))
    FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCExChangeBuyDialog:inputCountClicked()
    local str = FGUI:GTextInput_getText(self.text_count)
    if string.isNullOrEmpty(str) then
        self.num = 1
        return
    end
    local num = tonumber(str)
    if not num then
        num = 1
    end
    self.num = num
    self:ShowNum()
end

function PCExChangeBuyDialog:BtnMinusClicked()
    self.num = self.num - 1
    self:ShowNum()
end


function PCExChangeBuyDialog:BtnAddClicked()
    self.num = self.num + 1
    self:ShowNum()
end


function PCExChangeBuyDialog:BtnCancelClicked()
    self:OnClose()
end


function PCExChangeBuyDialog:BtnOkClicked()
    if self.data and self.data.ok then
        self.data.ok(self.data.makeIndex,self.data.price,self.num)
    end
    self:OnClose()
end


function PCExChangeBuyDialog:BtnMaxClicked()
    self.num = self.data.maxNum or 1
    self:ShowNum()
end

function PCExChangeBuyDialog:OnClose()
    self.super.Close(self)
end

function PCExChangeBuyDialog:ShowNum()
    if self.num <= 0 then
        self.num = 1
    end

    if self.num > self.data.maxNum then
        self.num = self.data.maxNum
    end


    if self.curItemNode then
       ItemUtil:ItemShow_Release(self.curItemNode) 
    end

    self.curItemNode = ItemUtil:ItemShow_Create(self.data.itemData,self.item_node)


    FGUI:GTextField_setText(self.text_name,self.data.itemName)
    FGUI:GTextField_setText(self.text_count,self.num)
    local moneyItemData = SL:GetValue("ITEM_DATA",self.data.costType)
    ItemUtil:RefreshItemUIByData(self.money_need, moneyItemData)
    ItemUtil:SetItemCountVisible(self.money_need, false)
    ItemUtil:SetItemGradeVisible(self.money_need, false)
    FGUI:GTextInput_setText(self.money_need_count,self.num * self.data.price)
end

--- 界面打开时调用
function PCExChangeBuyDialog:Enter(data)
    self.num = 1
    self.data = data
    self:ShowNum()
end

--- 界面关闭时调用
function PCExChangeBuyDialog:Exit()
end

--- 界面销毁时调用
function PCExChangeBuyDialog:Destroy()
end

return PCExChangeBuyDialog
