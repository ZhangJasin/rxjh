local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_Agreement = class("S_Agreement", BaseFGUILayout)
local function SplitString(str, delimiter)
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
local function SplitLongStrToArr(str)
	local parts = SplitString(str, "<br>")
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

function S_Agreement:Create()
    self._uiRoot = FGUI:GetChild(self.component, "Root")
    self._ui = FGUI:ui_delegate( self._uiRoot)
    self.handler_contentRenderer = handler(self, self.OnContentItemRenderer)

	local mask = FGUI:GetChild(self.component, "Mask")
	FGUI:setOnClickEvent(mask, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.Button_sure, handler(self, self.OnAgree))
    FGUI:setOnClickEvent(self._ui.Button_agree, handler(self, self.OnAgree))
    FGUI:setOnClickEvent(self._ui.Button_refuse, handler(self, self.OnRefuse))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))

    FGUI:GList_itemRenderer(self._ui.List_Content, self.handler_contentRenderer)
    FGUI:GList_setVirtual(self._ui.List_Content)
end

-- type  1: 用户协议(带拒绝按钮); 2:任意文本
function S_Agreement:Enter(initData)
    if not initData then return end
    self._type = initData.type
    self._content = initData.content
    self._strTitle = initData.title or SL:GetValue("I18N_STRING", 35)
    self:InitView()
end

function S_Agreement:Exit()
    self._content = nil
end

function S_Agreement:Destroy()
    self._announceData = nil

    self._parent = nil
    self._ui = nil
end

function S_Agreement:Close()
    self.super.Close(self)
end

function S_Agreement:InitView()
	if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setScale( self._uiRoot , 0.75, 0.75)
    else
        FGUI:setScale( self._uiRoot , 1, 1)
    end
    local showRefuse = self._type == 1
    FGUI:setVisible(self._ui.Button_sure, not showRefuse)
    FGUI:setVisible(self._ui.Button_agree, showRefuse)
    FGUI:setVisible(self._ui.Button_refuse, showRefuse)
    FGUI:GTextInput_setText(self._ui.title, self._strTitle)

    -- 单条长文本切割成多条文本
    FGUI:GList_setNumItems(self._ui.List_Content, 0)
    self._contentStrs = SplitLongStrToArr(self._content or "")  
    FGUI:GList_setNumItems(self._ui.List_Content, #self._contentStrs)
end

function S_Agreement:OnContentItemRenderer(idx, item)
    local strInfo = self._contentStrs[idx + 1]
    FGUI:GLabel_setTitle(item, strInfo.Str)
    local text =FGUI:GetChild(item, "title")
    FGUI:setHeight(item, FGUI:getHeight(text))
end

function S_Agreement:OnAgree()
    self:Close()
end

function S_Agreement:OnRefuse()
    if self._type ~= 1 then return end

    SL:SetValue("AGREEMENT_CACHE_STATE", 0)

	-- 
    SL:Logout()
end


return S_Agreement