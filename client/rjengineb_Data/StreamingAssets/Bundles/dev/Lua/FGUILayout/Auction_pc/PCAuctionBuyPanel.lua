local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCAuctionBuyPanel = class("PCAuctionBuyPanel", BaseFGUILayout)

-- cbx_allCamp
-- 0:所有阵营
-- 1:正
-- 2:邪
-- cbx_allGrade
-- -1:所有品质
-- 0:白
-- 1:绿
-- 2:蓝
-- 3:紫
-- 4:橙
-- 5:红
-- 0白,1绿,2蓝,3紫,4橙,5红
-- cbx_allLevel
-- 30-120 10档
-- 防止策划配置不均匀区间
local LEVEL_RANGE = {
    [1] = {context = "所有等级", min = 0,max = 0},
    [2] = {context = "0-30", min = 0,max = 30},
    [3] = {context = "31-40", min = 31,max = 40},
    [4] = {context = "41-50", min = 41,max = 50},
    [5] = {context = "51-60", min = 51,max = 60},
    [6] = {context = "61-70", min = 61,max = 70},
    [7] = {context = "71-80", min = 71,max = 80},
    [8] = {context = "81-90", min = 81,max = 90},
    [9] = {context = "91-100", min = 91,max = 100},
    [10] = {context = "101-110", min = 101,max = 110},
    [11] = {context = "111-120", min = 111,max = 120},
}

function PCAuctionBuyPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._scheduleID = nil
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitData()
    self:InitUI()
end

function PCAuctionBuyPanel:InitData()
    self._treeData = SL:GetValue("PAIMAI_TREE_FILTER_DATA")
    self._mainPageNames = self._treeData.mainPageNames
    self._groupSets = self._treeData.groupSets
    self._currentPageData = {}
    self._iconItemList = {}
    self._scheduleSet = {}
    self._nPage = self._groupSets[1]            -- _paiMaiConfig nPage 配置 树形结构左侧类
    self._camp = 0
    self._grade = -1
    self._levello = 0
    self._levelhi = 0
    self._minPage = 1
    self._maxPage = 1
    self._curPage = 1
end

function PCAuctionBuyPanel:CleanCache()
    for k,v in pairs(self._iconItemList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
    -- 清理定时器
    for k,v in pairs(self._scheduleSet) do
        if v then
            SL:UnSchedule(v)
        end
    end

    self._iconItemList = {}
end

function PCAuctionBuyPanel:GetAllFGuiData()
    self.list_PaiMai = self._ui.list_PaiMai
    self.tree_list = self._ui.tree_list
    self.cbx_allCamp = self._ui.cbx_allCamp
    self.cbx_allGrade = self._ui.cbx_allGrade
    self.cbx_allLevel = self._ui.cbx_allLevel
    self.btn_next = self._ui.btn_next
    self.btn_prev = self._ui.btn_prev
    self.btn_next_fast = self._ui.btn_next_fast
    self.btn_prev_fast = self._ui.btn_prev_fast
    self.text_currentPage = self._ui.text_currentPage
    self.input_search = self._ui.input_search
    self.ctrl_isShowPage = FGUI:getController(self.component,"isShowPage")
    self.ctrl_isSearchByKeyWord = FGUI:getController(self.component,"isSearchByKeyWord")
    self.btn_search = self._ui.btn_search
    self.btn_search_switch = self._ui.btn_search_switch

    self.loading = FGUI:GetTransition(self.component, "loading")
    self.ctrl_loading = FGUI:getController(self.component,"isShowloading")
end

function PCAuctionBuyPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_search,handler(self,self.BtnSearchClicked))
    FGUI:setOnClickEvent(self.btn_next,handler(self,self.BtnNextClicked))
    FGUI:setOnClickEvent(self.btn_prev,handler(self,self.BtnPrevClicked))
    FGUI:setOnClickEvent(self.btn_search_switch,handler(self,self.BtnSearchSwitch))
    FGUI:setOnClickEvent(self.btn_next_fast,handler(self,self.BtnNextFastClicked))
    FGUI:setOnClickEvent(self.btn_prev_fast,handler(self,self.BtnPrevFastClicked))
    FGUI:GComboBox_setOnChangeCallback(self.cbx_allCamp,handler(self,self.CBXAllCampChanged))
    FGUI:GComboBox_setOnChangeCallback(self.cbx_allGrade,handler(self,self.CBXAllGradeChanged))
    FGUI:GComboBox_setOnChangeCallback(self.cbx_allLevel,handler(self,self.CBXAllLevelChanged))
end

function PCAuctionBuyPanel:BtnSearchClicked()
    self.ctrl_isSearchByKeyWord.selectedIndex = 0
    self._curPage = 1
    self:RequestSearchPaiMai()
