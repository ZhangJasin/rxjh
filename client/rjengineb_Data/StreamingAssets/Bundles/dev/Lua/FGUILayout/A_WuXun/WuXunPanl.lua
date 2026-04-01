local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local WuXunPanl = class("WuXunPanl", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local WuXunPanlData = SL:RequireFile("FGUILayout/A_WuXun/WuXunPanlData")

local attrConfigs = SL:GetValue("ATTR_CONFIGS") -- 属性配置(AttScore表)

local equipBGUrl = {                            -- 武勋装备背景url路径
    "ui://st7dgeqqdxatvob", -- 武器
    "ui://st7dgeqqmzzl1u",  -- 衣服
    "ui://st7dgeqqmzzl1p",  -- 护腕
    "ui://st7dgeqqmzzl1q",  -- 戒指
}
local wuxun_level_data         =  require("game_config/cfgcsv/wuxun_level_data")              -- 武勋等级数据
local wuxun_skill_data         =  require("game_config/cfgcsv/wuxun_skill_data")              -- 武勋技能数据
local wuxun_chuilian_data      =  require("game_config/cfgcsv/wuxun_chuilian_data")           -- 武勋装备锤炼数据
local wuxun_zhujie_data        =  require("game_config/cfgcsv/wuxun_zhujie_data")             -- 武勋装备铸阶数据

function WuXunPanl:Create()
    -- 初始化玩家职业
    local playjob = SL:GetValue("JOB")              -- 玩家职业 1弓手,2枪客,3刺客,4医生,5刀客,6剑客    
    self._ui = FGUI:ui_delegate(self.component)
    
    FGUI:SetCloseUIWhenClickOutside(self)
    
    FGUI:setOnClickEvent(self._ui.btn_close, function()     -- 关闭按钮
        FGUI:Close("A_WuXun", "WuXunPanl")
    end)
    FGUI:GList_addOnClickItemEvent(self._ui.List_Page, function(context)
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.List_Page)
        self.rightPage = selectedIndex+1
        self:ChangeRightPage()                                          -- 更新当前界面数据
    end)

    ---- 以下为tips界面
    self.tipsbg = FGUI:ui_delegate(self._ui.panl_tips)
    self.tipsControlle = FGUI:getController(self.component,"tips")
    self.tipinfoScro = FGUI:ui_delegate(self.tipsbg.infoScro)
    ---- 点击tips
    FGUI:setOnClickEvent(self._ui.btntips,function()  
        FGUI:GTextField_setText(self.tipsbg.title, wuxun_level_data[self.rightPage]['tipstitle'])                                     -- 打开按钮
        FGUI:GRichTextField_setText(self.tipinfoScro['n3'], wuxun_level_data[self.rightPage]['TIPS'])
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,1)
    end)
    FGUI:setOnClickEvent(self.tipsbg.closetips,function()                                   -- 关闭按钮
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
    end)
    FGUI:setOnClickEvent(self.tipsbg.bg,function()                                          -- 关闭按钮
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
    end)
    
end
function WuXunPanl:Enter(data)
    self:RegisterEvent()                                            -- 注册事件
    self:SubscribeDataEvents()                                      -- 订阅数据事件
    self.rightPage = tonumber(data.page) or 1                       -- 默认打开右侧第一页
    self.SelectEquipZJLevel = 0                                     -- 当前选中的铸阶等级
    
    -- 通过数据层获取数据
    WuXunPanlData:Get():RequestWuXunData()
    
    self:Init() 
    -- 数据将通过事件回调更新
end
function WuXunPanl:Refresh(data)                    -- 界面刷新时调用
    
end
function WuXunPanl:Exit()                           -- 界面关闭时调用
    self:RemoveEvent()                              -- 移除事件
end
function WuXunPanl:Destroy()                        -- 界面销毁时调用
    self:UnsubscribeDataEvents()  -- 取消数据事件订阅
end

function WuXunPanl:SubscribeDataEvents()
    -- 存储订阅令牌
    self._subTokens = {}
    
    -- 订阅数据更新事件
    table.insert(self._subTokens, WuXunPanlData:Get():Subscribe("wuxun_data_update", handler(self, self.OnWuXunDataUpdate)))
    table.insert(self._subTokens, WuXunPanlData:Get():Subscribe("daily_reward_update", handler(self, self.OnDailyRewardUpdate)))
    table.insert(self._subTokens, WuXunPanlData:Get():Subscribe("chuilian_data_update", handler(self, self.OnChuiLianDataUpdate)))
    table.insert(self._subTokens, WuXunPanlData:Get():Subscribe("zhujie_data_update", handler(self, self.OnZhuJieDataUpdate)))
    table.insert(self._subTokens, WuXunPanlData:Get():Subscribe("zhuanyin_data_update", handler(self, self.OnZhuanYinDataUpdate)))
end

function WuXunPanl:UnsubscribeDataEvents()
    -- 取消所有订阅
    if self._subTokens then
        for _, token in ipairs(self._subTokens) do
            WuXunPanlData:Get():Unsubscribe(token)
        end
        self._subTokens = nil
    end
