local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCBarRootPanel = class("PCBarRootPanel", BaseFGUILayout)

local IDX_NULL                                                  = 0
local IDX_PROPERTY                                              = 1 -- 属性栏
local IDX_TITLE                                                 = 2 -- 称号

function PCBarRootPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)
    -- FGUI:setDragable(self._ui.dragGrapic,true)
    -- FGUI:SetCloseUIWhenClickOutside(self)
    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_PROPERTY] = {
            objName = "PCPropertyBar",
            obj = nil,
            tabName = 30000116 --属性栏
        },
        [IDX_TITLE] = {
            objName = "PCTitleBar",
            obj = nil,
            tabName = 30000117,--称号栏
        }
    }

    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCBarRootPanel:GetAllFGuiData()
    self.node_panel = self._ui.node_panel
    self.text_title = self._ui.text_title
    self.btn_close = self._ui.btn_close
    self.btn_tab_1 = self._ui.btn_tab_1
    self.btn_tab_2 = self._ui.btn_tab_2
end

function PCBarRootPanel:PageClose()
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

function PCBarRootPanel:PageTo(index)
    if not index then return end
    if self._index  == index then return end
    self:SwitchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function PCBarRootPanel:PageOpen(index)
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

function PCBarRootPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_tab_1,handler(self,self.BtnTab1Clicked))
    FGUI:setOnClickEvent(self.btn_tab_2,handler(self,self.BtnTab2Clicked))
end
function PCBarRootPanel:BtnTab1Clicked()
    self:PageTo(IDX_PROPERTY)
end

function PCBarRootPanel:BtnTab2Clicked()
    self:PageTo(IDX_TITLE)
end

function PCBarRootPanel:InitData()
end

function PCBarRootPanel:InitUI()
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        if tabComp then
            local textComp = FGUI:GetChild(tabComp,"text_content")
            FGUI:GTextField_setText(textComp,GET_STRING(self._pageDatas[index].tabName))
        end
    end
end

-- 切换页签显示
function PCBarRootPanel:SwitchTab(tabIndex)
    if not tabIndex then
        return
    end
    FGUI:GTextField_setText(self.text_title,GET_STRING(self._pageDatas[tabIndex].tabName))
    -- 设置页签选中显示状态
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        local controller = FGUI:getController(tabComp,"isSelected")
        FGUI:Controller_setSelectedIndex(controller,index == tabIndex and 0 or 1)
    end
end

function PCBarRootPanel:OnClose()
    self.super.Close(self)
end

function PCBarRootPanel:Enter(pageIndex)
    if not pageIndex then
        pageIndex = IDX_PROPERTY
    end

    self:PageTo(pageIndex)
end

function PCBarRootPanel:Destroy()
    self._ui = nil
    self._pageDatas = nil
end

function PCBarRootPanel:Exit()
    self:RemoveEvent()
    self:PageClose()
end

function PCBarRootPanel:RegisterEvent()
end

--移除事件
function PCBarRootPanel:RemoveEvent()
end

return PCBarRootPanel