end

function PCAuctionBuyPanel:BtnSearchSwitch()
    self.ctrl_isSearchByKeyWord.selectedIndex = 1
    FGUI:GTextInput_setText(self.input_search,"")
    self._curPage = 1
    self:RequestPaiMaiPage()
end

-- 格式化页码
function PCAuctionBuyPanel:formatPageNums(num)
    if num < self._minPage then
       num = self._minPage
    end

    if num > self._maxPage then
        num = self._maxPage
    end

    return num
end

function PCAuctionBuyPanel:RefreshPageShow()
    self.ctrl_isShowPage.selectedIndex = self._maxPage >= 1 and 0 or 1
    FGUI:GTextField_setText(self.text_currentPage,self._curPage .."/" .. self._maxPage)
end

-- 品质选择发生变化
function PCAuctionBuyPanel:CBXAllGradeChanged()
    local curGrade = FGUI:GComboBox_getSelectedIndex(self.cbx_allGrade)
    self._grade = curGrade - 1
    print("self._grade ",self._grade )
    self:RequestPaiMaiPage()
end

-- 阵营过滤发生变化
function PCAuctionBuyPanel:CBXAllCampChanged()
    local allCamp = FGUI:GComboBox_getSelectedIndex(self.cbx_allCamp)
    self._camp = allCamp
    print("self._camp",self._camp)
    self:RequestPaiMaiPage()
end

-- 等级过滤器发生变化
function PCAuctionBuyPanel:CBXAllLevelChanged()
    local allLevel = FGUI:GComboBox_getSelectedIndex(self.cbx_allLevel)
    print("allLevel",allLevel)
    self._levello = LEVEL_RANGE[allLevel + 1].min
    self._levelhi = LEVEL_RANGE[allLevel + 1].max
    print("self._levello,self._levelhi",self._levello,self._levelhi)
    self:RequestPaiMaiPage()
end

function PCAuctionBuyPanel:InitUI()
    -- 初始化树形结构
    self.rootTreeNode = FGUI:GTree_getRootNode(self.tree_list)
    for _key,_value in ipairs(self._treeData.tree) do
        local isHasChild = type(_value) ~= "number"
        local parent = FGUI:GTreeNode_Create("ui://1e928y1xoxr7a",isHasChild)
        FGUI:GTreeNode_addChild(self.rootTreeNode,parent)
        local comp = FGUI:GTreeNode_getCell(parent)
        FGUI:addOnClickMultipleEvent(comp,function()
            self._nPage = self._groupSets[_key]
            print("self.nPage======父",self._nPage)
            self:RequestPaiMaiPage()
        end)  
        FGUI:getController(comp,"isHasChild").selectedIndex = isHasChild and 1 or 0
        local text_title = FGUI:GetChild(comp,"text_content")
        FGUI:GTextField_setText(text_title,self._mainPageNames[_key])
        FGUI:GTreeNode_setExpanded(parent,true)
        if _value and isHasChild then
            for _nPage,_value_ in pairs(_value) do
                local child = FGUI:GTreeNode_Create("ui://1e928y1xoxr78",false)
                FGUI:GTreeNode_addChild(parent,child)
                local compChild = FGUI:GTreeNode_getCell(child)
                local text_content = FGUI:GetChild(compChild,"text_content")
                FGUI:GTextField_setText(text_content,_value_)
                FGUI:addOnClickMultipleEvent(compChild,function()
                    self._nPage =  tostring(_nPage)
                    print("self.nPage======子",self._nPage)
                    self:RequestPaiMaiPage()
                end)
            end
        end
    end

    FGUI:GList_addOnClickItemEvent(self.list_PaiMai,handler(self,self.CellClicked))
    FGUI:GList_itemRenderer(self.list_PaiMai,handler(self,self.ListViewCellsItemRenderer))
    FGUI:GList_setVirtual(self.list_PaiMai)
    -- -- 输入框占位字
    -- FGUI:GTextInput_setPromptText(self.input_search,"请输入关键词搜索")
    -- 初始化品质过滤器
    local data = SL:GetValue("ITEM_ALL_GRADE_NAME")
    local colorStrs = {}
    for k,v in pairs(data) do
        colorStrs[k + 1] ="[color="..v.color.."]"..v.name.."[/color]"
    end
    colorStrs[1] = GET_STRING(30000075)
    FGUI:GComboBox_setItems(self.cbx_allGrade, colorStrs)
    FGUI:GComboBox_setVisibleItemCount(self.cbx_allGrade, table.count(data) + 1)
    -- 初始化等级过滤器
    local strs = {}
    for k,v in pairs(LEVEL_RANGE) do
        strs[k] = v.context
    end 
    FGUI:GComboBox_setItems(self.cbx_allLevel, strs)
