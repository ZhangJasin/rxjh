local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCStatusBar = class("PCStatusBar", BaseFGUILayout)

local IDX_NULL          = 0
local IDX_PROPERTY      = 1
local IDX_QIGONG        = 2

function PCStatusBar:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:setDragable(self._ui.dragGrapic,true)
    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_PROPERTY] = {
            objName = "PCPlayerPropertyPanel",
            obj = nil,
            tabName = 30000045
        },
    }
    
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCStatusBar:InitData()
end

function PCStatusBar:InitUI()
end

function PCStatusBar:GetAllFGuiData()
    self.node_panel = self._ui.node_panel
    self.btn_close = self._ui.btn_close
end

function PCStatusBar:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCStatusBar:OnClose()
    self.super.Close(self)
end

function PCStatusBar:PageClose()
    local pageData = self._pageDatas[self._index]
    if not pageData then return true end
    local pageObj = pageData.obj
    if pageObj and pageObj.Exit then
        pageObj:Exit()
        FGUI:setVisible(pageObj.component, false)
    else
        SL:PrintEx("[ERROR] pageObj or pageObj.Exit 不存在 没有Exit方法")
    end
    self._index = IDX_NULL
    return true
end

function PCStatusBar:PageTo(index)
    if not index then return end
    if self._index  == index then return end
    self:SwitchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function PCStatusBar:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        if not pageData.objName then
            return
        end
        pageObj = FGUI:CreateObject(self.node_panel,"Bag_pc",pageData.objName,true)
        pageData.obj = pageObj
    end
    FGUI:setVisible(pageObj.component,true)
    if pageObj.Enter then
        pageObj:Enter()
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end

-- 切换页签显示
function PCStatusBar:SwitchTab(tabIndex)
    if not tabIndex then
        return
    end
end

function PCStatusBar:Enter(pageIndex)
    if not pageIndex then
        pageIndex = IDX_PROPERTY
    end
    self:RegisterEvent()
    self:PageTo(pageIndex)
end

function PCStatusBar:Exit()
    self:RemoveEvent()
end

function PCStatusBar:Destroy()
end

function PCStatusBar:RegisterEvent()
end
--移除事件
function PCStatusBar:RemoveEvent()
end

return PCStatusBar



