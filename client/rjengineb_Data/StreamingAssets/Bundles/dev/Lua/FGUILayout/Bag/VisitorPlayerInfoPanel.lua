local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorPlayerInfoPanel = class("VisitorPlayerInfoPanel", BaseFGUILayout)

local IDX_NULL = 0
local IDX_EQUIP   = 1
local IDX_STATEMENT = 2
local IDX_TITLE = 3 -- 称号
local IDX_MONEY = 4 -- 货币

function VisitorPlayerInfoPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)

    self._tradingData = {}
    
    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_EQUIP] = {
            objName = "VisitorBagPanel",
            obj = nil,
            tabName = 30000045 -- 装备栏
        },
        [IDX_STATEMENT] = {
            objName = "VisitorComponentPropertyPanel",
            obj = nil,
            tabName = 30000046 --状态栏
        },
        [IDX_TITLE] = {
            objName = "VisitorComponentTitlePanel",
            obj = nil,
            tabName = 30000110,--称号栏
        },
        [IDX_MONEY] = {
            objName = "VisitorMoneyPanel",
            obj = nil,
            tabName = "货币",--货币栏
        }
    }

    self._leftObj = nil

    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function VisitorPlayerInfoPanel:GetAllFGuiData()
    self.node_left = self._ui.node_left
    self.node_right = self._ui.node_right
    self.btn_close = self._ui.btn_close
    self.btn_tab_1 = self._ui.btn_tab_1
    self.btn_tab_2 = self._ui.btn_tab_2
    self.btn_tab_3 = self._ui.btn_tab_3
    self.btn_tab_4 = self._ui.btn_tab_4

    self.btn_bag_warehouse = self._ui.btn_bag_warehouse
    self.btn_bag_extra = self._ui.btn_bag_extra

    self.controller = FGUI:getController(self.component,"PageKind")
end

function VisitorPlayerInfoPanel:PageClose()
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

function VisitorPlayerInfoPanel:PageTo(index)
    if not index then return end
    self.controller.selectedIndex = index
    if self._index  == index then return end
    self:SwitchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function VisitorPlayerInfoPanel:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        if not pageData.objName then
            return
        end
        pageObj = FGUI:CreateObject(self.node_right,"Bag",pageData.objName,true)
        pageData.obj = pageObj
    end
    FGUI:setVisible(pageObj.component,true)
    if pageObj.Enter then
        pageObj:Enter()
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end

function VisitorPlayerInfoPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_tab_1,handler(self,self.BtnTab1Clicked)) -- 装备
    FGUI:setOnClickEvent(self.btn_tab_2,handler(self,self.BtnTab2Clicked)) -- 状态
    FGUI:setOnClickEvent(self.btn_tab_3,handler(self,self.BtnTab3Clicked)) -- 称号
    FGUI:setOnClickEvent(self.btn_tab_4,handler(self,self.BtnTab4Clicked)) -- 货币
    FGUI:setOnClickEvent(self.btn_bag_warehouse,handler(self,self.BtnBagWareHouseClicked))--仓库
    FGUI:setOnClickEvent(self.btn_bag_extra,handler(self,self.BtnExtraBagClicked))--附加仓库
end

-- 仓库
function VisitorPlayerInfoPanel:BtnBagWareHouseClicked()
    FGUI:Close("Bag","VisitorPlayerInfoPanel")
    FGUI:Open("Bag", "VisitorStoragePanel",{fromPanel = 1})
end

-- 附加仓库
function VisitorPlayerInfoPanel:BtnExtraBagClicked()
    FGUI:Close("Bag","VisitorPlayerInfoPanel")
    FGUI:Open("Bag", "VisitorStorageExPanel")
end

-- 装备
function VisitorPlayerInfoPanel:BtnTab1Clicked()
    self:PageTo(IDX_EQUIP)
end

-- 状态
function VisitorPlayerInfoPanel:BtnTab2Clicked()
    self:PageTo(IDX_STATEMENT)
end

-- 称号
function VisitorPlayerInfoPanel:BtnTab3Clicked()
    self:PageTo(IDX_TITLE)
end

-- 货币
function VisitorPlayerInfoPanel:BtnTab4Clicked()
    self:PageTo(IDX_MONEY)
end

function VisitorPlayerInfoPanel:InitUI()
    -- 页签名字设置
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        if tabComp then
            local textComp = FGUI:GetChild(tabComp,"text_content")
            if index == 4 then
                FGUI:GTextField_setText(textComp,self._pageDatas[index].tabName or "")
            else
                FGUI:GTextField_setText(textComp,GET_STRING(self._pageDatas[index].tabName))
            end
        end
    end
end

-- 切换页签显示
function VisitorPlayerInfoPanel:SwitchTab(tabIndex)
    if not tabIndex then
        return
    end
    -- 设置页签选中显示状态
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        local controller = FGUI:getController(tabComp,"isSelected")
        FGUI:Controller_setSelectedIndex(controller,index == tabIndex and 0 or 1)
    end
end

function VisitorPlayerInfoPanel:OnClose()
    self.super.Close(self)
end

function VisitorPlayerInfoPanel:Enter(pageIndex)
    if not pageIndex then
        pageIndex = IDX_STATEMENT
    end
    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag","VisitorComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end

    if self._leftObj.Enter then
        self._leftObj:Enter()
    end

    self:PageTo(pageIndex)

    SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorPlayerInfoMain, self._ui.Node_attach)
end


function VisitorPlayerInfoPanel:Destroy()
    local pageData = self._pageDatas[IDX_EQUIP]
    if pageData then
        local pageObj = pageData.obj
        if pageObj then
            pageObj:CleanItem()
        end
    end
    if self._leftObj then
        self._leftObj:ReleaseAllEquipItem()
    end
    self._ui = nil
    self._pageDatas = nil
    self._leftObj = nil
end

function VisitorPlayerInfoPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorPlayerInfoMain)
    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag","VisitorComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end
    if self._leftObj and self._leftObj.Exit then
        self._leftObj:Exit()
    end
    self:PageClose()
end

function VisitorPlayerInfoPanel:BagCellDoubleClickEvent(bagItem)

end

return VisitorPlayerInfoPanel