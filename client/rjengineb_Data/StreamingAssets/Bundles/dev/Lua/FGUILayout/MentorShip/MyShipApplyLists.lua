local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MyShipApplyLists = class("MyShipApplyLists", BaseFGUILayout)

function MyShipApplyLists:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    MyShipApplyListsUI.CCUI = self
end
function MyShipApplyLists:Close()
    self.super.Close(self)
end
function MyShipApplyLists:Enter(data)
    FGUI:GList_setNumItems(self._ui.list,0)
    self.fromPanel = data
    ssrMessage:sendmsgEx("MentorShip", "GetApplyList",3)
end
function MyShipApplyLists:initList(data)
    FGUI:GList_itemRenderer(self._ui.list,
        function (idx,item)
            local itemData = data[idx+1]
            local todoController = FGUI:getController(item,"todo")
            local model = 1
            if itemData.todoType == 1 then
                model = 2
                FGUI:Controller_setSelectedIndex(todoController,1)
            else
                FGUI:Controller_setSelectedIndex(todoController,0)
                model = 1
            end
            local name = FGUI:getChild(item, "name")
            local lv = FGUI:getChild(item, "lv")
            local guildName = FGUI:getChild(item, "guildName")
            local vatar = FGUI:GetChild(item, "avator")
            FGUI:GTextField_setText(name, itemData.UserName)
            FGUI:GTextField_setText(lv, itemData.Level)
            FGUI:GTextField_setText(guildName, itemData.GuildName)
            if vatar then
                if FGUIFunction.ClearCommonPlayerFrame then
                    FGUIFunction:ClearCommonPlayerFrame(vatar)
                end
                AVATOR_DATA.AvatarID = itemData.AvatarID
                AVATOR_DATA.Job = itemData.Job
                AVATOR_DATA.Sex = itemData.Sex
                AVATOR_DATA.FrameID = itemData.PhotoframeID
			    FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
		    end
        end
    )
    FGUI:GList_setNumItems(self._ui.list,#data)
end
function MyShipApplyLists:setList(data)
    self = MyShipApplyListsUI.CCUI
    FGUI:GList_itemRenderer(self._ui.list,
        function (idx,item)
            local itemData = data[idx+1]
            local name = FGUI:GetChild(item, "name")
            local lv = FGUI:GetChild(item, "lv")
            local guildName = FGUI:GetChild(item, "guildName")
            local vatar = FGUI:GetChild(item, "avator")
            local model = 1
            local todoController = FGUI:getController(item,"todo")
            if itemData.todoType == 1 then
                FGUI:Controller_setSelectedIndex(todoController,1)
                model = 2
            end
            if itemData.todoType == 2 then
                FGUI:Controller_setSelectedIndex(todoController,2)
                model = 1
            end
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
                ssrMessage:sendmsgEx("MentorShip", "doOper",{mode=model,status = 1,targetData = itemData,fromPanel = 'MyShipApplyLists'})
            end)
            FGUI:setOnClickEvent(notAgree, function()
                ssrMessage:sendmsgEx("MentorShip", "doOper",{mode=model,status = 2,targetData = itemData,fromPanel = 'MyShipApplyLists'})
            end)
        end
    )
    FGUI:GList_setNumItems(self._ui.list,#data)
end 

return MyShipApplyLists