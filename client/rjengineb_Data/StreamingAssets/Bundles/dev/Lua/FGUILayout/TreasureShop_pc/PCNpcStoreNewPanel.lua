local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCNpcStoreNewPanel = class("PCNpcStoreNewPanel", BaseFGUILayout)

local IDX_NULL                                  = 0
local IDX_BUY                                   = 1     -- 购买
local IDX_SELL                                  = 2     -- 卖出
local IDX_RECYCLE                               = 3     -- 回收
local PACKAGE_NAME                              = "TreasureShop_pc"

function PCNpcStoreNewPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

    self._index = IDX_NULL
    self._pageDatas = {
        [IDX_BUY] = {
            objName                 = "PCBuyPanel",
            obj                     = nil,
            tabName                 = 30000002, --购买
        },
        [IDX_SELL] = {
            objName                 = "PCSellPanel",
            obj                     = nil,
            tabName                 = 30000055, --出售
        },
        [IDX_RECYCLE] = {
            objName                 = "PCRecyclePanel",
            obj                     = nil,
            tabName                 = 60003003,
        }
    }

    self._ViewData = {}
    self:GetAllFGuiData()
    self:InitOnClickEvent()
end

function PCNpcStoreNewPanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.list_tab = self._ui.list_tab
    self.node_root = self._ui.node_root
    self.text_title = self._ui.text_title
end

function PCNpcStoreNewPanel:TabItemRender(idx, item)
    local data = self._ViewData[idx + 1]
    if data then
        local btn_name = FGUI:GetChild(item,"btn_name")
        FGUI:GTextField_setText(btn_name,GET_STRING(data.tabName))
    end
end

function PCNpcStoreNewPanel:TabItemClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local idx = FGUI:GetChildIndex(self.list_tab,eventData.data)
    self:PageTo(idx + 1)
end

function PCNpcStoreNewPanel:PageClose()
    local pageData = self._ViewData[self._index]
    if not pageData then return true end
    local pageObj = pageData.obj
    if pageObj and pageObj.Exit then
        pageObj:Exit()
        FGUI:setVisible(pageObj.component,false)
    else
        SL:PrintEx("[ERROR] pageObj or pageObj.Exit 不存在 没有Exit方法")
    end
    self._index = IDX_NULL
    return true
end

function PCNpcStoreNewPanel:PageTo(index)
    if not index then return end
    if self._index  == index then return end
    self:PageClose()
    self:PageOpen(index)
    self:RefreshSelected(index)
end

function PCNpcStoreNewPanel:RefreshSelected(index)
    local count = FGUI:GetChildCount(self.list_tab)
    if count < index then
       return
    end

    for target = 0,count - 1 do
        local item = FGUI:GetChildAt(self.list_tab,target)
        if item then
            local _ctl_isSelected = FGUI:getController(item,"isSelected")
            _ctl_isSelected.selectedIndex = target == index - 1 and 0 or 1
        end
    end
end


function PCNpcStoreNewPanel:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._ViewData[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    if not pageObj then
        if not pageData.objName then
            return
        end
        
        pageObj = FGUI:CreateObject(self.node_root,PACKAGE_NAME,pageData.objName,true)
        pageData.obj = pageObj
    end
    
    FGUI:setVisible(pageObj.component,true)
    if pageObj.Enter then
        if self._index == IDX_BUY then
            pageObj:Enter(self.groupID)

        elseif self._index == IDX_SELL then
            pageObj:Enter(self.serverGroupID)
        elseif self._index == IDX_RECYCLE then
            pageObj:Enter()
        end
    else
        SL:PrintEx("[ERROR] 脚本["..pageData.objName.."]没有Enter方法")
    end
end


function PCNpcStoreNewPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCNpcStoreNewPanel:OnClose()
    self.super.Close(self)
end

function PCNpcStoreNewPanel:Destroy()
    if self._ViewData[IDX_BUY] and self._ViewData[IDX_BUY].obj then
        self._ViewData[IDX_BUY].obj:CleanItemCache()
    end
    
    if self._ViewData[IDX_SELL] and self._ViewData[IDX_SELL].obj then
        self._ViewData[IDX_SELL].obj:CleanItemCache()
    end

    if self._ViewData[IDX_RECYCLE] and self._ViewData[IDX_RECYCLE].obj then
        self._ViewData[IDX_RECYCLE].obj:CleanItemCache()
    end
end


function PCNpcStoreNewPanel:Refresh()
    FGUI:GList_itemRenderer(self.list_tab,handler(self,self.TabItemRender))
    FGUI:GList_addOnClickItemEvent(self.list_tab,handler(self,self.TabItemClicked))
    FGUI:GList_setNumItems(self.list_tab,table.nums(self._ViewData))
end

function PCNpcStoreNewPanel:Enter(data)
    if not data then
       return
    end

    print("data----------")
    SL:print_t(data)

    self._ViewData = {}
    if data.kind == 0 then
        self._ViewData[IDX_BUY] = self._pageDatas[IDX_BUY]
        self._ViewData[IDX_SELL] = self._pageDatas[IDX_SELL]
        if data.recycleIsShow == 1 then
            self._ViewData[IDX_RECYCLE] = self._pageDatas[IDX_RECYCLE]
        end
    elseif data.kind == 1 then
        self._ViewData[1] = self._pageDatas[IDX_BUY]
        if data.recycleIsShow == 1 then
            self._ViewData[2] = self._pageDatas[IDX_RECYCLE]
        end
    elseif data.kind == 2 then
        self._ViewData[1] = self._pageDatas[IDX_SELL]
        if data.recycleIsShow == 1 then
            self._ViewData[2] = self._pageDatas[IDX_RECYCLE]
        end
    end

    if data and data.groupID then
        self.groupID = data.groupID
    end

    if data and data.sellGroup then
        self.serverGroupID = data.sellGroup
    end

    if data and not string.isNullOrEmpty(data.shopName) then
        FGUI:GTextField_setText(self.text_title,data.shopName)
    else
        FGUI:GTextField_setText(self.text_title,GET_STRING(30000101))
    end

    self:Refresh()
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","NPCStoreMoneyList"))
    self:PageTo(1)
end

function PCNpcStoreNewPanel:Exit()
    FGUIFunction:HideTopCurrency()
    self:PageClose()
end

return PCNpcStoreNewPanel