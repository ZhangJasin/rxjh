local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCPlayerInfoPanel = class("PCPlayerInfoPanel", BaseFGUILayout)

local IDX_NULL = 0
local IDX_EQUIP   = 1
local IDX_STATEMENT = 2
local IDX_TITLE = 3 -- 称号
local IDX_PET = 4 -- 灵兽
local IDX_REBIRTH = 5 -- 转职

function PCPlayerInfoPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

    self._tradingData = {}
    
    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_EQUIP] = {
            objName = "PCBagPanel",
            obj = nil,
            tabName = 30000045 -- 装备栏
        },
        [IDX_STATEMENT] = {
            objName = "PCComponentPropertyPanel",
            obj = nil,
            tabName = 30000046 --状态栏
        },
        [IDX_TITLE] = {
            objName = "PCComponentTitlePanel",
            obj = nil,
            tabName = 30000110,--称号栏
        },
        [IDX_PET] = {
            objName = "PCComponentPetPanel",
            obj = nil,
            tabName = 1000001,--灵兽栏
        },
        [IDX_REBIRTH] = {
            objName = "PCComponentRebirthPanel",
            obj = nil,
            tabName = 1000002,--转职栏
        }
    }

    self._leftObj = nil

    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCPlayerInfoPanel:GetAllFGuiData()
    self.node_left = self._ui.node_left
    self.node_right = self._ui.node_right
    self.btn_close = self._ui.btn_close
    self.btn_tab_1 = self._ui.btn_tab_1
    self.btn_tab_2 = self._ui.btn_tab_2
    self.btn_tab_3 = self._ui.btn_tab_3
    self.btn_tab_4 = self._ui.btn_tab_4
    self.btn_tab_5 = self._ui.btn_tab_5
    self.btn_bag_sort = self._ui.btn_bag_sort
    self.btn_bag_warehouse = self._ui.btn_bag_warehouse
    self.btn_bag_recycle = self._ui.btn_bag_recycle
    self.btn_bag_extra = self._ui.btn_bag_extra
    self.graph_drag = self._ui.graph_drag
    self.controller = FGUI:getController(self.component,"PageKind")
end

function PCPlayerInfoPanel:PageClose()
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

function PCPlayerInfoPanel:PageTo(index)
    if not index then return end
    self.controller.selectedIndex = index
    if self._index  == index then return end
    self:SwitchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function PCPlayerInfoPanel:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        if not pageData.objName then
            return
        end
        pageObj = FGUI:CreateObject(self.node_right,"Bag_pc",pageData.objName,true)
        pageData.obj = pageObj
    end

    if pageObj.component then
        FGUI:setVisible(pageObj.component,true)
    end

    if pageObj.Enter then
        pageObj:Enter(self._tradingData.tradingIndex)
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end

function PCPlayerInfoPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_tab_1,handler(self,self.BtnTab1Clicked))
    FGUI:setOnClickEvent(self.btn_tab_2,handler(self,self.BtnTab2Clicked))
    FGUI:setOnClickEvent(self.btn_tab_3,handler(self,self.BtnTab3Clicked))
    FGUI:setOnClickEvent(self.btn_tab_4,handler(self,self.BtnTab4Clicked))
    FGUI:setOnClickEvent(self.btn_tab_5,handler(self,self.BtnTab5Clicked))
    FGUI:setOnClickEvent(self.btn_bag_sort,handler(self,self.BtnBagSortClicked))
    FGUI:setOnClickEvent(self.btn_bag_warehouse,handler(self,self.BtnBagWareHouseClicked))
    FGUI:setOnClickEvent(self.btn_bag_recycle,handler(self,self.BtnBagRecycleClicked))
    FGUI:setOnClickEvent(self.btn_bag_extra,handler(self,self.BtnExtraBagClicked))
end

function PCPlayerInfoPanel:BtnBagRecycleClicked()
    FGUI:Close("Bag_pc","PCPlayerInfoPanel")
    FGUI:Open("Bag_pc", "BagRecyclePanel",{fromPanel = 1})
end

function PCPlayerInfoPanel:BtnBagWareHouseClicked()
    FGUI:Close("Bag_pc","PCPlayerInfoPanel")
    FGUI:Open("Bag_pc", "PCStoragePanel",{fromPanel = 1})
end

function PCPlayerInfoPanel:BtnExtraBagClicked()
    FGUI:Close("Bag_pc","PCPlayerInfoPanel")
    --FGUI:Open("Bag_pc", "OneFilterBagPanel",{title = GET_STRING(60003002) ,filterType = 3})
    FGUI:Open("Bag_pc", "PCStorageExPanel", 1)
end

function PCPlayerInfoPanel:BtnBagSortClicked()
    SL:RequestRefreshBagPos()
end

function PCPlayerInfoPanel:BtnTab1Clicked()
    self:PageTo(IDX_EQUIP)
end

function PCPlayerInfoPanel:BtnTab2Clicked()
    self:PageTo(IDX_STATEMENT)
end

function PCPlayerInfoPanel:BtnTab3Clicked()
    self:PageTo(IDX_TITLE)
end

function PCPlayerInfoPanel:BtnTab4Clicked()
    FGUI:Open("Mount", "mountMain")
end

function PCPlayerInfoPanel:BtnTab5Clicked()
    --self:PageTo(IDX_REBIRTH)
end

function PCPlayerInfoPanel:InitData()
end

function PCPlayerInfoPanel:InitUI()
    -- 页签名字设置
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        if tabComp then
            local textComp = FGUI:GetChild(tabComp,"text_content")
            FGUI:GTextField_setText(textComp,GET_STRING(self._pageDatas[index].tabName))
        end
    end
end

-- 切换页签显示
function PCPlayerInfoPanel:SwitchTab(tabIndex)
    if not tabIndex then
        return
    end
    -- 设置页签选中显示状态
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        local controller = FGUI:getController(tabComp,"isSelected")
        FGUI:Controller_setSelectedIndex(controller,index == tabIndex and 0 or 1)
    end

    if self._leftObj then
        self._leftObj:SwitchCtlisShowTitile(tabIndex == IDX_TITLE)
        if tabIndex == IDX_TITLE then
            self._leftObj:RefreshTitle()
        end
    end
end

function PCPlayerInfoPanel:OnClose()
    self.super.Close(self)
end

function PCPlayerInfoPanel:RefreshBag()
    if self._index == IDX_EQUIP then
       local pageData = self._pageDatas[IDX_EQUIP]
        if pageData then
            local pageObj = pageData.obj
            if pageObj then
                pageObj:Enter()
            end
        end
    end
end

function PCPlayerInfoPanel:Enter(pageIndex)
    local index = IDX_STATEMENT
    self._tradingData = {}
    if type(pageIndex) == "table" then
        index = pageIndex.index
        self._tradingData  = pageIndex
    else
        index = pageIndex
        if not pageIndex then
            index = IDX_STATEMENT
        end
    end
    self:RegisterEvent()
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","BagMoneyList"))
    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag_pc","PCComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end

    if self._leftObj.Enter then
        self._leftObj:Enter()
    end

    self:PageTo(index)


    SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoMain, self._ui.Node_attach)
end


function PCPlayerInfoPanel:Destroy()
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

function PCPlayerInfoPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoMain)
    self:RemoveEvent()
    FGUIFunction:HideTopCurrency()
    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag_pc","PCComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end

    if self._leftObj.Exit then
        self._leftObj:Exit()
    end

    self:PageClose()
end


function PCPlayerInfoPanel:RegisterEvent()
end

--移除事件
function PCPlayerInfoPanel:RemoveEvent()
end

return PCPlayerInfoPanel
