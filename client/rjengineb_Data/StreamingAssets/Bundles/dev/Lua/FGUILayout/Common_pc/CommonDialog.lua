local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonDialog = class("CommonDialog", BaseFGUILayout)

--[[
	title				--标题
    str            		--文本
    btnDesc        		--按钮名字{ "拒绝", "同意" }
    callback            --按钮回调 参数1:点击的按钮id 参数2:数据{editStr=输入框字符串}
    showEdit            --是否显示输入框
    editParams          --输入框参数 可以不传{str, inputMode, maxLength}
	showClose			--是否显示关闭按钮(默认false)
	maskClose			--点击遮罩是否关闭(默认true)
]]

function CommonDialog:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._editBox = self._ui.textInput
	self._text_str = self._ui("desc", "content")
	FGUI:setOnClickEvent(self._ui.Mask, handler(self, self.Close))
end

function CommonDialog:Enter(data)
	if not data then return end
	self._data = data
	self._showEdit = data.showEdit
	self._maskClose = data.maskClose == nil and true or data.maskClose
	self:RegisterEvent()
	self:InitBtnShow()
	self:InitTitle()
	self:InitDesc()
	self:InitEdit()
	self:StartCountdown()
end

function CommonDialog:Exit()
	self:RemoveEvent()
end

function CommonDialog:Close()
	self:StopCountdown()
	self.super.Close(self)
end

function CommonDialog:InitBtnShow()
	local function clickCallBack(tag)
        local data = {}
        data.event = tag

        if self._showEdit then
            local editStr = FGUI:GTextField_getText(self._editBox)
            data.editStr = editStr
        end
		self:HandleEvent(data)
    end
    self._clickCallBack = clickCallBack
	local btnDesc = self._data.btnDesc

	if btnDesc then
        local num = #btnDesc

		-- 单按钮
        if num == 1 then
			FGUI:GButton_setTitle(self._ui.btn_green, btnDesc[1])
			FGUI:setOnClickEvent(self._ui.btn_green, function ()
				clickCallBack(1)
			end)
			FGUI:setVisible(self._ui.btn_red, false)
			local y = FGUI:getPositionY(self._ui.btn_red)
        	FGUI:setPosition(self._ui.btn_green, (self.component.width - self._ui.btn_red.width) / 2, y) -- 居中
        elseif num == 2 then
			FGUI:GButton_setTitle(self._ui.btn_green, btnDesc[1])
			FGUI:GButton_setTitle(self._ui.btn_red, btnDesc[2])
			FGUI:setVisible(self._ui.btn_red, true)

			FGUI:setOnClickEvent(self._ui.btn_green, function ()
				clickCallBack(1)
			end)
			FGUI:setOnClickEvent(self._ui.btn_red, function ()
				clickCallBack(2)
			end)

			-- 镜像对称
			local center_x = self.component.width / 2
			local x, y = FGUI:getPosition(self._ui.btn_red)
			local offset_x = center_x - self._ui.btn_red.width - x
			FGUI:setPosition(self._ui.btn_green, center_x + offset_x, y)
		end
    end

	FGUI:setTouchEnabled(self._ui.Mask, self._maskClose)
	FGUI:setVisible(self._ui.btn_close, self._data.showClose)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function CommonDialog:StartCountdown()
    if not self._data.exitTime then return end
    self._countdownTime = self._data.exitTime
    self._countdownTask = SL:Schedule(function(dt)
        self._countdownTime = self._countdownTime - 1
        if self._countdownTime <= 0 then
            self._countdownTime = 0
            self:OnCountdownFinished()
        end
        if self._countdownTime and self._data.exitTime then
            local str = string.format(GET_STRING(600000457), self._countdownTime, "%s")
            FGUI:GRichTextField_setText(self._text_str, str)
        end
    end, 1)
end

function CommonDialog:StopCountdown()
    if self._countdownTask then
        SL:UnSchedule(self._countdownTask)
        self._countdownTask = nil
    end
end

function CommonDialog:OnCountdownFinished()
    self:StopCountdown()
     self._clickCallBack(1)
end

function CommonDialog:InitTitle()
	if self._data.title then
		FGUI:GTextField_setText(self._ui.title, self._data.title)
	end
end

function CommonDialog:InitDesc()
	if not self._data.str then
		return
	end

	local str = self._data.str
	FGUI:GRichTextField_setText(self._text_str, str)
end

function CommonDialog:InitEdit()
	if not self._showEdit then
		FGUI:setVisible(self._ui.input_root, false)
		return
	end

	FGUI:setVisible(self._ui.input_root, true)
	FGUI:GTextInput_addOnChanged(self._editBox, function ()
		local input = FGUI:GTextField_getText(self._editBox)
		if string.len(input) > 0 and string.find(input, "\n") then
			input = string.gsub(input, "\r\n", "")
			input = string.gsub(input, "\n", "")
			local data = {}
			data.event = 1
			data.editStr = input
			self:HandleEvent(data)
		end
	end)

	local editParams = self._data.editParams
	FGUI:GTextField_setText(self._editBox, "")
    if self._editBox and editParams then
        if editParams.inputMode then
			--FGUI:GTextInput_setRestrict(self._editBox, val)
        end
        if editParams.maxLength then
            FGUI:GTextInput_setMaxLength(self._editBox, editParams.maxLength)
		else
			FGUI:GTextInput_setMaxLength(self._editBox, 0)
		end
        if editParams.str then
            FGUI:GTextField_setText(self._editBox, editParams.str)
        end
    end

end

function CommonDialog:HandleEvent(data)
	local tag = data.event
    if tag then
        SL:CloseCommonDialog()
        if self._data.callback then
            self._data.callback(tag, data)
        end
    end
end

function CommonDialog:CloseById(id)
	if id == self._data.id then
		self:Close()
	end
end

function CommonDialog:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_CLOSE_COMMON_DIALOG_BY_ID, "CommonDialog", handler(self, self.CloseById))	--刷新自身摊位数据
end

function CommonDialog:RemoveEvent()
	 SL:UnRegisterLUAEvent(LUA_EVENT_CLOSE_COMMON_DIALOG_BY_ID, "CommonDialog")
end

return CommonDialog