end

function PCAuctionBuyPanel:CellClicked(context)
    print("CellClicked-----------")
end

function PCAuctionBuyPanel:ListViewCellsItemRenderer(idx,cell)
    local index = idx + 1
    local data = self._currentPageData[index]
    if data then
        local id = FGUI:GetID(cell)
        local text_name = FGUI:GetChild(cell,"text_name")
        local text_time = FGUI:GetChild(cell,"text_time")
        local text_price_jingJia = FGUI:GetChild(cell,"text_price_jingJia")
        local text_price_once = FGUI:GetChild(cell,"text_price_once")
        local itemRoot = FGUI:GetChild(cell,"itemRoot")
        local iconMoney1 = FGUI:GetChild(cell,"iconMoney1")
        local iconMoney2 = FGUI:GetChild(cell,"iconMoney2")
        local btn_jingjia = FGUI:GetChild(cell,"btn_jingjia")
        local btn_buy = FGUI:GetChild(cell,"btn_buy")
        local text_status = FGUI:GetChild(cell,"text_status")

        FGUI:GTextField_setText(text_price_jingJia,data.currprice ~= 0 and SL:GetThousandSepString(data.currprice) or SL:GetThousandSepString(data.price))
        FGUI:GTextField_setText(text_price_once,SL:GetThousandSepString(data.lastprice) or "")

        if self._iconItemList[id] then
            ItemUtil:ItemShow_Release(self._iconItemList[id])
        end

        if self._scheduleSet[id] then
            SL:UnSchedule(self._scheduleSet[id])
            self._scheduleSet[id] = nil
        end

        -- 倒计时
        local callBack = function()
            local curTime = SL:GetValue("SERVER_TIME")
            if data.endtime - curTime <= 0 then
                if self._scheduleSet[id] then
                    SL:UnSchedule(self._scheduleSet[id])
                    self._scheduleSet[id] = nil
                end
            else
                FGUI:GTextField_setText(text_time,SecondToHMS(math.ceil(data.endtime - curTime) ,true, false))
            end
        end
        self._scheduleSet[id] = SL:Schedule(callBack, 1)
        -- 当有竞拍者时下显示竞拍者名字
        if not string.isNullOrEmpty(data.currname) then
            FGUI:GTextField_setText(text_status,data.currname)
        end

        local itemData = SL:GetValue("ITEM_DATA",data.index)
        FGUI:GTextField_setText(text_name,itemData.Name)
        self._iconItemList[id] = ItemUtil:ItemShow_Create(data.useritem,itemRoot)
        local moneyData = SL:GetValue("ITEM_DATA",data.type)
        ItemUtil:RefreshItemUIByData(iconMoney1,moneyData)
        ItemUtil:RefreshItemUIByData(iconMoney2,moneyData)
        ItemUtil:SetItemCountVisible(iconMoney1,false)
        ItemUtil:SetItemCountVisible(iconMoney2,false)
        ItemUtil:SetItemGradeVisible(iconMoney1,false)
        ItemUtil:SetItemGradeVisible(iconMoney2,false)

        -- 竞价
        FGUI:setOnClickEvent(btn_jingjia,function()
            FGUI:Open("Auction","TipJingjiaPanel",data)
        end)

        -- 一口价
        FGUI:setOnClickEvent(btn_buy,function()
            FGUI:Open("Auction","TipOncePricePanel",data)
        end)
    end
end

function PCAuctionBuyPanel:Enter()
    self:RegisterEvent()
    SL:ComponentAttach(SLDefine.SUIComponentTable.AuctionBuy, self._ui.Node_attach)
    self.ctrl_isSearchByKeyWord.selectedIndex = 1
    self.ctrl_loading.selectedIndex = 1
    self:RequestPaiMaiPage()
end

function PCAuctionBuyPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.AuctionBuy)
    self:RemoveEvent()
end

function PCAuctionBuyPanel:BtnNextClicked()
    self._curPage = self:formatPageNums(self._curPage + 1 )
    self:RequestPaiMaiPage()
    self:RequestSearchPaiMai()
end

function PCAuctionBuyPanel:BtnPrevClicked()
    self._curPage = self:formatPageNums(self._curPage - 1 )
    self:RequestPaiMaiPage()
    self:RequestSearchPaiMai()
end

function PCAuctionBuyPanel:BtnPrevFastClicked()
    self._curPage = self._minPage
    self:RequestPaiMaiPage()
    self:RequestSearchPaiMai()
end

function PCAuctionBuyPanel:BtnNextFastClicked()
    self._curPage = self._maxPage
    self:RequestPaiMaiPage()
    self:RequestSearchPaiMai()
