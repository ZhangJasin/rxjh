local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PlayerInfoPanel = class("PlayerInfoPanel", BaseFGUILayout)

local IDX_NULL = 0
local IDX_EQUIP   = 1
local IDX_STATEMENT = 2
local IDX_TITLE = 3 -- 称号

function PlayerInfoPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)

    self._tradingData = {}
    
    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_EQUIP] = {
            objName = "BagPanel",
            obj = nil,
            tabName = 30000045 -- 装备栏
        },
        [IDX_STATEMENT] = {
            objName = "ComponentPropertyPanel",
            obj = nil,
            tabName = 30000046 --状态栏
        }
        --[IDX_TITLE] = {
        --    objName = "ComponentTitlePanel",
        --    obj = nil,
        --    tabName = 30000110,--称号栏
        --}
    }

    self._leftObj = nil

    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PlayerInfoPanel:GetAllFGuiData()
    self.node_left = self._ui.node_left
    self.node_right = self._ui.node_right
    self.btn_close = self._ui.btn_close
    self.btn_tab_1 = self._ui.btn_tab_1
    self.btn_tab_2 = self._ui.btn_tab_2
    self.btn_tab_3 = self._ui.btn_tab_3
    self.btn_bag_sort = self._ui.btn_bag_sort
    self.btn_bag_warehouse = self._ui.btn_bag_warehouse
    self.btn_bag_recycle = self._ui.btn_bag_recycle
    self.btn_bag_extra = self._ui.btn_bag_extra
    self.btn_bag_shared = self._ui.btn_bag_shared
    self.btn_bag_wareShop = self._ui.btn_bag_wareShop
    self.controller = FGUI:getController(self.component,"PageKind")
end

function PlayerInfoPanel:PageClose()
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

function PlayerInfoPanel:PageTo(index)
    if not index then return end
    self.controller.selectedIndex = index
    if self._index  == index then return end
    self:SwitchTab(index)
    self:PageClose()
    self:PageOpen(index)
end

function PlayerInfoPanel:PageOpen(index)
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

function PlayerInfoPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_tab_1,handler(self,self.BtnTab1Clicked))
    FGUI:setOnClickEvent(self.btn_tab_2,handler(self,self.BtnTab2Clicked))
    FGUI:setOnClickEvent(self.btn_tab_3,handler(self,self.BtnTab3Clicked))
    FGUI:setOnClickEvent(self.btn_bag_sort,handler(self,self.BtnBagSortClicked))
    FGUI:setOnClickEvent(self.btn_bag_warehouse,handler(self,self.BtnBagWareHouseClicked))
    FGUI:setOnClickEvent(self.btn_bag_recycle,handler(self,self.BtnBagRecycleClicked))
    FGUI:setOnClickEvent(self.btn_bag_extra,handler(self,self.BtnExtraBagClicked))
    FGUI:setOnClickEvent(self.btn_bag_shared,handler(self,self.BtnSharedClicked))
    FGUI:setOnClickEvent(self.btn_bag_wareShop,handler(self,self.BtnBagWareShopClicked))
    FGUI:GButton_setTitle(self.btn_bag_recycle, "回收")

end
function PlayerInfoPanel:BtnBagWareShopClicked()
    self.super.Close(self)
    ssrMessage:sendmsgEx("bag","openWareShop")
end
function PlayerInfoPanel:BtnBagRecycleClicked()
    FGUI:Close("Bag","PlayerInfoPanel")
    FGUI:Open("Bag", "BagRecyclePanel",{fromPanel = 1})
end

function PlayerInfoPanel:BtnBagWareHouseClicked()
    FGUI:Close("Bag","PlayerInfoPanel")
    FGUI:Open("Bag", "StoragePanel",{fromPanel = 1})
end

function PlayerInfoPanel:BtnExtraBagClicked()
    FGUI:Close("Bag","PlayerInfoPanel")
    --FGUI:Open("Bag", "OneFilterBagPanel",{title = GET_STRING(60003002) ,filterType = 3})
    FGUI:Open("Bag", "StorageExPanel", 1)
