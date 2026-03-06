local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonHelpDialog = class("CommonHelpDialog", BaseFGUILayout)

local textUrl = "ui://zu7kdgtsr1ygv64"
local btnUrl = "ui://zu7kdgtssb5ovoh"

function CommonHelpDialog:Create()
	self.super.Create(self)
	if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "Common_pc"
    else
        self._packageName = "Common"
    end
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._strArr = {}
	self._strArrLen = 0
	self._handler_OnRichTextRenderer = handler(self, self.OnRichTextRenderer)
	self._handler_OnItemProvider = handler(self, self.OnItemProvider)
	self._handler_OnClickHyperLink = handler(self, self.OnClickHyperLink)
	FGUI:GList_itemRenderer(self._ui.list, self._handler_OnRichTextRenderer)
	FGUI:GList_itemProvider(self._ui.list, self._handler_OnItemProvider)
	FGUI:GList_setVirtual(self._ui.list)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
end

function CommonHelpDialog:Enter(data)
	if not data then return end
	self._data = data
	self:RefreshDisplay()
end

function CommonHelpDialog:RefreshDisplay()
	local title = self._data.title and self._data.title or GET_STRING(1003)
	local str = self._data.str and self._data.str or ""
	FGUI:GTextField_setText(self._ui.text_title, title)
	FGUI:GList_setNumItems(self._ui.list, 0)
	self._strArr = self:SplitLongStrToArr(str)
	self._strArrLen = #self._strArr + (self._data.btnDesc and 1 or 0)
	FGUI:GList_setNumItems(self._ui.list, self._strArrLen)
end

function CommonHelpDialog:OnRichTextRenderer(idx, item)
	if self._data.btnDesc and idx == (self._strArrLen - 1) then
		-- 按钮
		FGUI:GButton_setTitle(item, self._data.btnDesc)
		FGUI:setOnClickEvent(item, handler(self, self.OnClickEndButton))

		
	else
		-- 文本
		local data = self._strArr[idx + 1]
		local text = FGUI:GetChild(item, "title")
		FGUI:GTextField_setText(text,data.Str)
		FGUI:setHeight(item, FGUI:getHeight(text))
		if data.Hyperlink then
			FGUI:GRichTextField_addOnLinkClickEvent(text, self._handler_OnClickHyperLink)
		end
	end
end

function CommonHelpDialog:OnItemProvider(idx)
	if self._data.btnDesc and idx == self._strArrLen - 1 then
		-- item换为按钮
		return "ui://"..self._packageName.."/HelpDialogBtn"
	else
		-- item换为文本
		return "ui://"..self._packageName.."/HelpDialogRickText"
	end
end

function CommonHelpDialog:OnClickEndButton()
	if self._data.btnCallback then
		self._data.btnCallback()
	end
	
	if not self._data.notClose then
		self:Close()
	end		
end

function CommonHelpDialog:OnClickHyperLink(context)
	if self._data.linkCallback then
		self._data.linkCallback(context.data)
	end
end


function CommonHelpDialog:SplitString(str, delimiter)
	delimiter = delimiter or "<br>"
	local result = {}
	local startIndex = 1
	local len = #str

	while startIndex <= len do
		local delimiterStart,delimiterEnd = string.find(str, delimiter, startIndex, true)

		if not delimiterStart then
			table.insert(result, string.sub(str, startIndex, len))
			break
		end

		table.insert(result, string.sub(str, startIndex, delimiterStart - 1))

		startIndex = delimiterEnd + 1
	end

	return result
end

-- 拆分长字符串
function  CommonHelpDialog:SplitLongStrToArr(str)
	local parts = self:SplitString(str, "<br>")
	local finalResult = {}

	for _, part in ipairs(parts) do
		local subParts = {}
		local subStart = 1
		local subLen = #part

		while subStart <= subLen do 
			local foundPos = string.find(part, "\r\n", subStart, true) or 
							string.find(part, "\n", subStart, true)
			
			if not foundPos then
				table.insert(subParts, string.sub(part, subStart, subLen))
				break
			end

			table.insert(subParts, string.sub(part, subStart, foundPos - 1))
			subStart = foundPos + (string.sub(part, foundPos, foundPos) == "\r" and 2 or 1)
		end

		for _, subPart in ipairs(subParts) do
			local hasStartTag = string.find(subPart, "<a",1, true) ~= nil
			local hasEndTag = string.find(subPart, "</a>",1, true) ~= nil
			local containsHyperlink = false
			if hasStartTag and hasEndTag then
				containsHyperlink = true
			end
			local data = {}
			data.Hyperlink = containsHyperlink
			data.Str = subPart
			table.insert(finalResult, data)
		end
	end

	return finalResult
end


function CommonHelpDialog:Exit()
	
end

function CommonHelpDialog:Close()
	self.super.Close(self)
end

return CommonHelpDialog