end

-- 刷新列表
function PCAuctionBuyPanel:RefreshPaiMaiList()
    FGUI:GList_setNumItems(self.list_PaiMai,table.count(self._currentPageData))
end

-- 刷新当前页的数据
function PCAuctionBuyPanel:RefreshData(curPage,totalPage)
    if curPage then
        self._minPage = curPage
    else
        self._minPage = 1
    end

    if totalPage and  totalPage >0 then
        self._maxPage = totalPage
    else
        self._maxPage = 1
    end

    self._currentPageData = SL:GetValue("PAIMAI_LATEST_RES_PAGE_DATA")
    print("服务器数据收到")
    SL:print_t(self._currentPageData)
    self:RefreshPageShow()
    self:RefreshPaiMaiList()
end

-- 请求数据
function PCAuctionBuyPanel:RequestPaiMaiPage()
    if self.ctrl_isSearchByKeyWord.selectedIndex == 1 then
        local data = {
            page = self._nPage,
            camp = self._camp,
            grade = self._grade,
            levello = self._levello,
            levelhi = self._levelhi,
        }
        
        SL:RequestAuctionPaiMaiPageInfo(data,self._curPage)
    end
end

function PCAuctionBuyPanel:RequestSearchPaiMai()
    if self.ctrl_isSearchByKeyWord.selectedIndex == 0 then
        local search = FGUI:GTextInput_getText(self.input_search)
        search  = string.trimLeft(search)
        search  = string.trimRight(search)
        if string.isNullOrEmpty(search) or 
            FGUI:GTextInput_getPromptText(self.input_search) == search then
            SL:ShowSystemTips(GET_STRING(30000093))
            return 
        end
            
        SL:RequestAuctionSearchPaiMai(self._curPage,search)
    end
end

function PCAuctionBuyPanel:BuyTips(recog)
    if not recog then
        return
    end
    if recog == -1 then
        SL:ShowSystemTips(GET_STRING(30000082)) 
    elseif recog == -2 then
        SL:ShowSystemTips(GET_STRING(30000083)) 
    elseif recog == -3 then
        SL:ShowSystemTips(GET_STRING(30000084)) 
    elseif recog == -4 then
        SL:ShowSystemTips(GET_STRING(30000085)) 
    elseif recog == -5 then
        SL:ShowSystemTips(GET_STRING(30000086)) 
    elseif recog == -6 then
        SL:ShowSystemTips(GET_STRING(30000087)) 
    elseif recog == -7 then
        SL:ShowSystemTips(GET_STRING(30000088))
    elseif recog == 1 then
        SL:ShowSystemTips(GET_STRING(30000089))
    elseif recog == 2 then
        SL:ShowSystemTips(GET_STRING(30000090))
    else
        SL:ShowSystemTips(GET_STRING(30000091) .. recog) 
    end   
end

function PCAuctionBuyPanel:PlayerLoadingActionByTime(time)
    self.ctrl_loading.selectedIndex = time > 0 and 0 or 1
    if self._scheduleID then
        SL:UnSchedule(self._scheduleID)
        self._scheduleID = nil
    end
    if time > 0 then
        if  FGUI:Transition_getIsPlaying(self.loading) then
            FGUI:Transition_setPaused(self.loading,true)
        end

        FGUI:Transition_play(self.loading,nil,-1)
        self._scheduleID = ScheduleOnce(function()
            self._scheduleID = nil
            FGUI:Transition_setPaused(self.loading,true)
            self.ctrl_loading.selectedIndex = 1
        end, time)
    else
        if FGUI:Transition_getIsPlaying(self.loading) then
            FGUI:Transition_setPaused(self.loading,true)
            self.ctrl_loading.selectedIndex = 1
        end
    end
end

function PCAuctionBuyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_PAGE_RES, "PCAuctionBuyPanel", handler(self,self.RefreshData))
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_PAGE_UPDATE, "PCAuctionBuyPanel", handler(self,self.RefreshData))
    SL:RegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "PCAuctionBuyPanel", handler(self,self.BuyTips))
    SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "PCAuctionBuyPanel", handler(self,self.BuyTips))
    SL:RegisterLUAEvent(LUA_EVENT_MY_AUCTION_LOADING_UPDATE, "PCAuctionBuyPanel", handler(self, self.PlayerLoadingActionByTime))
end

function PCAuctionBuyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_PAGE_RES, "PCAuctionBuyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_PAGE_UPDATE, "PCAuctionBuyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUCTION_BUY_RESULT, "PCAuctionBuyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "PCAuctionBuyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MY_AUCTION_LOADING_UPDATE, "PCAuctionBuyPanel")
end

return PCAuctionBuyPanel
