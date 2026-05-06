local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ShipApplyLists = class("ShipApplyLists", BaseFGUILayout)

function ShipApplyLists:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function ShipApplyLists:Close()
    FGUI:Close("MentorShip", "ShipApplyLists")
end

function ShipApplyLists:Enter(data)
    FGUI:GList_setNumItems(self._ui.list, 0)
    self._mode = (data and tonumber(data.mode)) or 1
    FGUI:GList_itemRenderer(self._ui.list,
        function(idx, item)
            local itemData = data[idx + 1]
            if not itemData then return end
            local name = FGUI:GetChild(item, "name")
            local lv = FGUI:GetChild(item, "lv")
            local guildName = FGUI:GetChild(item, "guildName")
            local vatar = FGUI:GetChild(item, "avator")
            FGUI:GTextField_setText(name, itemData.UserName)
            FGUI:GTextField_setText(lv, itemData.Level)
            FGUI:GTextField_setText(guildName, itemData.GuildName)
            if vatar then
                local AVATOR_DATA = {}
                if FGUIFunction.ClearCommonPlayerFrame then
                    FGUIFunction:ClearCommonPlayerFrame(vatar)
                end
                AVATOR_DATA.AvatarID = itemData.AvatarID
                AVATOR_DATA.Job = itemData.Job
                AVATOR_DATA.Sex = itemData.Sex
                AVATOR_DATA.FrameID = itemData.PhotoframeID
                FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
            end
            local agree = FGUI:GetChild(item, "agree")
            local notAgree = FGUI:GetChild(item, "notAgree")
            FGUI:setOnClickEvent(agree, function()
                self:Close()
                ssrMessage:sendmsgEx("MentorShip", "doOper", { mode = self._mode, status = 1, targetData = itemData })
            end)
            FGUI:setOnClickEvent(notAgree, function()
                self:Close()
                ssrMessage:sendmsgEx("MentorShip", "doOper", { mode = self._mode, status = 2, targetData = itemData })
            end)
        end
    )
    ShipApplyListsUI.CCUI = self
    ssrMessage:sendmsgEx("MentorShip", "GetApplyList", self._mode)
end

function ShipApplyLists:setList(data)
    if #data > 0 then
        self = ShipApplyListsUI.CCUI
        FGUI:GList_setNumItems(self._ui.list, #data)
    else
        FGUI:Close("MentorShip", "ShipApplyLists")
    end
end

return ShipApplyLists
