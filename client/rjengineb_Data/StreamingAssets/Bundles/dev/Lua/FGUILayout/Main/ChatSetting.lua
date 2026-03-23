local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ChatSetting = class("ChatSetting", BaseFGUILayout)

function ChatSetting:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self:InitData()
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function ChatSetting:InitData()
    self.SaveListKey = "SaveBottomChannelListKey"
    self._channels = FGUIFunction:GetShowChannels()
    self._receiveChannelList = {}
    local cacheReceiveList = self:GetReceiveList()
    local initList = next(cacheReceiveList) == nil
    self._selectChannel = SLDefine.CHAT_CHANNEL.Common
    self.CommonIndex = 0
    for k, v in ipairs(self._channels) do
        if v.id == SLDefine.CHAT_CHANNEL.Common then
            self.CommonIndex = k
        end
        if initList then
            self._receiveChannelList[v.id] = true
        else
            local res = true
            if cacheReceiveList[tostring(v.id)] ~= nil then
                res = cacheReceiveList[tostring(v.id)]
            end
            self._receiveChannelList[v.id] = res
        end
    end
    -- print("self._receiveChannelList")
    -- SL:print_t(self._receiveChannelList)
    -- SL:print_t(self._channels)
end

function ChatSetting:GetAllFGuiData()
    self._List_channel = self._ui.List_channel
    self._btn_close = self._ui.btn_close
end

function ChatSetting:GetReceiveList()
    local cache = SL:GetLocalString(self.SaveListKey)
    if cache and cache ~="" then
        return SL:JsonDecode(cache)
    end
    return {}
end

function ChatSetting:SaveReceiveList()
    SL:SetLocalString(self.SaveListKey, SL:JsonEncode( self._receiveChannelList))
    SL:onLUAEvent(LUA_EVENT_CHAT_SETTING_UPDATE,self._receiveChannelList)
end

function ChatSetting:InitOnClickEvent()
    FGUI:setOnClickEvent(self._btn_close,handler(self,self.OnClose))
end

function ChatSetting:OnClose()
    self.super.Close(self)
end

function ChatSetting:InitUI()
    FGUI:GList_itemRenderer(self._ui.List_channel, handler(self, self.OnItemRendererListChannel))
    FGUI:GList_addOnClickItemEvent(self._ui.List_channel, handler(self, self.OnClickListChannel))
end

function ChatSetting:RefreshList()
    local cNum =math.max(0,#self._channels)
    FGUI:GList_setNumItems(self._ui.List_channel, cNum + 1)
end

function ChatSetting:IsAllCheck()
    for k,v in pairs(self._receiveChannelList) do
        if v == false then
            return false
        end
    end

    return true
end

function ChatSetting:OperatorAllValue(value)
    for k,v in pairs(self._receiveChannelList) do
        self._receiveChannelList[k] = value
    end
end

function ChatSetting:OnItemRendererListChannel(idx, item)
    if not item then
        return
    end

    local ctrl_isSelected = FGUI:getController(item,"isSelected")
    local title = FGUI:GetChild(item,"title")
    if idx == 0 then
        ctrl_isSelected.selectedIndex = self:IsAllCheck() and 0 or 1
        FGUI:GTextField_setText(title,GET_STRING(30000109))
    else    
        ctrl_isSelected.selectedIndex = self._receiveChannelList[self._channels[idx].id] and 0 or 1
        FGUI:GTextField_setText(title,self._channels[idx].str)
    end
end

function ChatSetting:OnClickListChannel(context)
    local item = context.data
	local idx = FGUI:GetChildIndex(self._ui.List_channel, item)

    if idx == 0 then
        self:OperatorAllValue(not self:IsAllCheck())
    else
        self._receiveChannelList[self._channels[idx].id] = not self._receiveChannelList[self._channels[idx].id]
    end

    self:RefreshList()
end

function ChatSetting:RegisterEvent()
end

function ChatSetting:RemoveEvent()
end

function ChatSetting:Enter()
    self:RegisterEvent()
    self:RefreshList()
end

function ChatSetting:Exit()
    self:RemoveEvent()
    self:SaveReceiveList()
end

return ChatSetting