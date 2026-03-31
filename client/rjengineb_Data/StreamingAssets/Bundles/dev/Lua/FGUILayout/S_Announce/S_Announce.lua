local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_Announce = class("S_Announce", BaseFGUILayout)

function S_Announce:Create()
    self._uiRoot = FGUI:GetChild(self.component, "Root")
    self._ui = FGUI:ui_delegate( self._uiRoot)
    self._announceData = nil
    self._selectIdx = 0

    self:InitAnnounceData()
    local mask = FGUI:GetChild(self.component, "Mask")
    FGUI:setOnClickEvent(mask, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function S_Announce:Enter()
    self:InitView()
    self:RegisterEvent()
end

function S_Announce:Exit()
    self:RemoveEvent()
end

function S_Announce:Destroy()
    self._announceData = nil

    self._parent = nil
    self._ui = nil
end


function S_Announce:InitView()
    self:InitListView()
    self:SelectAnnounce(1, true)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setScale( self._uiRoot , 0.75, 0.75)
    else
        FGUI:setScale( self._uiRoot , 1, 1)
    end
end

function S_Announce:InitAnnounceData()
    self._selectIdx = 0
	local serverData = SL:GetValue("SERVER_DATA")
	if not serverData then return end
	local announce   = serverData.announce
	if not announce then return end

	-- filter
	local items = {}
    self._announceData = items
	for i, v in ipairs(announce) do
		if v.type and tonumber(v.type) == 1 then
			table.insert(items, 1, v)
		else
			table.insert(items, v)
		end
	end
end

function S_Announce:InitListView()

    self.handler_listItemRenderer = handler(self, self.OnListItemRenderer)
    self.handler_onClickItemEvent = handler(self, self.OnClickListItemEvent)
    -- 区服列表Item刷新
    FGUI:GList_itemRenderer(self._ui["List_select_btns"],  self.handler_listItemRenderer)
    local num = self._announceData and #self._announceData or 0
    FGUI:GList_setNumItems(self._ui["List_select_btns"], num)
    FGUI:GList_addOnClickItemEvent(self._ui["List_select_btns"], self.handler_onClickItemEvent)
end

function S_Announce:OnListItemRenderer(idx, item)
    if not self._announceData then return end
        local data = self._announceData[idx + 1]
        if not data then return end
        FGUI:GButton_setTitle(item, data.name)
end

function S_Announce:OnClickListItemEvent(context)
    local selectIdx = FGUI:GList_getSelectedIndex(self._ui["List_select_btns"]) + 1
    self:SelectAnnounce(selectIdx)
end

function S_Announce:UpdateAnnounce()
    if not self._announceData then return end
    local data = self._announceData[self._selectIdx]
    local richText = FGUI:GetChild(self._ui["TextScrollComponent"], "RichText_Content")
    if not data then 
        FGUI:GRichTextField_setText(richText, "")
        return        
    end
    
    FGUI:GRichTextField_setText(richText, data.desc)
    local pane = FGUI:GetScrollPane(self._ui["TextScrollComponent"])
    if pane then
        FGUI:ScrollPane_scrollTop(pane, false)
    end
 
end

function S_Announce:SelectAnnounce(idx, isChangeUI)
    if isChangeUI then
        FGUI:GList_setSelectedIndex(self._ui["List_select_btns"], idx - 1)
    end
  
    if self._selectIdx == idx then return end
    self._selectIdx = idx
    self:UpdateAnnounce()
end


function S_Announce:OnAnnounceDataChange()
    self:InitAnnounceData()
    self:InitListView()
    self:SelectAnnounce(1, true)
end


-----------------------------------注册事件--------------------------------------
function S_Announce:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ANNOUNCE_CHANGE, "Announce", handler(self, self.OnAnnounceDataChange))
end

function S_Announce:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ANNOUNCE_CHANGE, "Announce")
end

return S_Announce