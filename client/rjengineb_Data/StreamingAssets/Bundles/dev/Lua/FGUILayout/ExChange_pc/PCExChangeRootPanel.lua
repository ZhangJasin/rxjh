local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCExChangeRootPanel = class("PCExChangeRootPanel", BaseFGUILayout)

local RIGHT_TAB_NAME =
{
    30000002,
    30000601,
    30000014
}

local IDX_NULL = 0
local IDX_BUY = 1
local IDX_LAUNCH = 2
local IDX_RECORD = 3

--- 界面被创建时调用
function PCExChangeRootPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)
    self._index = IDX_NULL

    self._pageDatas = {
        [IDX_BUY] = {
            objName = "PCExChangeBuyPanel",
            obj = nil,
        },
        [IDX_LAUNCH] = {
            objName = "PCExChangeLaunchPanel",
            obj = nil,
        },
        [IDX_RECORD] = {
            objName = "PCExChangeRecordPanel",
            obj = nil,
        },
    }

    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitUI()
end

function PCExChangeRootPanel:GetAllFGuiData()
    self.Node_Content = self._ui.Node_Content
    self.btn_close = self._ui.btn_close
    self.btn_right_tab_1 = self._ui.btn_right_tab_1
    self.btn_right_tab_2 = self._ui.btn_right_tab_2
    self.btn_right_tab_3 = self._ui.btn_right_tab_3

    self.controller_tab_isSelectedRightTab_1 = FGUI:getController(self.btn_right_tab_1,"isSelectedRightTab")
    self.controller_tab_isSelectedRightTab_2 = FGUI:getController(self.btn_right_tab_2,"isSelectedRightTab")
    self.controller_tab_isSelectedRightTab_3 = FGUI:getController(self.btn_right_tab_3,"isSelectedRightTab")
end

function PCExChangeRootPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.BtnCloseClicked))
    FGUI:setOnClickEvent(self.btn_right_tab_1,handler(self,self.BtnRightTab1Clicked))
    FGUI:setOnClickEvent(self.btn_right_tab_2,handler(self,self.BtnRightTab2Clicked))
    FGUI:setOnClickEvent(self.btn_right_tab_3,handler(self,self.BtnRightTab3Clicked))
end


function PCExChangeRootPanel:BtnRightTab1Clicked()
    self:PageTo(IDX_BUY)
end

function PCExChangeRootPanel:BtnRightTab2Clicked()
    self:PageTo(IDX_LAUNCH)
end

function PCExChangeRootPanel:BtnRightTab3Clicked()
    self:PageTo(IDX_RECORD)
end

function PCExChangeRootPanel:InitUI()
     for index = 1,3 do
        local text_Content = FGUI:GetChild(self._ui["btn_right_tab_"..index],"text_Content")
        FGUI:GTextField_setText(text_Content,GET_STRING(RIGHT_TAB_NAME[index]))
    end
end



function PCExChangeRootPanel:PageClose()
    local pageData = self._pageDatas[self._index]
    if not pageData then return true end
    local pageObj = pageData.obj
    if pageObj and pageObj.Exit then
        pageObj:Exit()
        FGUI:setVisible(pageObj.component, false)
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Exit方法")
    end
    self._index = IDX_NULL
    return true
end

function PCExChangeRootPanel:PageTo(index)
    if not index then return end
    if self._index  == index then return end
    self:SwtchTab(index)
    self:PageClose()
    self:PageOpen(index)
end
-- 切换页签
function PCExChangeRootPanel:SwtchTab(tabIndex)
    self.controller_tab_isSelectedRightTab_1.selectedIndex = IDX_BUY == tabIndex and 0 or 1
    self.controller_tab_isSelectedRightTab_2.selectedIndex = IDX_LAUNCH == tabIndex and 0 or 1
    self.controller_tab_isSelectedRightTab_3.selectedIndex = IDX_RECORD == tabIndex and 0 or 1
end

function PCExChangeRootPanel:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        pageObj = FGUI:CreateObject(self.Node_Content,"ExChange_pc",pageData.objName,true)
        pageData.obj = pageObj
    end
    FGUI:setVisible(pageObj.component,true)
    if pageObj.Enter then
        pageObj:Enter()
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end


function PCExChangeRootPanel:BtnCloseClicked()
    self.super.Close(self)
end

--- 界面打开时调用
function PCExChangeRootPanel:Enter(data)
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","NPCStoreMoneyList"))
    self:PageTo(IDX_BUY)

    SL:ComponentAttach(SLDefine.SUIComponentTable.AuctionMain, self._ui.Node_attach)
end

--- 界面打开和刷新时调用
function PCExChangeRootPanel:Refresh(data)
end

--- 界面关闭时调用
function PCExChangeRootPanel:Exit()
    SL:RequestExClose()
    FGUIFunction:HideTopCurrency()
    SL:ComponentDetach(SLDefine.SUIComponentTable.AuctionMain)
    self:PageClose()
end

--- 界面销毁时调用
function PCExChangeRootPanel:Destroy()
    self._ui = nil
    for k,v in pairs(self._pageDatas) do
        if v and v.obj then
            if v.obj.CleanCache then
                v.obj:CleanCache()
            end
        end
    end
    self._pageDatas = nil
end

return PCExChangeRootPanel