end
-------------------------------↓↓↓ 本地方法 ↓↓↓---------------------------------------
function WuXunPanl:Init()                          -- 初始化
    -- 恭喜获得界面控制器
    self.gxhdControlle = FGUI:getController(self.component, "gxhd")
    -- 恭喜获得弹窗相关
    self.gxhdbg = FGUI:ui_delegate(self._ui.panl_gxhd)
    FGUI:setVisible(self.gxhdbg.closepanl, false)
    FGUI:setOnClickEvent(self.gxhdbg.bg, function()
        if WuXunPanl.dsqid then
            SL:UnSchedule(WuXunPanl.dsqid)
            WuXunPanl.dsqid = false
        end
        FGUI:Controller_setSelectedIndex(self.gxhdControlle,0)
    end)
    -- 恭喜获得奖励列表渲染
    FGUI:GList_itemRenderer(self.gxhdbg['n8'], handler(self, self.ListGXHDShow))
    FGUI:GList_setDefaultItem(self.gxhdbg['n8'], "ui://hed3v11ooqrpf")
    FGUI:GList_setVirtual(self.gxhdbg['n8'])
    

    -- 每日奖励领取界面控制器
    self.dayGiftControlle = FGUI:getController(self.component, "dayGift")
    -- 每日奖励领取弹窗相关
    self.dayGiftbg = FGUI:ui_delegate(self._ui.panl_dayGift)
    FGUI:setOnClickEvent(self.dayGiftbg.bg, function()
        FGUI:Controller_setSelectedIndex(self.dayGiftControlle,0)
    end)
    FGUI:setOnClickEvent(self.dayGiftbg.btn_close, function()
        FGUI:Controller_setSelectedIndex(self.dayGiftControlle,0)
    end)
    -- 每日奖励领取列表渲染
    FGUI:GList_itemRenderer(self.dayGiftbg.DayGiftList, handler(self, self.ListDayGiftShow))
    FGUI:GList_setDefaultItem(self.dayGiftbg.DayGiftList, "ui://hed3v11ooqrp1d")
    FGUI:GList_setVirtual(self.dayGiftbg.DayGiftList)
    FGUI:GList_setNumItems(self.dayGiftbg.DayGiftList,  #wuxun_level_data)
end
-- 切换功能界面
function WuXunPanl:ChangeRightPage()                -- 切换右侧页签
    if self.rightPage == 1 then
        self:WuXunShow()                                  -- 武勋界面
    elseif self.rightPage == 2 then
        self:WuXunChuiLian()                              -- 锤炼界面
    elseif self.rightPage == 3 then
        self:WuXunZhuJie()                                -- 铸阶界面
    elseif self.rightPage == 4 then
        self:WuXunZhuanYin()                              -- 转印界面
    end
end
function WuXunPanl:GetWuXunEquip()                        -- 获取装备数据
    local playjob = SL:GetValue("JOB")              -- 玩家职业 1弓手,2枪客,3刺客,4医生,5刀客,6剑客  
    -- 获取身上武勋装备              
    local equippos = wuxun_level_data[1]['WuXun_EquipPos'] or {}
    self.equipList = {}
    for j = 1, #equippos do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[j])
        if equipData then
            table.insert(self.equipList, equipData)
        end
    end
    local equipShow = wuxun_level_data[1]['WuXun_EquipShow'] or {}
    -- 获取武勋装备展示
    self.wxShowEquip = {}
    for i = 1,#equipShow do
        if equipShow[i][1] == playjob or equipShow[i][1] == 9 then
            table.insert(self.wxShowEquip, equipShow[i][2])
        end
    end
    -- 获取武勋装备属性 四件装备属性值和
    self.EquipBaseAttrTab = {}
    for i = 1,#self.equipList do
        local itemData = self.equipList[i]
        -- 获取基础属性
        local attData = FGUIFunction:GetAttShowData2(itemData.Attribute, nil, nil)
        for j = 1,#attData do
            local name = attData[j]['name']
            local attrid = tonumber(attData[j]['id'])
            local value = tonumber(attData[j]['value'])
            if self.EquipBaseAttrTab[name] then
                self.EquipBaseAttrTab[name][2] = self.EquipBaseAttrTab[name][2] + value
            else
                self.EquipBaseAttrTab[name] = {attrid,value}
            end
        end
        -- 获取锤炼属性
        -- 计算锤炼附加基础属性
        -- dump(itemData)
        local wxclLv = self.WuXun_ChuiLianList[""..itemData.Where] or 0
        if wxclLv > 0 then
            for i=1,#wuxun_chuilian_data[itemData.ID][wxclLv]['attrlist'] do
                local attr = wuxun_chuilian_data[itemData.ID][wxclLv]['attrlist'][i]
                local attrid,value = attr[1],attr[2]
                local name = attrConfigs[attrid]['Name']..""
                if self.EquipBaseAttrTab[name] then
                    self.EquipBaseAttrTab[name][2] = self.EquipBaseAttrTab[name][2] + value
                else
                    self.EquipBaseAttrTab[name] = {attrid,value}
                end
            end 
        end
        -- 获取铸阶属性
        -- 计算铸阶附加基础属性
        local zjLv = 0
        if itemData then
            for j = 1, #itemData.Values do
                if itemData.Values[j]['Id'] == 2 then  
                    zjLv = itemData.Values[j]['Value']
                end 
            end
        end
        if zjLv > 0 then
            for i=1,#wuxun_zhujie_data[itemData.ID][zjLv]['attrlist'] do
                local attr = wuxun_zhujie_data[itemData.ID][zjLv]['attrlist'][i]
                local attrid,value = attr[1],attr[2]
                local name = attrConfigs[attrid]['Name']..""
                if self.EquipBaseAttrTab[name] then
                    self.EquipBaseAttrTab[name][2] = self.EquipBaseAttrTab[name][2] + value
                else
                    self.EquipBaseAttrTab[name] = {attrid,value}
                end
            end 
        end
        -- 获取鉴定属性
        local itemConfig = itemData.ExAbil
        local attrstr = ""
        if itemConfig and itemConfig.abil[1] then
            local tab = itemConfig.abil[1]['v']
            if tab then
                local attId     = tab[1][2] or 0     -- 属性ID 绑定表
                local name = attrConfigs[attId]['Name']..""
	            local value     = tab[1][3] or 0  -- 属性值
                if self.EquipBaseAttrTab[name] then
                    self.EquipBaseAttrTab[name][2] = self.EquipBaseAttrTab[name][2] + value
                else
                    self.EquipBaseAttrTab[name] = {attId,value}
                end
            end
        end
        -- 获取转印属性
        local attrstr = ""
        if itemConfig and itemConfig.abil[2] then
            local tab = itemConfig.abil[2]['v']
            if tab then
                for i=1,#tab do
                    local attId     = tab[i][2] or 0     -- 属性ID 绑定表
                    local name = attrConfigs[attId]['Name']..""
	                local value     = tab[i][3] or 0  -- 属性值
                    if self.EquipBaseAttrTab[name] then
                        self.EquipBaseAttrTab[name][2] = self.EquipBaseAttrTab[name][2] + value
                    else
                        self.EquipBaseAttrTab[name] = {attId,value}
                    end
                end
            end
        end
    end
    self.EquipBaseAttrTab = GetNewTable(self.EquipBaseAttrTab) -- 转换为以id为下标的表
end

-------------------------------↓↓↓ 武勋界面 ↓↓↓---------------------------------------
function WuXunPanl:WuXunShow()
    self.back = FGUI:ui_delegate(self._ui.panl_wuxun)     -- 武勋界面  
    FGUI:setOnClickEvent(self.back.btn_wxshop, function()   -- 武勋商店按钮
        ssrMessage:sendmsgEx("wuxun", "OpenWuXunShop")
    end)
    FGUI:setOnClickEvent(self.back.btn_wxjl, function()     -- 武勋每日奖励按钮
        if self.WuXun_DailyState == 0 then                  -- 未领取 领取奖励
            WuXunPanlData:Get():GetDailyReward()
            self.GXHDItemList = wuxun_level_data[self.WuXun_Level]['rewardList']
            FGUI:GList_setNumItems(self.gxhdbg['n8'], #wuxun_level_data[self.WuXun_Level]['rewardList'])
            FGUI:GList_refreshVirtualList(self.gxhdbg['n8'])--刷新虚拟列表
        else                                                -- 已领取 打开奖励界面
            FGUI:Controller_setSelectedIndex(self.dayGiftControlle,1)
            FGUI:GList_scrollToView(self.dayGiftbg.DayGiftList, self.WuXun_Level-1, false, false)
        end
    end)
    -- 称号图片
    local curTitleImg = wuxun_level_data[self.WuXun_Level]['WuXun_Pic'][self.goodDevilID][1] and wuxun_level_data[self.WuXun_Level]['WuXun_Pic'][self.goodDevilID][1] or 0
    local nextTitleImg = wuxun_level_data[self.WuXun_Level]['WuXun_Pic'][self.goodDevilID][2] and wuxun_level_data[self.WuXun_Level]['WuXun_Pic'][self.goodDevilID][2] or 0
    FGUI:GLoader_setUrl(self.back.curTitle,"ui://A_WuXun/"..curTitleImg)
    FGUI:GLoader_setUrl(self.back.nextTitle,"ui://A_WuXun/"..nextTitleImg)
    -- -- 武勋等级显示
    -- local wxlvContro = FGUI:getController(self._ui.panl_wuxun, "wxlv")
    -- FGUI:Controller_setSelectedIndex(wxlvContro,self.WuXun_Level-1)
    -- -- 阵营显示
    -- local EVILContro = FGUI:getController(self._ui.panl_wuxun, "GOODEVILID")
    -- FGUI:Controller_setSelectedIndex(EVILContro,self.goodDevilID-1)
    -- 穿戴装备控制器
    self.WXequipContro = FGUI:getController(self._ui.panl_wuxun, "iswear")
    FGUI:Controller_setSelectedIndex(self.WXequipContro, #self.equipList > 0 and 1 or 0)
    -- 武勋经验进度条显示
    self.expPro = FGUI:ui_delegate(self.back.n33)     -- 武勋界面  
    local maxExp = wuxun_level_data[self.WuXun_Level] and wuxun_level_data[self.WuXun_Level]['WuXunExp'][2] or wuxun_level_data[1]['WuXunExp'][2]
    local minExp = wuxun_level_data[self.WuXun_Level] and wuxun_level_data[self.WuXun_Level]['WuXunExp'][1] or wuxun_level_data[1]['WuXunExp'][1]
    if self.WuXun_Level >= #wuxun_level_data then
        maxExp = minExp
    end
    FGUI:GProgressBar_setValue(self.back.n33, (self.WuXun_curExp - minExp)/(maxExp - minExp) * 100)
    -- 经验文字显示
    FGUI:GTextField_setText(self.expPro.n2, self.WuXun_curExp.."/"..maxExp)
    -- 武勋属性显示
    self.curattrlist = wuxun_level_data[self.WuXun_Level] and wuxun_level_data[self.WuXun_Level]['attrlist'] or {}
    self.nextattrlist = wuxun_level_data[self.WuXun_Level+1] and wuxun_level_data[self.WuXun_Level+1]['attrlist'] or wuxun_level_data[self.WuXun_Level]['attrlist']
    FGUI:GList_itemRenderer(self.back.attrlist,handler(self,self.ListAttrItemRenderer))     -- 右侧属性列表 
    FGUI:GList_setDefaultItem(self.back.attrlist,"ui://hed3v11ooqrpd")
	FGUI:GList_setVirtual(self.back.attrlist)
    FGUI:GList_setNumItems(self.back.attrlist,  #self.curattrlist >= #self.nextattrlist and #self.curattrlist or #self.nextattrlist)
    -- 武勋装备展示
    FGUI:GList_itemRenderer(self.back.equipShow,handler(self,self.ListWXEquipShowRenderer))  
    FGUI:GList_setDefaultItem(self.back.equipShow,"ui://hed3v11ooqrpf")
	FGUI:GList_setVirtual(self.back.equipShow)
    FGUI:GList_setNumItems(self.back.equipShow,  #self.wxShowEquip)
    -- 前往购买
    FGUI:setOnClickEvent(self.back.n47, function()  
        ssrMessage:sendmsgEx("wuxun", "OpenWuXunShop")
    end)
    -- 武勋装备属性
    FGUI:GList_itemRenderer(self.back.attrlist2,handler(self,self.ListWXEquipAttrRenderer))  
    FGUI:GList_setDefaultItem(self.back.attrlist2,"ui://hed3v11ooqrpm")
	FGUI:GList_setVirtual(self.back.attrlist2)
    FGUI:GList_setNumItems(self.back.attrlist2,  #self.EquipBaseAttrTab)
    -- 武勋装备左侧展示
    if self.equipMentSlots then
        self:ReleaseAllEquipItem()   
    end
    self.equipMentSlots = {}
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    for index = equippos[1],equippos[#equippos] do            -- 新加需改fgui  index最好对应装备位  方便修改
        self.equipMentSlots[index] = self.back["equip" .. index]
    end
    self.equipMentObjList = {}
    self:RefreshEquipByPos()                              -- 刷新装备   
    self:UpdateRoleModel()                                -- 更新中间模型数据 特效
end
-- 清除所有
function WuXunPanl:ReleaseAllEquipItem()        
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
    self.equipMentObjList = {}
end
-- 左侧武勋装备刷新
function WuXunPanl:UpdateWuXunEquip(equipData)
    -- dump(equipData)
    if not equipData then
        return
    end
    local pos = equipData.Where
    local parent = self.equipMentSlots[pos]
    if parent then
        self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent,
        {
            itemTipData = {from = ItemFrom.PALYER_EQUIP},
            OverLap = equipData.OverLap,
            doubleClickCallback = function()
            SL:TakeOffPlayerEquip(equipData)
            end
            })
        -- 刷新右侧列表 左侧装备展示
    end
    
end

function WuXunPanl:ListAttrItemRenderer(idx,item)         -- 武勋等级属性右侧列表
    if self.curattrlist[idx+1] or self.nextattrlist[idx+1] then
        local name = attrConfigs[self.nextattrlist[idx+1][1]]['Name']..""
        local type = attrConfigs[self.nextattrlist[idx+1][1]]['Type'] or 0 -- 0 数值 1 万分比
        local curFont = self.curattrlist[idx+1] and self.curattrlist[idx+1][2] or 0
        local nextFont = self.nextattrlist[idx+1] and self.nextattrlist[idx+1][2] or 0
        if type == 1 then
            curFont = string.format("%.0f", curFont / 100) .. "%"
            nextFont = string.format("%.0f", nextFont / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n1 = FGUI:GetChild(item,"n1")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n1, nextFont)
        FGUI:GTextField_setText(n4, curFont)
    end
end
function WuXunPanl:ListWXEquipShowRenderer(idx,item)      -- 武勋装备展示
    if self.wxShowEquip[idx+1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        local itemData = SL:GetValue("ITEM_DATA", self.wxShowEquip[idx+1])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true
        }
        local itemobj = ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
        if itemobj.hideArrow then -- 隐藏箭头
            itemobj:hideArrow()
        end
    end
end

function WuXunPanl:ListWXEquipAttrRenderer(idx,item)      -- 武勋装备属性右侧列表
    if self.EquipBaseAttrTab[idx+1]  then
        local attrid = self.EquipBaseAttrTab[idx+1][1]
        local name = self.EquipBaseAttrTab[idx+1][3]..""
        local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
        local value = self.EquipBaseAttrTab[idx+1][2]
        if type == 1 then
            value = string.format("%.0f", value / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n4, value)
    end
end

-------------------------------↓↓↓ 武勋锤炼 ↓↓↓---------------------------------------
function WuXunPanl:WuXunChuiLian()
    self.back = FGUI:ui_delegate(self._ui.panl_chuilian)     -- 武勋界面  
    -- self.WuXun_ChuiLianList
    -- 锤炼
    FGUI:setOnClickEvent(self.back.btn_chuilian, function()  
        WuXunPanlData:Get():WuXunEquipChuilian({self.SelectCLEquipMakeindex})
    end)

    -- 武勋锤炼属性展示 未满级展示
    FGUI:GList_itemRenderer(self.back.attrlist,handler(self,self.ListWXCLAttr1Renderer))  
    FGUI:GList_setDefaultItem(self.back.attrlist,"ui://hed3v11ooqrpd")
	FGUI:GList_setVirtual(self.back.attrlist)
    FGUI:GList_setNumItems(self.back.attrlist,  #wuxun_chuilian_data[400001][1]['attrlist'])
    -- 武勋锤炼属性展示 满级展示
    FGUI:GList_itemRenderer(self.back.attrlist2,handler(self,self.ListWXCLAttr2Renderer))  
    FGUI:GList_setDefaultItem(self.back.attrlist2,"ui://hed3v11ooqrpx")
	FGUI:GList_setVirtual(self.back.attrlist2)
    FGUI:GList_setNumItems(self.back.attrlist2,  #wuxun_chuilian_data[400001][1]['attrlist'])

    
    -- 武勋装备参数
    self.SelectCLEquipItemID = 0            -- 选中装备id
    self.SelectCLEquipMakeindex = 0         -- 选中装备makeindex
    self.SelectCLEquipEquipData = 0         -- 选中装备数据
    self.SelectCLEquipIndex = 1             -- 选中装备索引
    self.SelectCLattData = 0                -- 选中装备属性数据 
    -- 武勋装备展示  左侧列表
    FGUI:GList_itemRenderer(self.back.equipList,handler(self,self.ListWXCLEquipRenderer))  
    FGUI:GList_setDefaultItem(self.back.equipList,"ui://hed3v11ooqrps")
	FGUI:GList_setVirtual(self.back.equipList)
    FGUI:GList_setNumItems(self.back.equipList,  #wuxun_level_data[1]['WuXun_EquipPos'])
    FGUI:GList_addOnClickItemEvent(self.back.equipList, function(context)
        local index=FGUI:GetIntData(context.data)
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][index])
        -- 重新赋值
        self.SelectCLEquipIndex = index
        self.SelectCLEquipItemID = equipData and equipData.ID or 0
        self.SelectCLEquipMakeindex = equipData and equipData.MakeIndex  or 0
        self.SelectCLEquipEquipData = equipData and equipData  or 0
        self.SelectCLattData = 0
        local zjLv = 0
        if equipData then
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then  
                    zjLv = equipData.Values[j]['Value']
                end 
            end
            -- dump(equipData)
            self.SelectCLattData = FGUIFunction:GetAttShowData2(equipData.Attribute, nil, nil) -- 选中装备的数据基础属性数据
        end 
        self.SelectEquipZJLevel = zjLv
        self:UpdateWXChuiLian()
    end)

    -- 锤炼满级控制器
    self.wxclmjContro = FGUI:getController(self._ui.panl_chuilian,"ismj")


    local obj = FGUI:GetChildAt(self.back.equipList,0)
    FGUI:GButton_FireClick(obj, true, true)                 -- 默认点击列表第一个 
    

end
function WuXunPanl:ListWXCLEquipRenderer(idx,item)      -- 武勋装备展示
    FGUI:SetIntData(item,idx+1)
    if wuxun_level_data[1]['WuXun_EquipPos'][idx+1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][idx+1])
        local extData = {
            hideTip = false,
            itemTipData = equipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        -- dump(equipData)
        if self.SelectCLEquipIndex == idx+1 then
            self.SelectCLEquipEquipData = equipData and equipData or 0
        end
        local itemname = "未穿戴"
        if equipData then
            local itemobj = ItemUtil:ItemShow_Create(equipData, itemRoot, extData)
            if itemobj.hideArrow then -- 隐藏箭头
                itemobj:hideArrow()
            end
            itemname = SL:GetValue("ITEM_NAME", equipData.ID)
        else
            FGUI:RemoveChildren(itemRoot, 0, -1)
            local icon = FGUI:GetChild(item, "n4")
            FGUI:GLoader_setUrl(icon,equipBGUrl[idx+1] or equipBGUrl[1])
        end
        local name = FGUI:GetChild(item, "name")
        FGUI:GTextField_setText(name, "" .. itemname)
        FGUI:GTextField_setColor(name, "#FFFFFF")
        local att = FGUI:GetChild(item, "att")
        local Rtitle = FGUI:GetChild(att, "Rtitle")
        FGUI:GRichTextField_setColor(Rtitle, "#30ff00")
        local curjs = self.WuXun_ChuiLianList[""..wuxun_level_data[1]['WuXun_EquipPos'][idx+1]] or 0
        FGUIFunction:ScrollText_setString(att,"锤炼等级 +"..curjs.."", 3.5, 0)

    end
end

-- 武勋锤炼界面更新
function WuXunPanl:UpdateWXChuiLian()
    self.wxclLv = self.WuXun_ChuiLianList[""..wuxun_level_data[1]['WuXun_EquipPos'][self.SelectCLEquipIndex]] or 0
    local maxlv = wuxun_chuilian_data[self.SelectCLEquipItemID] and #wuxun_chuilian_data[self.SelectCLEquipItemID] or 0
    self.nextwxclLv = (self.wxclLv + 1) > maxlv and maxlv or (self.wxclLv + 1)
    local wxclISManJi = self.wxclLv >= self.nextwxclLv
    local sxnum = wuxun_chuilian_data[self.SelectCLEquipItemID] and #wuxun_chuilian_data[self.SelectCLEquipItemID] or 0
    -- 武勋锤炼属性展示 未满级展示
    FGUI:GList_setNumItems(self.back.attrlist, self.SelectCLEquipItemID == 0 and 0 or
          (#wuxun_chuilian_data[self.SelectCLEquipItemID] and #wuxun_chuilian_data[self.SelectCLEquipItemID][1]['attrlist'] or #wuxun_chuilian_data[400001][1]['attrlist']))
    -- 武勋锤炼属性展示 满级展示
    FGUI:GList_setNumItems(self.back.attrlist2,self.SelectCLEquipItemID == 0 and 0 or
          (#wuxun_chuilian_data[self.SelectCLEquipItemID] and #wuxun_chuilian_data[self.SelectCLEquipItemID][1]['attrlist'] or #wuxun_chuilian_data[400001][1]['attrlist']))

    local itemname = ""
    if self.SelectCLEquipEquipData ~= 0 then
        itemname = SL:GetValue("ITEM_NAME", self.SelectCLEquipEquipData.ID)
    end
    FGUI:GTextField_setText(self.back.curLv, "锤炼等级 "..self.wxclLv.."")
    -- 选择装备
    -- FGUI:RemoveFromParent(self.back.xzequip, true)
    FGUI:setVisible(self.back.xzequip, self.SelectCLEquipEquipData ~= 0)
    if self.SelectCLEquipEquipData ~= 0 then
        local itemRoot = FGUI:GetChild(self.back.xzequip, "itemRoot")
        local extData = {
            hideTip = false,
            itemTipData = self.SelectCLEquipEquipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(self.SelectCLEquipEquipData, itemRoot, extData)
    end
    -- 是否佩戴装备
    local isWear = self.SelectCLEquipEquipData ~= 0
    FGUI:setVisible(self.back.wpdfont, not (self.SelectCLEquipEquipData ~= 0))
    FGUI:setVisible(self.back.item1, self.SelectCLEquipEquipData ~= 0)
    FGUI:setVisible(self.back.btn_chuilian, self.SelectCLEquipEquipData ~= 0)
    FGUI:setVisible(self.back.n53, self.SelectCLEquipEquipData ~= 0)
    FGUI:setVisible(self.back.curLv, self.SelectCLEquipEquipData ~= 0)
    
    -- 锤炼满级控制器
    FGUI:Controller_setSelectedIndex(self.wxclmjContro,(wxclISManJi and isWear) and 1 or 0)

    -- 消耗材料
    local itemid = wuxun_chuilian_data[self.SelectCLEquipItemID] and wuxun_chuilian_data[self.SelectCLEquipItemID][self.nextwxclLv]['xhitemlist'][1] or 0
    local neednum = wuxun_chuilian_data[self.SelectCLEquipItemID] and wuxun_chuilian_data[self.SelectCLEquipItemID][self.nextwxclLv]['xhitemlist'][2] or 0
    if itemid > 0 then
        local itemRoot = FGUI:GetChild(self.back.item1, "itemRoot")
        local itemData = SL:GetValue("ITEM_DATA", itemid)
        local itemnum = SL:GetValue("ITEMCOUNT", itemid)
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
        local num = FGUI:GetChild(self.back.item1, "num")
        FGUI:GTextField_setText(num, itemnum.."/" .. neednum)
        FGUI:GTextField_setColor(num, itemnum >= neednum and "#00FF00" or "#FF0000")
    end

end

-- 武勋锤炼属性展示 未满级展示
function WuXunPanl:ListWXCLAttr1Renderer(idx,item)
    if wuxun_chuilian_data[self.SelectCLEquipItemID] and wuxun_chuilian_data[self.SelectCLEquipItemID][1]['attrlist'][idx+1] then
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][self.SelectCLEquipIndex])
        local attData = FGUIFunction:GetAttShowData2(self.SelectCLattData.Attribute, nil, nil)
        local name = self.SelectCLattData[idx+1]['name']
        local attrid = tonumber(self.SelectCLattData[idx+1]['id'])
        local value = tonumber(self.SelectCLattData[idx+1]['value'])
        local nextValur = value
        for i=1,#wuxun_chuilian_data[self.SelectCLEquipItemID][self.nextwxclLv]['attrlist'] do
            local attr = wuxun_chuilian_data[self.SelectCLEquipItemID][self.nextwxclLv]['attrlist'][i]
            if attr[1] == attrid then
                nextValur = value + attr[2]
            end
        end
        -- 计算锤炼附加基础属性
        if self.wxclLv > 0 then
            for i=1,#wuxun_chuilian_data[self.SelectCLEquipItemID][self.wxclLv]['attrlist'] do
                local attr = wuxun_chuilian_data[self.SelectCLEquipItemID][self.wxclLv]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        -- 计算铸阶附加基础属性
        if self.SelectEquipZJLevel > 0 then
            for i=1,#wuxun_zhujie_data[self.SelectCLEquipItemID][self.SelectEquipZJLevel]['attrlist'] do
                local attr = wuxun_zhujie_data[self.SelectCLEquipItemID][self.SelectEquipZJLevel]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                    nextValur = nextValur + attr[2]
                end
            end 
        end
        local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.0f", value / 100) .. "%"
            nextValur = string.format("%.0f", nextValur / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n1 = FGUI:GetChild(item,"n1")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n4, value)
        FGUI:GTextField_setText(n1, nextValur)
    end
end
-- 武勋锤炼属性展示 满级展示
function WuXunPanl:ListWXCLAttr2Renderer(idx,item)
    if wuxun_chuilian_data[self.SelectCLEquipItemID] and wuxun_chuilian_data[self.SelectCLEquipItemID][1]['attrlist'][idx+1] then
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][self.SelectCLEquipIndex])
        local attData = FGUIFunction:GetAttShowData2(self.SelectCLattData.Attribute, nil, nil)
        local name = self.SelectCLattData[idx+1]['name']
        local attrid = tonumber(self.SelectCLattData[idx+1]['id'])
        local value = tonumber(self.SelectCLattData[idx+1]['value'])
        -- 计算锤炼附加基础属性
        if self.wxclLv > 0 then
            for i=1,#wuxun_chuilian_data[self.SelectCLEquipItemID][self.wxclLv]['attrlist'] do
                local attr = wuxun_chuilian_data[self.SelectCLEquipItemID][self.wxclLv]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        -- 计算铸阶附加基础属性
        if self.SelectEquipZJLevel > 0 then
            for i=1,#wuxun_zhujie_data[self.SelectCLEquipItemID][self.SelectEquipZJLevel]['attrlist'] do
                local attr = wuxun_zhujie_data[self.SelectCLEquipItemID][self.SelectEquipZJLevel]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.0f", value / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n4, value)
    end
end

-------------------------------↓↓↓ 武勋铸阶 ↓↓↓---------------------------------------
-- 武勋铸阶界面
function WuXunPanl:WuXunZhuJie()
    self.back = FGUI:ui_delegate(self._ui.panl_zhujie)     -- 武勋界面  
    -- 铸阶
    FGUI:setOnClickEvent(self.back.btn_zhujie, function()  
        ssrMessage:sendmsgEx("wuxun", "WuXunEquipZhujie",{self.SelectZJEquipMakeindex})
    end)
    -- 获取武勋装备铸阶等级
    self:GetWuXunEquipLevel()

    -- 武勋铸阶属性展示 当前
    FGUI:GList_itemRenderer(self.back.attrlist1,handler(self,self.ListWXZJAttr1Renderer))  
    FGUI:GList_setDefaultItem(self.back.attrlist1,"ui://hed3v11ooqrpx")
	FGUI:GList_setVirtual(self.back.attrlist1)
    FGUI:GList_setNumItems(self.back.attrlist1,  #wuxun_zhujie_data[400001][1]['attrlist'])
    -- 武勋铸阶属性展示 下一级
    FGUI:GList_itemRenderer(self.back.attrlist2,handler(self,self.ListWXZJAttr2Renderer))  
    FGUI:GList_setDefaultItem(self.back.attrlist2,"ui://hed3v11ooqrpx")
	FGUI:GList_setVirtual(self.back.attrlist2)
    FGUI:GList_setNumItems(self.back.attrlist2,  #wuxun_zhujie_data[400001][1]['attrlist'])

    
    -- 武勋装备参数
    self.SelectZJEquipItemID = 0                -- 选择铸阶装备id
    self.SelectZJEquipMakeindex = 0             -- 选择铸阶装备唯一ID
    self.SelectZJEquipEquipData = 0             -- 选择铸阶装备数据
    self.SelectZJEquipIndex = 1                 -- 选择铸阶装备索引
    self.SelectZJattData = 0                    -- 选择铸阶基础装备属性数据
    self.SelectZJSkillIndex = 1                 -- 选择铸阶装备技能索引
    -- 武勋装备展示  左侧列表
    FGUI:GList_itemRenderer(self.back.equipList,handler(self,self.ListWXZJEquipRenderer))  
    FGUI:GList_setDefaultItem(self.back.equipList,"ui://hed3v11ooqrps")
	FGUI:GList_setVirtual(self.back.equipList)
    FGUI:GList_setNumItems(self.back.equipList,  #wuxun_level_data[1]['WuXun_EquipPos'])
    FGUI:GList_addOnClickItemEvent(self.back.equipList, function(context)
        local index=FGUI:GetIntData(context.data)
        self:GetWuXunEquipLevel()
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][index])
        -- 重新赋值
        self.SelectZJEquipIndex = index
        self.SelectZJEquipItemID = equipData and equipData.ID or 0
        self.SelectZJEquipMakeindex = equipData and equipData.MakeIndex  or 0
        self.SelectZJEquipEquipData = equipData and equipData  or 0
        self.SelectZJattData = 0
        if equipData then
            self.SelectZJattData = FGUIFunction:GetAttShowData2(equipData.Attribute, nil, nil) -- 选中装备的数据基础属性数据
            local zjLv = 0
            if equipData then
                for j = 1, #equipData.Values do
                    if equipData.Values[j]['Id'] == 2 then  
                        zjLv = equipData.Values[j]['Value']
                        break
                    end 
                end
            end
            self.SelectEquipZJLevel = zjLv
        end 
        self:UpdateWXZhuJie()
    end)

    -- 铸阶满级控制器
    self.wxzjmjContro = FGUI:getController(self._ui.panl_zhujie,"ismj")
    -- 铸阶是否选中穿戴装备控制器
    self.wxzjiswearContro = FGUI:getController(self._ui.panl_zhujie,"iswear")
    -- 铸阶技能描述控制器
    self.wxzjskilltipsContro = FGUI:getController(self._ui.panl_zhujie,"skilltips")
    self.Panl_skilltips = FGUI:ui_delegate(self.back.panl_skilltips)   
    FGUI:setOnClickEvent(self.Panl_skilltips.bg, function()                    
        FGUI:Controller_setSelectedIndex(self.wxzjskilltipsContro,0)
    end)
    FGUI:setPositionX(self.Panl_skilltips.Group_item, 632)
    FGUI:setPositionY(self.Panl_skilltips.Group_item, 253)
    
    -- 有装备时选中第一个装备
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    for i = 1, #equippos do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[i])
        if equipData then
            local obj = FGUI:GetChildAt(self.back.equipList,i-1)
            FGUI:GButton_FireClick(obj, true, true)
            break
        end
    end

    
end
-- 获取武勋装备铸阶等级
function WuXunPanl:GetWuXunEquipLevel()
    self.WuXunZhuJieTab = {}
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    for i = 1, #equippos do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[i])
        if equipData then
            local zjLv = 0
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then  
                    zjLv = equipData.Values[j]['Value']
                    self.WuXunZhuJieTab[zjLv] = (self.WuXunZhuJieTab[zjLv] or 0) + 1
                end 
            end
        end
    end
end
function WuXunPanl:ListWXZJEquipRenderer(idx,item)      -- 武勋装备展示
    FGUI:SetIntData(item,idx+1)
    if wuxun_level_data[1]['WuXun_EquipPos'][idx+1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][idx+1])
        local extData = {
            hideTip = false,
            itemTipData = equipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        -- dump(equipData)
        local zjLv = 0
        if equipData then
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then  
                    zjLv = equipData.Values[j]['Value']
                end 
            end
        end
        if self.SelectZJEquipIndex == idx+1 then
            self.SelectZJEquipEquipData = equipData and equipData or 0
            self.SelectEquipZJLevel = zjLv
        end
        local itemname = "未穿戴"
        if equipData then
            local itemobj = ItemUtil:ItemShow_Create(equipData, itemRoot, extData)
            if itemobj.hideArrow then -- 隐藏箭头
                itemobj:hideArrow()
            end
            itemname = SL:GetValue("ITEM_NAME", equipData.ID)
            itemname = zjLv.."阶"..itemname
        else
            FGUI:RemoveChildren(itemRoot, 0, -1)
            local icon = FGUI:GetChild(item, "n4")
            FGUI:GLoader_setUrl(icon,equipBGUrl[idx+1] or equipBGUrl[1])
        end
        local name = FGUI:GetChild(item, "name")
        FGUI:GTextField_setText(name, "" .. itemname)
        FGUI:GTextField_setColor(name, "#FFFFFF")
        local att = FGUI:GetChild(item, "att")
        local Rtitle = FGUI:GetChild(att, "Rtitle")
        FGUI:GRichTextField_setColor(Rtitle, "#30ff00")
        FGUIFunction:ScrollText_setString(att,"铸阶等级 "..zjLv.."阶", 3.5, 0)
    end
end
-- 武勋铸阶属性展示 当前等级
function WuXunPanl:ListWXZJAttr1Renderer(idx,item)
    if wuxun_zhujie_data[self.SelectZJEquipItemID] and wuxun_zhujie_data[self.SelectZJEquipItemID][1]['attrlist'][idx+1] then
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][self.SelectZJEquipIndex])
        local attData = FGUIFunction:GetAttShowData2(self.SelectZJattData.Attribute, nil, nil) -- 选中装备的数据基础属性数据
        local name = self.SelectZJattData[idx+1]['name']
        local attrid = tonumber(self.SelectZJattData[idx+1]['id'])
        local value = tonumber(self.SelectZJattData[idx+1]['value'])
        -- 计算锤炼附加基础属性
        if self.wxclLv > 0 then
            for i=1,#wuxun_chuilian_data[self.SelectZJEquipItemID][self.wxclLv]['attrlist'] do
                local attr = wuxun_chuilian_data[self.SelectZJEquipItemID][self.wxclLv]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        -- 计算铸阶附加基础属性
        if self.SelectEquipZJLevel > 0 then
            for i=1,#wuxun_zhujie_data[self.SelectZJEquipItemID][self.SelectEquipZJLevel]['attrlist'] do
                local attr = wuxun_zhujie_data[self.SelectZJEquipItemID][self.SelectEquipZJLevel]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.0f", value / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n4, value)
    end
end
-- 武勋铸阶属性展示 下一级
function WuXunPanl:ListWXZJAttr2Renderer(idx,item)
    if wuxun_zhujie_data[self.SelectZJEquipItemID] and wuxun_zhujie_data[self.SelectZJEquipItemID][1]['attrlist'][idx+1] then
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][self.SelectZJEquipIndex])
        local attData = FGUIFunction:GetAttShowData2(self.SelectZJattData.Attribute, nil, nil) -- 选中装备的数据基础属性数据
        local name = self.SelectZJattData[idx+1]['name']
        local attrid = tonumber(self.SelectZJattData[idx+1]['id'])
        local value = tonumber(self.SelectZJattData[idx+1]['value'])
        -- 计算锤炼附加基础属性
        if self.wxclLv > 0 then
            for i=1,#wuxun_chuilian_data[self.SelectZJEquipItemID][self.wxclLv]['attrlist'] do
                local attr = wuxun_chuilian_data[self.SelectZJEquipItemID][self.wxclLv]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        -- 计算铸阶附加基础属性
        local nextlv = (self.SelectEquipZJLevel + 1) > #wuxun_zhujie_data[self.SelectZJEquipItemID] and #wuxun_zhujie_data[self.SelectZJEquipItemID] or (self.SelectEquipZJLevel + 1)
        if wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv] then
            for i=1,#wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv]['attrlist'] do
                local attr = wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv]['attrlist'][i]
                if attr[1] == attrid then
                    value = value + attr[2]
                end
            end 
        end
        local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.0f", value / 100) .. "%"
        end
        local n0 = FGUI:GetChild(item,"n0")
        local n4 = FGUI:GetChild(item,"n4")
        FGUI:GTextField_setText(n0, name)
        FGUI:GTextField_setText(n4, value)
    end
end
-- 武勋铸阶更新
function WuXunPanl:UpdateWXZhuJie()
    self.wxclLv = self.WuXun_ChuiLianList[""..wuxun_level_data[1]['WuXun_EquipPos'][self.SelectZJEquipIndex]] or 0
    local maxlv = wuxun_zhujie_data[self.SelectZJEquipItemID] and #wuxun_zhujie_data[self.SelectZJEquipItemID] or 0
    local wxzjISManJi = self.SelectEquipZJLevel >= maxlv
    local nextlv = (self.SelectEquipZJLevel + 1) > maxlv and maxlv or (self.SelectEquipZJLevel + 1)
    -- print("武勋铸阶更新",self.wxclLv,self.SelectEquipZJLevel,nextlv)
    local sxnum = wuxun_zhujie_data[self.SelectZJEquipItemID] and #wuxun_zhujie_data[self.SelectZJEquipItemID] or 0
    -- 武勋铸阶属性展示 未满级展示
    FGUI:GList_setNumItems(self.back.attrlist1, self.SelectZJEquipItemID == 0 and 0 or
          (#wuxun_zhujie_data[self.SelectZJEquipItemID] and #wuxun_zhujie_data[self.SelectZJEquipItemID][1]['attrlist'] or #wuxun_zhujie_data[400001][1]['attrlist']))
    -- 武勋铸阶属性展示 满级展示
    FGUI:GList_setNumItems(self.back.attrlist2,self.SelectZJEquipItemID == 0 and 0 or
          (#wuxun_zhujie_data[self.SelectZJEquipItemID] and #wuxun_zhujie_data[self.SelectZJEquipItemID][1]['attrlist'] or #wuxun_zhujie_data[400001][1]['attrlist']))

    -- 选择装备
    FGUI:setVisible(self.back.xzequip, self.SelectZJEquipEquipData ~= 0)
    if self.SelectZJEquipEquipData ~= 0 then
        local itemRoot = FGUI:GetChild(self.back.xzequip, "itemRoot")
        local extData = {
            hideTip = false,
            itemTipData = self.SelectZJEquipEquipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(self.SelectZJEquipEquipData, itemRoot, extData)
        local itemname = SL:GetValue("ITEM_NAME", self.SelectZJEquipEquipData.ID)
        FGUI:GTextField_setText(self.back.curequipname, self.SelectEquipZJLevel.."阶"..itemname)
        FGUI:GTextField_setText(self.back.nextequipname, nextlv.."阶"..itemname)
    end
    -- 是否佩戴装备
    local isWear = self.SelectZJEquipEquipData ~= 0
    FGUI:setVisible(self.back.wpdfont, not (self.SelectZJEquipEquipData ~= 0))
    FGUI:setVisible(self.back.item1, self.SelectZJEquipEquipData ~= 0)
    FGUI:setVisible(self.back.btn_zhujie, self.SelectZJEquipEquipData ~= 0)
    
    -- 铸阶穿戴装备控制器
    FGUI:Controller_setSelectedIndex(self.wxzjiswearContro,isWear and 1 or 0)
    -- 铸阶满级控制器
    FGUI:Controller_setSelectedIndex(self.wxzjmjContro,(wxzjISManJi and isWear) and 1 or 0)

    -- 消耗材料
    local itemid = wuxun_zhujie_data[self.SelectZJEquipItemID] and wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv]['xhitemlist'][1] or 0
    local neednum = wuxun_zhujie_data[self.SelectZJEquipItemID] and wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv]['xhitemlist'][2] or 0
    if itemid > 0 then
        local itemRoot = FGUI:GetChild(self.back.item1, "itemRoot")
        local itemData = SL:GetValue("ITEM_DATA", itemid)
        local itemnum = SL:GetValue("ITEMCOUNT", itemid)
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
        local num = FGUI:GetChild(self.back.item1, "num")
        FGUI:GTextField_setText(num, itemnum.."/" .. neednum)
        FGUI:GTextField_setColor(num, itemnum >= neednum and "#00FF00" or "#FF0000")
    end
    FGUI:GTextField_setText(self.back.mjfont, "已达最大铸阶等级")
    -- 已达当前武勋等级最大可提升等级
    local needWXLv = wuxun_zhujie_data[self.SelectZJEquipItemID] and wuxun_zhujie_data[self.SelectZJEquipItemID][nextlv]['needWXLevel'] or 0
    -- print("已达当前武勋等级最大可提升等级",self.SelectEquipZJLevel,self.WuXun_Level,needWXLv)
    if self.WuXun_Level < needWXLv then
        FGUI:Controller_setSelectedIndex(self.wxzjmjContro,1)
        FGUI:GTextField_setText(self.back.mjfont, "需达到武勋等级【"..wuxun_level_data[needWXLv]['WuXunName'][self.goodDevilID].."】")
    end
    -- 当前武勋技能
    for i=1,#wuxun_skill_data do
        -- 武勋技能图标
        local icon = FGUI:GetChild(self.back['curskill'..i], "Image_icon")
        local skillicon = wuxun_skill_data[i] and wuxun_skill_data[i]['SkillIcon'] or 0
        FGUI:GLoader_setUrl(icon,"ui://A_WuXun/"..skillicon)
        -- 武勋技能组件
        local needJS = wuxun_skill_data[i]['needlv'] or 0       -- 需求铸阶等级 全套装备最低铸阶等级
        local curJSNum =  0       
        for k , v in pairs(self.WuXunZhuJieTab) do              -- 当前达到铸阶等级的装备数量
            if k >= needJS then
                curJSNum = curJSNum + v
            end
        end
        -- 武勋技能条件展示 图标置灰
        local jsfont = FGUI:GetChild(self.back['curskill'..i], "n6")
        if curJSNum >= #wuxun_skill_data then
            FGUI:setGrey(icon, false)
            FGUI:setVisible(jsfont, false)
        else
            FGUI:setGrey(icon, true)
            FGUI:setVisible(jsfont, true)
            FGUI:GRichTextField_setText(jsfont, needJS.."阶\n("..curJSNum.."/"..#wuxun_skill_data..")")
        end
        -- 武勋组件点击切换时间
        FGUI:setOnClickEvent(self.back['curskill'..i],function()
            self.SelectZJSkillIndex = i
            self:UpDateSkillTipFont() 
            FGUI:Controller_setSelectedIndex(self.wxzjskilltipsContro,1)
        end)
    end
    --dump(self.WuXunZhuJieTab,"武勋铸阶1")
    -- 下阶武勋技能等级
    self.WuXunZhuJieTab[self.SelectEquipZJLevel] = (self.WuXunZhuJieTab[self.SelectEquipZJLevel] or 1) - 1
    self.WuXunZhuJieTab[nextlv] = (self.WuXunZhuJieTab[nextlv] or 0) + 1
    -- dump(self.WuXunZhuJieTab,"武勋铸阶2")
    -- 下阶武勋技能
    for i=1,#wuxun_skill_data do
        -- 武勋技能图标
        local icon = FGUI:GetChild(self.back['nextskill'..i], "Image_icon")
        local skillicon = wuxun_skill_data[i] and wuxun_skill_data[i]['SkillIcon'] or 0
        FGUI:GLoader_setUrl(icon,"ui://A_WuXun/"..skillicon)
        -- 武勋技能组件
        local needJS = wuxun_skill_data[i]['needlv'] or 0       -- 需求铸阶等级 全套装备最低铸阶等级
        local curJSNum =  0       
        for k , v in pairs(self.WuXunZhuJieTab) do              -- 当前达到铸阶等级的装备数量
            if k >= needJS then
                curJSNum = curJSNum + v
            end
        end
        -- 武勋技能条件展示 图标置灰
        local jsfont = FGUI:GetChild(self.back['nextskill'..i], "n6")
        if curJSNum >= #wuxun_skill_data then
            FGUI:setGrey(icon, false)
            FGUI:setVisible(jsfont, false)
        else
            FGUI:setGrey(icon, true)
            FGUI:setVisible(jsfont, true)
            FGUI:GRichTextField_setText(jsfont, needJS.."阶\n("..curJSNum.."/"..#wuxun_skill_data..")")
        end
        -- 武勋组件点击切换时间
        FGUI:setOnClickEvent(self.back['nextskill'..i],function()
            self.SelectZJSkillIndex = i
            self:UpDateSkillTipFont() 
            FGUI:Controller_setSelectedIndex(self.wxzjskilltipsContro,1)
        end)
    end
    
end
-- 武勋技能描述 
function WuXunPanl:UpDateSkillTipFont()                  -- 技能tips显示
    local skillName = wuxun_skill_data[self.SelectZJSkillIndex] and wuxun_skill_data[self.SelectZJSkillIndex]['SkillName'] or "无"
    local curStr = wuxun_skill_data[self.SelectZJSkillIndex] and wuxun_skill_data[self.SelectZJSkillIndex]['SkillDesc'] or "无"
    FGUI:GTextField_setText(self.Panl_skilltips.n3,skillName.."："..curStr )
end

-------------------------------↓↓↓ 武勋转印 ↓↓↓---------------------------------------
-- 武勋转印界面
function WuXunPanl:WuXunZhuanYin()              
    self.back = FGUI:ui_delegate(self._ui.panl_zhuanyin)     -- 武勋界面  
    -- 转印
    FGUI:setOnClickEvent(self.back.btn_zhuanyin, function()  
        ssrMessage:sendmsgEx("wuxun", "WuXunEquipZhuanYin",{self.SelectZYEquipMakeindex,self.SelectZYXHEquipMakeindex,self.SelectZYEquipAttrIndex,self.SelectZYXHEquipAttrIndex})
    end)

    -- 转印装备控制器
    self.wxzyiswearContro = FGUI:getController(self._ui.panl_zhuanyin,"iswear")
    -- 转印选择装备控制器  0 未选择  1选择中 2已选择
    self.wxzyselectEquipContro = FGUI:getController(self._ui.panl_zhuanyin,"selectEquip")  
    self.panl_addEquip = FGUI:ui_delegate(self.back.panl_addEquip)   -- 选择装备弹窗
    FGUI:setOnClickEvent(self.panl_addEquip.bg, function()                    
        FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,0)
    end)
    self.panl_xzEquip = FGUI:ui_delegate(self.back.xzequip2)   -- 选择装备弹窗
    FGUI:setOnClickEvent(self.panl_xzEquip.closeitembtn, function()
        self.SelectZYXHEquipMakeindex = 0           -- 选择转印消耗装备唯一ID
        self.SelectZYXHEquipEquipData = 0           -- 选择转印消耗装备数据
        self.SelectZYXHEquipAttrIndex = 1           -- 选择转印消耗装备属性索引
        self.SelectZYXHEquipAttrList = {}           -- 当前选择转印消耗装备鉴定转印属性列表
        self:UpdateWXZhuanYin()
        FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,0)
    end)
    
    -- 武勋装备参数
    self.SelectZYEquipItemID = 0                -- 选择转印装备id
    self.SelectZYEquipMakeindex = 0             -- 选择转印装备位装备唯一ID
    self.SelectZYEquipEquipData = 0             -- 选择转印装备数据
    self.SelectZYEquipIndex = 1                 -- 选择转印装备索引
    self.SelectZYEquipAttrIndex = 1             -- 选择转印装备属性索引
    self.SelectZYEquipAttrList = {}             -- 当前选择装备位装备鉴定转印属性列表
    
    self.SelectZYXHEquipMakeindex = 0           -- 选择转印消耗装备唯一ID
    self.SelectZYXHEquipEquipData = 0           -- 选择转印消耗装备数据
    self.SelectZYXHEquipAttrIndex = 1           -- 选择转印消耗装备属性索引
    self.SelectZYXHEquipAttrList = {}           -- 当前选择转印消耗装备鉴定转印属性列表

    self.SelectZYBagEquipList = {}              -- 选择背包里所有满足条件的转印装备列表

    -- 武勋装备展示  左侧列表
    FGUI:GList_itemRenderer(self.back.equipList,handler(self,self.ListWXZYEquipRenderer))  
    FGUI:GList_setDefaultItem(self.back.equipList,"ui://hed3v11ooqrps")
	FGUI:GList_setVirtual(self.back.equipList)
    FGUI:GList_setNumItems(self.back.equipList,  #wuxun_level_data[1]['WuXun_EquipPos'])
    FGUI:GList_addOnClickItemEvent(self.back.equipList, function(context)
        local index=FGUI:GetIntData(context.data)
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][index])
        -- 重新赋值
        self.SelectZYEquipIndex = index
        self.SelectZYEquipItemID = equipData and equipData.ID or 0
        self.SelectZYEquipMakeindex = equipData and equipData.MakeIndex  or 0
        self.SelectZYEquipEquipData = equipData and equipData  or 0
        self.SelectZYEquipAttrIndex = 1             -- 选择转印装备属性索引
        self.SelectZYXHEquipMakeindex = 0           -- 选择转印消耗装备唯一ID
        FGUI:GButton_FireClick(self.back["btn_gx"..self.SelectZYXHEquipAttrIndex], true, true)
        if equipData then
            local zjLv = 0
            if equipData then
                for j = 1, #equipData.Values do
                    if equipData.Values[j]['Id'] == 2 then  
                        zjLv = equipData.Values[j]['Value']
                    end 
                end
            end
            self.SelectEquipZJLevel = zjLv

            -- 转印装备属性列表  鉴定  转印
            self.SelectZYEquipAttrList =  self:GetSelectZYEquipAttrList(equipData,zjLv)

        end 
        -- 重置选择装备控制器  
        FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,0)
        -- 获取可消耗装备数据
        self:GetWuXunEquipData() 
        -- 更新转印数据
        self:UpdateWXZhuanYin()
    end)
    
    -- 可消耗武勋装备展示  右侧列表
    FGUI:GList_itemRenderer(self.panl_addEquip.additemlist,handler(self,self.ListWXZYXHEquipRenderer))  
    FGUI:GList_setDefaultItem(self.panl_addEquip.additemlist,"ui://hed3v11ooqrps")
	FGUI:GList_setVirtual(self.panl_addEquip.additemlist)
    FGUI:GList_addOnClickItemEvent(self.panl_addEquip.additemlist, function(context)
        local index=FGUI:GetIntData(context.data)
        local equipData = self.SelectZYBagEquipList[index]
        -- 重新赋值
        self.SelectZYXHEquipMakeindex = equipData and equipData.MakeIndex  or 0
        self.SelectZYXHEquipEquipData = equipData and equipData  or 0
        self.SelectZYXHEquipAttrIndex = 1             -- 选择转印装备属性索引
        FGUI:GButton_FireClick(self.back["btn_xz"..self.SelectZYXHEquipAttrIndex], true, true)
        if equipData then
            local zjLv = 0
            if equipData then
                for j = 1, #equipData.Values do
                    if equipData.Values[j]['Id'] == 2 then  
                        zjLv = equipData.Values[j]['Value']
                    end 
                end
            end
            -- 转印消耗装备属性列表  鉴定  转印
            self.SelectZYXHEquipAttrList =  self:GetSelectZYEquipAttrList(equipData,zjLv)
        end 
        FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,2)
         -- 更新转印数据
        self:UpdateWXZhuanYin()
    end)
    -- 选择装备转印
    FGUI:setOnClickEvent(self.back.xzequip2, function()   
        if self.SelectZYEquipItemID ~= 0 then
            FGUI:GList_setNumItems(self.panl_addEquip.additemlist,  #self.SelectZYBagEquipList or 0)    
            if #self.SelectZYBagEquipList > 0 then
                FGUI:setVisible(self.panl_addEquip.wpdfont, false)
            else
                FGUI:setVisible(self.panl_addEquip.wpdfont, true)
            end
            FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,1)
        end
    end)
    
    -- 有装备时选中第一个装备
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    for i = 1, #equippos do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[i])
        if equipData then
            local obj = FGUI:GetChildAt(self.back.equipList,i-1)
            FGUI:GButton_FireClick(obj, true, true)
            break
        end
    end
    

    -- 选择装备转印索引
    for i=1,5 do
        FGUI:setOnClickEvent(self.back["btn_gx"..i], function()   
            self.SelectZYEquipAttrIndex = i
            for j=1,5 do
                FGUI:GButton_setSelected(self.back["btn_gx"..j], j == self.SelectZYEquipAttrIndex)
            end
        end)
    end
    -- 选择消耗装备转印索引 已废弃
    -- for i=1,5 do
    --     FGUI:setOnClickEvent(self.back["btn_xz"..i], function()  
    --         local flag = self:isSameAttr(
    --             self.SelectZYEquipAttrList[self.SelectZYEquipAttrIndex] and self.SelectZYEquipAttrList[self.SelectZYEquipAttrIndex][1] or 0,
    --             self.SelectZYXHEquipAttrList[i] and self.SelectZYXHEquipAttrList[i][1] or 0)  
    --         if flag then                    
    --             self.SelectZYXHEquipAttrIndex = i
    --             for j=1,5 do
    --                 FGUI:GButton_setSelected(self.back["btn_xz"..j], j == self.SelectZYXHEquipAttrIndex)
    --             end
    --         else
    --             FGUI:GButton_setSelected(self.back["btn_xz"..i], false)
    --         end
    --     end)
    -- end

    self:UpdateWXZhuanYin()
end

-- 判断是否为相同词条
function WuXunPanl:isSameAttr(attrid1,attrid2)
    -- print(attrid1,attrid2)
    if attrid1 == attrid2 and attrid1 > 0  then
        return false
    end
    return true
end

function WuXunPanl:ListWXZYEquipRenderer(idx,item)      -- 武勋装备展示
    FGUI:SetIntData(item,idx+1)
    if wuxun_level_data[1]['WuXun_EquipPos'][idx+1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][idx+1])
        local extData = {
            hideTip = false,
            itemTipData = equipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        local zjLv = 0
        if equipData then
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then  
                    zjLv = equipData.Values[j]['Value']
                end 
            end
        end
        if self.SelectZYEquipIndex == idx+1 then
            self.SelectZYEquipEquipData = equipData and equipData or 0
            self.SelectEquipZJLevel = zjLv
        end
        local itemname = "未穿戴"
        if equipData then
            local itemobj = ItemUtil:ItemShow_Create(equipData, itemRoot, extData)
            if itemobj.hideArrow then -- 隐藏箭头
                itemobj:hideArrow()
            end
            itemname = SL:GetValue("ITEM_NAME", equipData.ID)
        else
            FGUI:RemoveChildren(itemRoot, 0, -1)
            local icon = FGUI:GetChild(item, "n4")
            FGUI:GLoader_setUrl(icon,equipBGUrl[idx+1] or equipBGUrl[1])
        end
        local name = FGUI:GetChild(item, "name")
        FGUI:GTextField_setText(name, "" .. itemname)
        local att = FGUI:GetChild(item, "att")
        local limitZyNum = 0
        if equipData then 
            limitZyNum = wuxun_zhujie_data[equipData.ID][zjLv] and (wuxun_zhujie_data[equipData.ID][zjLv]['zhuanyin'] or 0) or 0
        end
        local str = ""
        if equipData then
            local itemConfig = equipData.ExAbil
            if itemConfig and itemConfig.abil[2] then  -- 转印属性
                local tab = itemConfig.abil[2]['v']
                if #tab < limitZyNum then
                    str = str.."空转印孔位"
                end
            end
        end
        local Rtitle = FGUI:GetChild(att, "Rtitle")
        FGUI:GRichTextField_setColor(Rtitle, "#00ff00")
        FGUIFunction:ScrollText_setString(att,str, 3.5, 0)
    end
end
-- 消耗武勋装备展示  右侧列表
function WuXunPanl:ListWXZYXHEquipRenderer(idx,item)     
    FGUI:SetIntData(item,idx+1)
    if self.SelectZYBagEquipList[idx+1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        local equipData = self.SelectZYBagEquipList[idx+1]
        local extData = {
            hideTip = false,
            itemTipData = equipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        local itemobj = ItemUtil:ItemShow_Create(equipData, itemRoot, extData)
        if itemobj.hideArrow then -- 隐藏箭头
            itemobj:hideArrow()
        end
        local itemname = SL:GetValue("ITEM_NAME", equipData.ID)
        local name = FGUI:GetChild(item, "name")
        FGUI:GTextField_setText(name, "" .. itemname)
        local att = FGUI:GetChild(item, "att")
        local itemConfig = equipData.ExAbil
        local attrstr = ""
        if itemConfig and itemConfig.abil[1] then
            local tab = itemConfig.abil[1]['v']
            -- dump(tab)
            if tab then
                local attId     = tab[1][2] or 0     -- 属性ID 绑定表
                local name = attrConfigs[attId]['Name'].."："
		        local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
		        local value     = tab[1][3] or 0  -- 属性值
		        if percent == 1 then
		        	value = string.format("%.0f", value / 100) .. "%"  
		        end
                attrstr = ""..name..value
            end
        end
        FGUIFunction:ScrollText_setString(att,attrstr, 3.5, 0)
    end
end
-- 武勋转印更新
function WuXunPanl:UpdateWXZhuanYin()
    -- 选择装备
    local itemRoot = FGUI:GetChild(self.back.xzequip, "itemRoot")
    if self.SelectZYEquipMakeindex ~= 0 then
        local extData = {
            hideTip = false,
            itemTipData = self.SelectZYEquipEquipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(self.SelectZYEquipEquipData, itemRoot, extData)
    else
        FGUI:RemoveChildren(itemRoot, 0, -1)
    end
    -- 选择转印消耗装备
    local itemRoot = FGUI:GetChild(self.back.xzequip2, "itemRoot")
    if self.SelectZYXHEquipMakeindex ~= 0 then
        local extData = {
            hideTip = false,
            itemTipData = self.SelectZYXHEquipEquipData,
            clickCallback = false,
            doubleClickCallback = false,
            bgVisible = true
        }
        ItemUtil:ItemShow_Create(self.SelectZYXHEquipEquipData, itemRoot, extData)
        FGUI:setVisible(self.panl_xzEquip.closeitembtn,true)
    else
        FGUI:RemoveChildren(itemRoot, 0, -1)
        FGUI:setVisible(self.panl_xzEquip.closeitembtn,false)
    end
    -- 是否佩戴装备
    local isWear = self.SelectZYEquipMakeindex ~= 0
    -- 转印穿戴装备控制器
    FGUI:Controller_setSelectedIndex(self.wxzyiswearContro,isWear and 1 or 0)
    
    -- 属性展示  self.SelectZYEquipAttrList
    if isWear then
        for i=1,5 do
            -- 获取穿戴装备属性展示
            if self.SelectZYEquipAttrList[i] then
                local type = self.SelectZYEquipAttrList[i][1] or -2
                local name = self.SelectZYEquipAttrList[i][2] or ""
                local value = self.SelectZYEquipAttrList[i][3] or ""
                if type ~= -2 then
                    FGUI:setVisible(self.back["btn_gx"..i],true)
                    FGUI:setVisible(self.back["suo"..i],false)
                else
                    FGUI:setVisible(self.back["btn_gx"..i],false)
                    FGUI:setVisible(self.back["suo"..i],true)
                end
                FGUI:GTextField_setText(self.back["curfont"..i],name.."  "..value)
                FGUI:GTextField_setColor(self.back["curfont"..i], type == -2 and "#ff0000" or "#00ff00")
            end
            -- 获取选中消耗属性展示
            if self.SelectZYXHEquipAttrList[i] then
                local type = self.SelectZYXHEquipAttrList[i][1] or -2
                local name = self.SelectZYXHEquipAttrList[i][2] or ""
                local value = self.SelectZYXHEquipAttrList[i][3] or ""
                if type > 0 then
                    -- FGUI:setVisible(self.back["btn_xz"..i],true)
                    -- FGUI:setVisible(self.back["xzsuo"..i],false)
                else
                    -- FGUI:setVisible(self.back["btn_xz"..i],false)
                    -- FGUI:setVisible(self.back["xzsuo"..i],true)
                end
                FGUI:GTextField_setText(self.back["nextfont"..i],name.."  "..value)
                FGUI:GTextField_setColor(self.back["nextfont"..i], type == -2 and "#ff0000" or "#00ff00")
            end
        end
    end


end

-- 获取背包物品数据
function WuXunPanl:GetWuXunEquipData()
    self.SelectZYBagEquipList = {}              -- 选择背包里所有满足条件的转印装备列表
    local BagData = SL:GetValue("BAG_DATA")
    -- print("武勋转印装备",self.SelectZYEquipItemID)
    -- 获取选中装备背包里满足消耗条件的装备列表  同ID装备  未铸阶
    for i, data in pairs(BagData) do
        if data.ID == self.SelectZYEquipItemID then    -- 和选中装备相同
            local equipData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", i)
            local itemConfig = equipData.ExAbil
            -- 判断是否已鉴定
            local isJianDIng = false
            if itemConfig and itemConfig.abil[1] then
                isJianDIng = true
            end
            -- 获取铸阶等级
            local zjLv = 0
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then
                    zjLv = equipData.Values[j]['Value']
                    break
                end
            end
            -- 获取是否已转印
            local zynum = 0
            if itemConfig and itemConfig.abil[2] then  
                local tab = itemConfig.abil[2]['v']
                zynum = #tab or 0
            end
            -- 只有已鉴定且未铸阶的装备可以显示
            if isJianDIng and zjLv == 0 and zynum == 0 then
                table.insert(self.SelectZYBagEquipList, equipData)
            end
        end
    end
end

-- 获取右侧展示属性列表
function WuXunPanl:GetSelectZYEquipAttrList(equipData,zjLv)
    local attrlist = {}
    local itemConfig = equipData.ExAbil
    local attrstr = ""
    if itemConfig and itemConfig.abil[1] then
        local tab = itemConfig.abil[1]['v']
        if tab then
            local attId     = tab[1][2] or 0     -- 属性ID 绑定表
            local name = attrConfigs[attId]['Name'].."："
            local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
	        local value     = tab[1][3] or 0  -- 属性值
	        if percent == 1 then
	        	value = string.format("%.0f", value / 100) .. "%"  
	        end
            attrstr = ""..name..value
            attrlist[1] = {attId,name,value}
        end
    end
    local limitZyNum = 0
    if equipData then 
        limitZyNum = wuxun_zhujie_data[equipData.ID][zjLv] and (wuxun_zhujie_data[equipData.ID][zjLv]['zhuanyin'] or 0) or 0
    end
    local index = 1
    for i=1,#wuxun_zhujie_data[equipData.ID] do
        if wuxun_zhujie_data[equipData.ID][i]['zhuanyin'] then
            index = index+1
            attrlist[index] = {-2,"铸阶"..i.."级解锁"}  -- -2 未解锁
        end
    end
    for i=1,4 do
        if i <= limitZyNum then
            attrlist[i+1] = {-1,"可转印"}                -- -1 已解锁未转印
        end
    end
    -- 转印属性
    if itemConfig and itemConfig.abil[2] then  
        local tab = itemConfig.abil[2]['v']
        -- 已转印属性 且对应位置
        for i=1,#tab do
            local attId     = tab[i][2] or 0     -- 属性ID 绑定表
            local name = attrConfigs[attId]['Name'].."："
		    local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
		    local value     = tab[i][3] or 0  -- 属性值
            local index     = tab[i][7] or 0     -- 属性索引
		    if percent == 1 then
		    	value = string.format("%.0f", value / 100) .. "%"  
		    end
            attrlist[index+1] = {attId,name,value}
        end
    end
    --dump(attrlist)
    return attrlist
end


-------------------------------↓↓↓ 模型界面 ↓↓↓---------------------------------------

function WuXunPanl:ClearModel()                           -- 清理中间模型数据 特效
    if self._WuXunModel then
        self:UIModel_Unbind(self.back.graph_fashion_role)
    end
end
function WuXunPanl:UpdateRoleModel()                      -- 更新中间模型数据  特效
    self:ClearModel()
    -- 人物模型
	self._WuXunModel = self:UIModel_Bind(self.back.graph_fashion_role)
	FGUI:UIModel_setObjectEulerAngles(self._WuXunModel, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local Sex = SL:GetValue("SEX")
    local Job = SL:GetValue("JOB")
    local modelData = SL:GetValue("FEATURE")
    if modelData then 
		local extData = {}
		extData.sex = Sex
		extData.job = Job
		extData.bodyId = modelData.clothID == 0 and bodyId or modelData.clothID
		extData.helmetId = modelData.helmetID == 0 and helmetId or modelData.helmetID
        extData.weaponId = modelData.weaponID == 0 and weaponId or modelData.weaponID
		extData.faceId = modelData.faceID == 0 and weaponId or modelData.faceID
        self._WuXunModelIndex = FGUI:UIModel_addCharacterModel(self._WuXunModel, extData, nil, nil,Vector3.one * 1.3)
        FGUI:UIModel_addFx(self._WuXunModel, self.WuXunFXID,true,{x=0,y=0.7,z=0})
    end
    FGUI:UIModel_setModelCallback(self._WuXunModel, function(index)
        FGUI:UIModel_playAnimation(self._WuXunModel, index, "FashionModel", nil, 0)
        self:SetModelRotate(self.back.panel_touch)
    end)
end

function WuXunPanl:SetModelRotate(uiTouch)                -- 设置模型旋转
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    local beginFunc = function (eventData)
        if not self._WuXunModel then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._WuXunModel:GetObjectEulerAngles(self._WuXunModelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._WuXunModel then
            return
        end
        local distanceMax = 1000
        local distence = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self._WuXunModel:SetObjectEulerAngles(0, angle, 0, self._WuXunModelIndex)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

-------------------------------↓↓↓ 弹窗界面 ↓↓↓---------------------------------------
-- 每日奖励界面列表渲染
function WuXunPanl:ListDayGiftShow(idx, item)
    if wuxun_level_data[idx + 1] then
        local itemRoot = FGUI:GetChild(item, "itemRoot")
        -- 武勋称号显示 等级，阵营控制器控制
        -- local wxlvContro = FGUI:getController(item, "wxlv")
        -- local EVILContro = FGUI:getController(item, "GOODEVILID")
        -- FGUI:Controller_setSelectedIndex(wxlvContro,idx)
        -- FGUI:Controller_setSelectedIndex(EVILContro,self.goodDevilID-1)
        -- 奖励列表
        local reward = wuxun_level_data[idx + 1]['rewardList']
        if reward then
            for i=1,#reward do
                local itemData = SL:GetValue("ITEM_DATA", reward[i][1])
                local extData = {
                    hideTip = false,
                    itemTipData = itemData,
                    clickCallback = false,
                    doubleClickCallback = true,
                    bgVisible = true,
                    OverLap = reward[i][2]
                }
                local equip = FGUI:GetChild(item, "equip"..i)
                FGUI:RemoveChildren(equip, 0, -1)
                ItemUtil:ItemShow_Create(itemData, equip, extData)
            end
        end
        -- 是否已领取
        local n20 = FGUI:GetChild(item, "n20") 
        FGUI:setVisible(n20, self.WuXun_Level == (idx + 1))
        local titleid = FGUI:GetChild(item, "titleid")
        local curTitleImg = wuxun_level_data[idx + 1]['WuXun_Pic'][self.goodDevilID][1] and wuxun_level_data[idx + 1]['WuXun_Pic'][self.goodDevilID][1] or 0
        FGUI:GLoader_setUrl(titleid,"ui://A_WuXun/"..curTitleImg)
    end
end

-- 恭喜获得奖励列表渲染
function WuXunPanl:ListGXHDShow(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    local reward = self.GXHDItemList[idx + 1]
    if reward then
        local itemData = SL:GetValue("ITEM_DATA", reward[1])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true,
            OverLap = reward[2]
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
    end
end

-- 恭喜获得弹窗倒计时自动关闭
function WuXunPanl:daojishi()
    if WuXunPanl.dsqid then
        SL:UnSchedule(WuXunPanl.dsqid)
    end
    WuXunPanl.time = 3
    FGUI:GTextField_setText(self.gxhdbg['daojishi'], WuXunPanl.time .. "秒后自动关闭")
    FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
    local function realivedjs()
        WuXunPanl.time = WuXunPanl.time - 1
        FGUI:GTextField_setText(self.gxhdbg['daojishi'], string.format("%s秒后自动关闭", "" .. WuXunPanl.time))
        FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
        if WuXunPanl.time == 0 then
            SL:UnSchedule(WuXunPanl.dsqid)
            WuXunPanl.dsqid = false
            FGUI:Controller_setSelectedIndex(self.gxhdControlle,0)
        end
    end
    WuXunPanl.dsqid = SL:Schedule(realivedjs, 1)
end
-- 装备刷新
function WuXunPanl:RefreshEquipByPos(pos)
    -- print("装备刷新",pos)
    self:ReleaseAllEquipItem() -- 释放所有装备
    local bodyEquips = SL:GetValue("EQUIP_POS_DATAS")
    for pos, makeindex in pairs(bodyEquips) do
        local equipData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", makeindex)
        if equipData then
            self:UpdateWuXunEquip(equipData)
        end
    end
    self:GetWuXunEquip()                        -- 获取装备数据
    -- print("更新更新更新更新更新")
    -- dump(self.EquipBaseAttrTab)
    if self.rightPage == 1 then
        FGUI:GList_setNumItems(self.back.attrlist2,  #self.EquipBaseAttrTab)
        FGUI:GList_refreshVirtualList(self.back.attrlist2)--刷新虚拟列表
    -- dump(self.equipList)
        FGUI:Controller_setSelectedIndex(self.WXequipContro, #self.equipList > 0 and 1 or 0)
    end
end
-------------------------------↓↓↓ 注册 ↓↓↓---------------------------------------
function WuXunPanl:RegisterEvent()
    -- 装备更新
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"WuXunPanl",handler(self, self.RefreshEquipByPos))
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"WuXunPanl",handler(self, self.RefreshEquipByPos))
end


function WuXunPanl:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"WuXunPanl")
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"WuXunPanl")
end
-------------------------------↓↓↓ 网络消息 ↓↓↓---------------------------------------
function WuXunPanl:OnWuXunDataUpdate(data)
    -- 更新UI数据
    self.WuXun_Level = data.WuXun_Level
    self.WuXun_curExp = data.WuXun_curExp
    self.WuXun_DailyState = data.WuXun_DailyState
    self.goodDevilID = data.goodDevilID
    self.WuXunFXID = data.WuXunFXID
    self.WuXun_ChuiLianList = data.WuXun_ChuiLianList
    -- 获取装备数据
    self:GetWuXunEquip()
    
    -- 设置每日奖励列表选中项
    if self.dayGiftbg then
        FGUI:GList_setSelectedIndex(self.dayGiftbg.DayGiftList, self.WuXun_Level-1)
    end
    
    -- 更新界面
    self:ChangeRightPage()
end

-- 更新领取武勋等级每日奖励标识
function WuXunPanl:OnDailyRewardUpdate(data)
    self.WuXun_DailyState = data.state
    FGUI:Controller_setSelectedIndex(self.gxhdControlle,1)
    self:daojishi()
end

-- 更新武勋锤炼数据
function WuXunPanl:OnChuiLianDataUpdate(data)
    self.WuXun_ChuiLianList = data.list
    -- dump(self.WuXun_ChuiLianList,"更新武勋锤炼数据")
    if self.back and self.back.equipList then
        -- print("更新锤炼列表")
        FGUI:GList_setNumItems(self.back.equipList, #wuxun_level_data[1]['WuXun_EquipPos'])
        FGUI:GList_refreshVirtualList(self.back.equipList)
        self:UpdateWXChuiLian()
    end
end

-- 更新武勋铸阶数据
function WuXunPanl:OnZhuJieDataUpdate(data)
    if self.GetWuXunEquipLevel then
        self:GetWuXunEquipLevel()
    end
    if self.back and self.back.equipList then
        FGUI:GList_setNumItems(self.back.equipList, #wuxun_level_data[1]['WuXun_EquipPos'])
        self:UpdateWXZhuJie()
    end
end

-- 更新武勋转印数据
function WuXunPanl:OnZhuanYinDataUpdate(data)
    FGUI:GList_setNumItems(self.back.equipList,  #wuxun_level_data[1]['WuXun_EquipPos'])
    self.SelectZYXHEquipMakeindex = 0           -- 选择转印消耗装备唯一ID
    -- 获取可消耗装备数据
    self:GetWuXunEquipData() 
    local equipData = SL:GetValue("EQUIP_DATA_BY_POS", wuxun_level_data[1]['WuXun_EquipPos'][self.SelectZYEquipIndex])
    if equipData then
        -- 转印装备属性列表  鉴定  转印
        self.SelectZYEquipAttrList =  self:GetSelectZYEquipAttrList(equipData,self.SelectEquipZJLevel)
    end 
    -- 重置选择装备控制器  
    FGUI:Controller_setSelectedIndex(self.wxzyselectEquipContro,0)
    -- 更新转印数据
    self:UpdateWXZhuanYin()
end

return WuXunPanl