local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local GMBox = class("GMBox", BaseFGUILayout)
GMBox.Page1 = 1
GMBox.Page2 = 1
local GmBtnFont = {
    {
      {"修改","查询","银两+1E","银两清除","元宝+1E","元宝清除"},  
      {"修改"}, {"添加","删除"}, {"添加","删除"}, {"修改"}, {"修改"}, {"修改"}, 
    },
    {
        {"刷怪"}, {"清理"}, 
    },
    {
        {"添加","删除"}, {"清理背包"}, {"生成道具"}
    },
    {
        {"传送"}, {"清理"}, 
    },
    {
        {"修改","查询"}, {"修改","查询"}, {"修改","查询"}, {"修改","查询"},  {"修改"}, 
    },
}
function GMBox:Create()
	self._ui = FGUI:ui_delegate(self.component)
    GMBox.self = self  --绑定组件
    FGUI:setOnClickEvent(self._ui.closegm, function()  --关闭按钮
        FGUI:Close("A_gm", "GMBox")
    end)
    self.zhulist = FGUI:ui_delegate(self._ui.zhulist)
    self.list1 = FGUI:ui_delegate(self._ui.list1)
    self.list2 = FGUI:ui_delegate(self._ui.list2)
    
    --默认选中第一页第一个
    FGUI:GList_setSelectedIndex(self._ui.zhulist, 0)
    FGUI:GList_setSelectedIndex(self._ui.list1, 0)

    FGUI:GList_addOnClickItemEvent(self._ui.zhulist, function(context)
        self:changepagepre()
        local index = FGUI:GList_getSelectedIndex(self._ui.zhulist)
        GMBox.Page1 = index+1
        FGUI:GList_setSelectedIndex(self._ui['list'..GMBox.Page1], 0)
        GMBox.Page2 = 1
        self:changepage()
    end)
    for i=1,#GmBtnFont do
        FGUI:GList_addOnClickItemEvent(self._ui["list"..i], function(context)
            self:changepagepre()
            local index = FGUI:GList_getSelectedIndex(self._ui["list"..i])
            GMBox.Page2 = index+1
            self:changepage()
        end)
    end

    FGUI:setOnClickEvent(self._ui["btn_wudiclose"], function()
        ssrMessage:sendmsgEx("gmbox", "wudiclose")
    end)

    FGUI:setOnClickEvent(self._ui["btn_wudiopen"], function()
        ssrMessage:sendmsgEx("gmbox", "wudiopen")
    end)
    
    

    self:changepagepre()
    self:changepage()
end

function GMBox:changepagepre()
    FGUI:setVisible(self._ui['list'..GMBox.Page1],false)
    FGUI:setVisible(self._ui['n'..GMBox.Page1..GMBox.Page2],false)
end
function GMBox:changepage()
    FGUI:setVisible(self._ui['list'..GMBox.Page1],true)
    FGUI:setVisible(self._ui['n'..GMBox.Page1..GMBox.Page2],true)

    self:UpdateRight()
end

function GMBox:UpdateRight()
    self.right = FGUI:ui_delegate(self._ui['n'..GMBox.Page1..GMBox.Page2])

    local inputfont = ""
    for i=1,5 do
        if self.right['srk'..i] then  
            local text = FGUI:GTextInput_getText(self.right['srk'..i])
            if text == "" then
                text = "0"
            end
            if inputfont ~= "" then
                inputfont = inputfont.."|"
            end
            inputfont = inputfont..text
            FGUI:GTextInput_setOnChanged(self.right['srk'..i], function (context)
                self:UpdateRight()
            end)
        end
    end
    -- print("文本inputfont:", inputfont)
    for i=1,#GmBtnFont[GMBox.Page1][GMBox.Page2] do
        FGUI:GButton_setTitle(self.right['btn'..i], GmBtnFont[GMBox.Page1][GMBox.Page2][i])
        FGUI:setOnClickEvent(self.right['btn'..i], function()
            --SL:SendNetMsg(90002, GMBox.Page1, GMBox.Page2, i, ""..inputfont)
            ssrMessage:sendmsgEx("gmbox", "func",{GMBox.Page1,GMBox.Page2,i,inputfont})
        end)
    end

end

return GMBox