end

function PlayerInfoPanel:BtnSharedClicked()
    FGUI:Close("Bag","PlayerInfoPanel")
    FGUI:Open("Bag","SharedStoragePanel")
end

function PlayerInfoPanel:BtnBagSortClicked()
    SL:RequestRefreshBagPos()
end

function PlayerInfoPanel:BtnTab1Clicked()
    self:PageTo(IDX_EQUIP)
end

function PlayerInfoPanel:BtnTab2Clicked()
    self:PageTo(IDX_STATEMENT)
end

function PlayerInfoPanel:BtnTab3Clicked()
    self:PageTo(IDX_TITLE)
end

function PlayerInfoPanel:InitData()
end

function PlayerInfoPanel:InitUI()
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
function PlayerInfoPanel:SwitchTab(tabIndex)
    if not tabIndex then
        return
    end
    -- 设置页签选中显示状态
    for index = 1,table.nums(self._pageDatas) do
        local tabComp = self._ui["btn_tab_" .. index]
        local controller = FGUI:getController(tabComp,"isSelected")
        FGUI:Controller_setSelectedIndex(controller,index == tabIndex and 0 or 1)
    end
    -- 在页签切换时是否显示称号
    if self._leftObj then
        self._leftObj:SwitchCtlisShowTitile(tabIndex == IDX_TITLE)
        if tabIndex == IDX_TITLE then
            self._leftObj:RefreshTitle()
        end
    end
end

function PlayerInfoPanel:OnClose()
    self.super.Close(self)
end

function PlayerInfoPanel:RefreshBag()
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

function PlayerInfoPanel:Enter(pageIndex)
    if not pageIndex then
        pageIndex = IDX_STATEMENT
    end
    self:RegisterEvent()
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","BagMoneyList"))

    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag","ComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end

    if self._leftObj.Enter then
        self._leftObj:Enter()
    end


    ------------交易行截图begin----------
    local index = global.TradingCaptureDatas and global.TradingCaptureDatas.index
    if index then
        pageIndex = index
    end
    ------------交易行截图end----------

    self:PageTo(pageIndex)

    SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoMain, self._ui.Node_attach)
    if pageIndex == IDX_EQUIP then
        FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.PlayerInfoGuide,self._ui)
    end
end


function PlayerInfoPanel:Destroy()
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

function PlayerInfoPanel:Exit()    
    SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoMain)
    self:RemoveEvent()
    FGUIFunction:HideTopCurrency()
    if not self._leftObj then
        self._leftObj = FGUI:CreateObject(self.node_left,"Bag","ComponentEquipPanel",true)
        FGUI:setVisible(self._leftObj.component,true)
    end

    if self._leftObj and self._leftObj.Exit then
        self._leftObj:Exit()
    end

    self:PageClose()
    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.PlayerInfoGuide)
end

function PlayerInfoPanel:BagCellDoubleClickEvent(bagItem)
    -- 检查是否为回城符,如果是则直接调用回城接口
    local BACK_CITY_ITEM_IDS = { 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140 }
    local isBackCityItem = false
    if bagItem._itemData then
        for i = 1, #BACK_CITY_ITEM_IDS do
            if BACK_CITY_ITEM_IDS[i] == bagItem._itemData.ID then
                isBackCityItem = true
                break
            end
        end
    end
    
    if isBackCityItem then
        local righttoppanlData = requireFGUILayout("A_Right/righttoppanlData")
        righttoppanlData:Get():RequestBackCity({ bagItem._itemData.ID })
        return
    end
    
    SL:RequestUseItem(bagItem._itemData)
end

function PlayerInfoPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_DOUBLE_CLICK, "PlayerInfoPanel",  handler(self,self.BagCellDoubleClickEvent))
end

--移除事件
function PlayerInfoPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_DOUBLE_CLICK, "PlayerInfoPanel")
end
return PlayerInfoPanel