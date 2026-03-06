local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local AuctionRootPanel = class("AuctionRootPanel", BaseFGUILayout)

-- tab页签名字
local RIGHT_TAB_NAME =
{
    30000002,
    30000015,
    30000014
}

local IDX_NULL = 0
local IDX_BUY   = 1
local IDX_CONSIGNMENT = 2
local IDX_RECORD = 3

-- 拍卖行
function AuctionRootPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
    self._index = IDX_NULL

    self._pageDatas = {
        [IDX_BUY] = {
            objName = "AuctionBuyPanel",
            obj = nil,
        },
        [IDX_CONSIGNMENT] = {
            objName = "AuctionConsignMentPanel",
            obj = nil,
        },
        [IDX_RECORD] = {
            objName = "AuctionRecordPanel",
            obj = nil
        }
    }

    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitUI()
end

function AuctionRootPanel:InitUI()
        -- 初始化页签名字
    for index = 1,3 do
        local text_Content = FGUI:GetChild(self._ui["btn_right_tab_"..index],"text_Content")
        FGUI:GTextField_setText(text_Content,GET_STRING(RIGHT_TAB_NAME[index]))
    end

end

function AuctionRootPanel:PageClose()
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

function AuctionRootPanel:PageTo(index)
    if not index then return end
    if self._index  == index then return end
    self:SwtchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function AuctionRootPanel:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        pageObj = FGUI:CreateObject(self.Node_Content,"Auction",pageData.objName,true)
        pageData.obj = pageObj
    end
    FGUI:setVisible(pageObj.component,true)
    if pageObj.Enter then
        pageObj:Enter()
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end

-- 获取所有的组件和控制器
function AuctionRootPanel:GetAllFGuiData()
    self.Node_Content = self._ui.Node_Content
    self.btn_close = self._ui.btn_close
    self.btn_right_tab_1 = self._ui.btn_right_tab_1
    self.btn_right_tab_2 = self._ui.btn_right_tab_2
    self.btn_right_tab_3 = self._ui.btn_right_tab_3

    self.controller_tab_isSelectedRightTab_1 = FGUI:getController(self.btn_right_tab_1,"isSelectedRightTab")
    self.controller_tab_isSelectedRightTab_2 = FGUI:getController(self.btn_right_tab_2,"isSelectedRightTab")
    self.controller_tab_isSelectedRightTab_3 = FGUI:getController(self.btn_right_tab_3,"isSelectedRightTab")
end

function AuctionRootPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_right_tab_1,handler(self,self.BtnRightTab1Clicked))
    FGUI:setOnClickEvent(self.btn_right_tab_2,handler(self,self.BtnRightTab2Clicked))
    FGUI:setOnClickEvent(self.btn_right_tab_3,handler(self,self.BtnRightTab3Clicked))
end

function AuctionRootPanel:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

function AuctionRootPanel:BtnRightTab1Clicked()
    self:PageTo(IDX_BUY)
end

function AuctionRootPanel:BtnRightTab2Clicked()
    self:PageTo(IDX_CONSIGNMENT)
end

function AuctionRootPanel:BtnRightTab3Clicked()
    self:PageTo(IDX_RECORD)
end

-- 切换页签
function AuctionRootPanel:SwtchTab(tabIndex)
    self.controller_tab_isSelectedRightTab_1.selectedIndex = IDX_BUY == tabIndex and 0 or 1
    self.controller_tab_isSelectedRightTab_2.selectedIndex = IDX_CONSIGNMENT == tabIndex and 0 or 1
    self.controller_tab_isSelectedRightTab_3.selectedIndex = IDX_RECORD == tabIndex and 0 or 1
end

function AuctionRootPanel:RemoveEvent()
end

function AuctionRootPanel:RegisterEvent()
end

function AuctionRootPanel:Enter()
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","NPCStoreMoneyList"))
    self:InitAdapt()
    self:RegisterEvent()
    self:PageTo(IDX_BUY)

    SL:ComponentAttach(SLDefine.SUIComponentTable.AuctionMain, self._ui.Node_attach)
end

function AuctionRootPanel:Exit()
    SL:RequestAuctionClose()
    FGUIFunction:HideTopCurrency()
    SL:ComponentDetach(SLDefine.SUIComponentTable.AuctionMain)

    self:RemoveEvent()
    self:PageClose()
end
function AuctionRootPanel:Destroy()
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
function AuctionRootPanel:OnClose()
    self.super.Close(self)
end

return AuctionRootPanel


