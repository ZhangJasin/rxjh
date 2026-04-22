local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local equipCollect = class("equipCollect", BaseFGUILayout)

function equipCollect:Create()
    --常量设置
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")

    --初始化请求数据

    --初始化UI组件
    self._ui = FGUI:ui_delegate(self.component)


    --默认页签数据
    self:initPageLists()

    --绑定事件
    self:bindEvents()

    --冗余设置
    FGUI:SetCloseUIWhenClickOutside(self)               --点击空白关闭
    FGUI:setOnClickEvent(self._ui.btn_close, function() --关闭按钮
        FGUI:Close("Z_Jasin", isPC and "equipCollect" or "equipCollect")
    end)
    --适配pc端UI
    if isPC then
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end
end

function equipCollect:initPageLists()
    print("equipCollect:initPageLists()")

    --默认页签数据
    FGUI:GList_setSelectedIndex(self._ui.pageList, 0)
    --TODO:默认武器页面
end

function equipCollect:bindEvents()
    FGUI:GList_addOnClickItemEvent(self._ui.pageList, function()
        local index = FGUI:GList_getSelectedIndex(self._ui.pageList)
        if index == 0 then
            print("武器页面")
        elseif index == 1 then
            print("防具页面")
        else
            print("首饰页面")
        end
    end)
end

return equipCollect
