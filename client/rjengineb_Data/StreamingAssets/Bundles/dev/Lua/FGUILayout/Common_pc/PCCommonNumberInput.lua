local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCCommonNumberInput = class("PCCommonNumberInput", BaseFGUILayout)

local defaultMax = 999999
function PCCommonNumberInput:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._maxNum = defaultMax
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self._curInputVal = 0
	FGUI:setOnClickEvent(self._ui.btn_no, handler(self, self.OnClickCancelButton))
	FGUI:setOnClickEvent(self._ui.btn_yes, handler(self, self.OnClickSureButton))
	FGUI:setOnClickEvent(self._ui.btn_close,handler(self,self.Close))

	-- 数字键绑定
	for i = 0,9 do
		local btn_name = string.format("num_%s", i)
		FGUI:setOnClickEvent(self._ui[btn_name], function ()
			self:SetShowNumber(self._curInputVal * 10 + i)
		end)
	end
	
	-- 增加数字
	local addNumber = {10, 50 ,100}
	for _, v in pairs(addNumber) do
		local btn_name = string.format("add_%s", v)
		FGUI:setOnClickEvent(self._ui[btn_name], function ()
			self:SetShowNumber(self._curInputVal + v)
		end)
	end

	-- 返回
	FGUI:setOnClickEvent(self._ui.btn_back, function ()
		self:SetShowNumber(math.floor(self._curInputVal / 10))
	end)

	-- 删除
	FGUI:setOnClickEvent(self._ui.btn_del, function ()
		self:SetShowNumber(0)
	end)

	-- 最大
	FGUI:setOnClickEvent(self._ui.btn_max, function ()
		self:SetShowNumber(self._maxNum)
	end)
end

function PCCommonNumberInput:Enter(data)
	if not data then return end
	self._data = data
	if self._data.maxNum then
		self._maxNum = self._data.maxNum
	else
		self._maxNum = defaultMax
	end

	self:SetShowNumber(0)
	FGUI:GTextField_setText(self._ui.title, data.title)
end

function PCCommonNumberInput:Exit()
	
end

function PCCommonNumberInput:Close()
	self.super.Close(self)
end

-- 点击确认按钮
function PCCommonNumberInput:OnClickSureButton()
	if self._data and self._data.callback_yes then
		self._data.callback_yes(self._curInputVal)
	end
	self:Close()
end

-- 点击取消按钮
function PCCommonNumberInput:OnClickCancelButton()
	if self._data and self._data.callback_no then
		self._data.callback_no(self._curInputVal)
	end
	self:Close()
end

function PCCommonNumberInput:SetShowNumber(num)
	if num < 0 then
		num = 0
	elseif num > self._maxNum then
		num = self._maxNum
	end

	self._curInputVal = num
	FGUI:GTextField_setText(self._ui.text_show_num, self._curInputVal)
end

return PCCommonNumberInput