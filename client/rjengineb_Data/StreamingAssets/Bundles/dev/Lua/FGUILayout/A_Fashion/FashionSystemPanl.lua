--[[
    时装系统面板
    主要功能：时装展示、幻化、穿戴、属性展示、魅力值面板等
--]]

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local FashionSystemPanl = class("FashionSystemPanl", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local fashion_huanwu_data      = require("game_config/cfgcsv/fashion_huanwu_data")        --幻武装备数据
local fashion_pifeng_data      = require("game_config/cfgcsv/fashion_pifeng_data")        --披风装备数据
local fashion_toushi_data      = require("game_config/cfgcsv/fashion_toushi_data")        --头饰装备数据
local fashion_charmlevel_data  = require("game_config/cfgcsv/fashion_charmlevel_data")    --魅力值等级数据

local attrConfigs = SL:GetValue("ATTR_CONFIGS") -- 属性配置(AttScore表)
local FashionSystemData = require("FGUILayout/A_Fashion/FashionSystemData")

local _fashion_right_page = {
    [1] = "btn_pifeng",         -- fgui工程按钮组件
    [2] = "btn_huanwu",         -- fgui工程按钮组件
    [3] = "btn_toushi",         -- fgui工程按钮组件
}
local _FashionType = {          -- 时装类型
    PiFeng  = 1,                -- 披风
    HuanWan = 2,                -- 幻武
    TouShi  = 3,                -- 头饰
}
local _FashionTypeKey = {       -- 时装类型
    [1]  = "pifeng",            -- 披风
    [2]  = "huanwu",            -- 幻武
    [3]  = "toushi",            -- 头饰
}

local function fashionTimeOut()                                   -- 更新时装倒计时显示    
    local curtime = os.time()                                    
    if FashionSystemData._fashionTimeOutList then
        for i=1,#FashionSystemData._fashionTimeOutList do
            local stateObj,fashionID,rightPage = FashionSystemData._fashionTimeOutList[i][1], FashionSystemData._fashionTimeOutList[i][2], FashionSystemData._fashionTimeOutList[i][3]
            FGUI:GTextField_setText(stateObj, "")
            local fashionData = FashionSystemData:GetState().FashionDate
            if fashionData and fashionData["".._FashionTypeKey[rightPage]] and fashionData["".._FashionTypeKey[rightPage]][""..fashionID] then  -- 激活了才显示
                local timeout = fashionData["".._FashionTypeKey[rightPage]][""..fashionID][2]
                if timeout ~= -1 then
                    local sytime = timeout - curtime
                    local statestr = SL:SecondToHMS(sytime, true, false)
                    statestr = "剩余时间："..statestr
                    if sytime <= 0 then
                        statestr = "未激活"
                    end
                    FGUI:GTextField_setText(stateObj, statestr)
                else
                    FGUI:GTextField_setText(stateObj, "")
                end
            else
                FGUI:GTextField_setText(stateObj, "未激活")
            end
        end
    end
end

function FashionSystemPanl:Create()
    -- 初始化玩家性别和职业
    local playsex = SL:GetValue("SEX") + 1          -- 玩家性别 1男2女
    local playjob = SL:GetValue("JOB")              -- 玩家职业 1弓手,2枪客,3刺客,4医生,5刀客,6剑客
    -- 移除 CCUI 赋值
    self.itemobjlist = {}
    self._ui = FGUI:ui_delegate(self.component)
    
    FGUI:SetCloseUIWhenClickOutside(self)

    FGUI:setOnClickEvent(self._ui.btn_close, function()     -- 关闭按钮
        FGUI:Close("A_Fashion", "FashionSystemPanl")
    end)
    
    FGUI:setOnClickEvent(self._ui.btn_huanhua, function()   -- 幻化按钮
        -- 使用数据层接口发送消息
        FashionSystemData:RequestHuanHua({self.rightPage, self.leftFashionList[self.leftindex][3]})
        self:UpdateRightBtn()                                 -- 更新右侧按钮
    end)
    
    FGUI:setOnClickEvent(self._ui.btn_use, function()       -- 使用按钮
        -- 使用数据层接口发送消息
        FashionSystemData:RequestWearAttr({self.rightPage, self.leftFashionList[self.leftindex][3]})
        self:UpdateRightBtn()                                 -- 更新右侧按钮
    end)
    
    self.meilizhiSelected = FGUI:getController(self.component,"meilizhi")             -- 魅力值面板显示控制器
    FGUI:setOnClickEvent(self._ui.n8, function()            -- 魅力值按钮
        FGUI:Controller_setSelectedIndex(self.meilizhiSelected, self.meilizhiSelected.selectedIndex == 1 and 0 or 1)
        if self.meilizhiSelected.selectedIndex == 1 then
            self:UpdateCharmPanl()      
        end
    end)
    
    self.meilizhiPanl = FGUI:ui_delegate(self._ui.meilizhi_panl)                    -- 魅力值面板组件
    FGUI:setOnClickEvent(self.meilizhiPanl.btn_close, function()                -- 魅力值面板关闭按钮
        FGUI:Controller_setSelectedIndex(self.meilizhiSelected, 0)
    end)
    
    for i=1,#_fashion_right_page do
        FGUI:setOnClickEvent(self._ui[''.._fashion_right_page[i]], function()   -- 右侧页签事件
            if self.rightPage ~= i then
                self.rightPage = i
                self:ChangeRightPage()                      -- 切换右侧页签
            end
        end)
    end
end
function FashionSystemPanl:Enter(data)
    self.rightPage      = tonumber(data.page) or 1          -- 默认打开右侧第一页
    self.leftindex      = 1                                 -- 左侧时装列表选中下标 默认1
    self.djsobjList     = {}                                -- 时装倒计时文本对象列表
    self._eventTokens   = {}                                -- 事件订阅token列表
    
    -- 初始化倒计时列表
    FashionSystemData._fashionTimeOutList = {}
    
    -- 从数据层获取时装数据
    self.fashionData = FashionSystemData:InitFashionData()
    
    -- 订阅数据更新事件
    local token = FashionSystemData:Subscribe("fashion_data_update", function(data)
        self:OnFashionDataUpdate(data)
    end)
    table.insert(self._eventTokens, token)
    
    self.leftFashionList = {}                               -- 左侧时装展示列表 排序 幻化时装>使用时装>其他已激活时装>未激活时装（未激活按配置表排序） 
    self:ChangeRightPage()                                  -- 更新当前界面数据    
    SL:schedule(self._ui.bg, fashionTimeOut, 1)             -- 添加节点定时器
end
function FashionSystemPanl:Refresh(data)
    -- 界面刷新时调用
end

function FashionSystemPanl:Exit()
    -- 界面关闭时调用
end

function FashionSystemPanl:Destroy()
    -- 取消所有事件订阅
    for _, token in ipairs(self._eventTokens or {}) do
        FashionSystemData:Unsubscribe(token)
    end
    self._eventTokens = nil
    -- 移除倒计时列表
    FashionSystemData._fashionTimeOutList = nil
end


-------------------------------↓↓↓ 本地方法 ↓↓↓---------------------------------------

function FashionSystemPanl:ChangeRightPage()                -- 切换右侧页签
    for i=1,#_fashion_right_page do
        if i == self.rightPage then
            FGUI:GButton_setTitleColor(self._ui[''.._fashion_right_page[i]], "#ffff00")
            FGUI:GButton_setSelected(self._ui[''.._fashion_right_page[i]], true)
        else
            FGUI:GButton_setTitleColor(self._ui[''.._fashion_right_page[i]], "#CCCCCC")
            FGUI:GButton_setSelected(self._ui[''.._fashion_right_page[i]], false)
        end
    end
    self:GetFashinPageData()                                -- 获取当前页时装数据
    self:InitData()                                         -- 切换页签更新数据
    local obj = FGUI:GetChildAt(self.LeftFashion.itemlist,0)
    FGUI:GButton_FireClick(obj, true, true)                 -- 默认点击列表第一个 
end

-- 修改获取时装数据的方法，使用数据层
function FashionSystemPanl:GetFashinPageData()
    self.leftFashionList = {}                               -- 重置左侧时装展示列表数据
    self.djsobjList     = {}                                -- 重置时装倒计时文本对象列表
    
    local playsex = SL:GetValue("SEX") + 1          -- 玩家性别 1男2女
    local playjob = SL:GetValue("JOB")              -- 玩家职业 1弓手,2枪客,3刺客,4医生,5刀客,6剑客
    -- 从数据层获取状态
    local fashionData = FashionSystemData:GetState().FashionDate
    
    local huanhuaID, wearID = 0, 0                          -- 当前时装部位幻化的时装ID,当前时装部位穿戴的时装ID
    if fashionData and fashionData["huanhua"] and fashionData["huanhua"]["".._FashionTypeKey[self.rightPage]] then
        huanhuaID = fashionData["huanhua"]["".._FashionTypeKey[self.rightPage]]
    end
    if fashionData and fashionData["wear"] and fashionData["wear"]["".._FashionTypeKey[self.rightPage]] then
        wearID = fashionData["wear"]["".._FashionTypeKey[self.rightPage]][1]
    end

    -- 以下部分逻辑保持不变，只是将FashionSystemUI.FashionDate替换为fashionData
    if self.rightPage == _FashionType.PiFeng then           -- 披风界面
        for i=1,#fashion_pifeng_data do
            local fashionID = fashion_pifeng_data[i]['sex_type'][playsex] -- 时装装备ID
            local modelID = fashion_pifeng_data[i]['model'][playsex]      -- 时装模型ID
            if not fashion_pifeng_data[i]['Show_Type'] then -- 默认展示
                table.insert(self.leftFashionList,{fashionID,modelID,i})
            else
                if fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..fashionID] then  -- 激活了才显示
                    table.insert(self.leftFashionList,{fashionID,modelID,i})
                end
            end
        end
    elseif self.rightPage == _FashionType.HuanWan then      -- 幻武界面
        for i=1,#fashion_huanwu_data do
            local fashionID = fashion_huanwu_data[i]['job_type'][playjob]
            local modelID = fashion_huanwu_data[i]['model'][playjob]      -- 时装模型ID
            -- SL:ShowSystemTips("角色职业id："..playjob.." 时装ID："..fashionID.." 模型ID："..modelID)
            if not fashion_huanwu_data[i]['Show_Type'] then -- 默认展示
                table.insert(self.leftFashionList,{fashionID,modelID,i})
            else
                if fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..fashionID] then  -- 激活了才显示
                    table.insert(self.leftFashionList,{fashionID,modelID,i})
                end
            end
        end
    elseif self.rightPage == _FashionType.TouShi then       -- 头饰界面
        for i=1,#fashion_toushi_data do
            local fashionID = fashion_toushi_data[i]['sex_type'][playsex]
            local modelID = fashion_toushi_data[i]['model'][playsex]      -- 时装模型ID
            if not fashion_toushi_data[i]['Show_Type'] then -- 默认展示
                table.insert(self.leftFashionList,{fashionID,modelID,i})
            else
                if fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..fashionID] then  -- 激活了才显示
                    table.insert(self.leftFashionList,{fashionID,modelID,i})
                end
            end
        end
    end
    
    -- 排序部分也需要修改为使用fashionData
    table.sort(self.leftFashionList, function(a, b)
        local priorityA,priorityB = 4,4                     -- 默认优先级最低
        if a[1] == huanhuaID then
            priorityA = 1
        elseif a[1] == wearID then
            priorityA = 2
        elseif fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..a[1]] then
            priorityA = 3
        end
        if b[1] == huanhuaID then
            priorityB = 1
        elseif b[1] == wearID then
            priorityB = 2
        elseif fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..b[1]] then
            priorityB = 3
        end
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
        return a[1] < b[1]
    end)
end

function FashionSystemPanl:InitData()                       -- 切换页签更新数据
    self.LeftFashion = FGUI:ui_delegate(self._ui.fashionList)       -- 左侧时装列表组件
    -- 更新左侧时装列表
    FGUI:GList_itemRenderer(self.LeftFashion.itemlist,handler(self,self.ListViewCellsItemRenderer))
    FGUI:GList_setDefaultItem(self.LeftFashion.itemlist,"ui://k09jn1qdrg4i4")
	FGUI:GList_setVirtual(self.LeftFashion.itemlist)
    FGUI:GList_setNumItems(self.LeftFashion.itemlist,  #self.leftFashionList)
    FGUI:GList_addOnClickItemEvent(self.LeftFashion.itemlist, function(context)
        local itemRoot = FGUI:GetChild(context.data,"itemRoot")
        local index=FGUI:GetIntData(itemRoot)
        if self.leftFashionList[index] then
            self.leftindex = index
            -- 更新右侧模型 与 属性
            --self:UpdateFashionModel()                           -- 更新右侧模型 
            self:UpdateRoleModel()                                -- 更新右侧模型 
            self:UpdateRightAttr()                                -- 更新右侧属性
            self:UpdateRightBtn()                                 -- 更新右侧按钮
        end 
    end)
    self:UpdateRightBtn()                       -- 更新右侧幻化使用按钮
    self:UpdateCharmValue()                     -- 更新左上魅力值
    self:UpdateCharmPanl()                      -- 更新魅力值面板展示
end
function FashionSystemPanl:ListViewCellsItemRenderer(idx,item)
    local itemRoot = FGUI:GetChild(item,"itemRoot")
    FGUI:SetIntData(itemRoot, idx+1)
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    if self.leftFashionList[idx+1] then
        local fashionID = self.leftFashionList[idx+1][1]
        local itemData = SL:GetValue("ITEM_DATA", tonumber(fashionID))

        local image_icon = FGUI:GetChild(item,"Image_icon")
        local path = "ui://public/icon_item0"
        if itemData.Looks then
            if itemData.Looks and itemData.Looks >= 0 then
                path = ItemUtil:GetIconResPathByItemID(itemData.ID)
            end
        end
        FGUI:GLoader_setUrl(image_icon, path)

        local title = FGUI:GetChild(item,"title")
        local state = FGUI:GetChild(item,"sytime")
        
        -- 存储倒计时对象到数据层的列表中，包含rightPage信息
        table.insert(FashionSystemData._fashionTimeOutList, {state, fashionID, self.rightPage})
        
        FGUI:GTextField_setText(title, ""..itemData.Name)
        
        -- 使用数据层的数据
        local fashionData = FashionSystemData:GetState().FashionDate
        if fashionData and fashionData["".._FashionTypeKey[self.rightPage]] and fashionData["".._FashionTypeKey[self.rightPage]][""..fashionID] then  -- 激活了才显示
            local timeout = fashionData["".._FashionTypeKey[self.rightPage]][""..fashionID][2]
            if timeout ~= -1 then
                local curtime = os.time()
                local sytime = timeout - os.time()
                local statestr = SL:SecondToHMS(sytime, true, false)
                statestr = "剩余时间："..statestr
                if sytime <= 0 then
                    statestr = "未激活"
                end
                FGUI:GTextField_setText(state, ""..statestr)
            else
                FGUI:GTextField_setText(state, "")
            end
        else
            FGUI:GTextField_setText(state, "未激活")
        end
    end
end

-- 修改魅力值相关方法，使用数据层
function FashionSystemPanl:UpdateCharmValue()
    self.LeftTopCharm = FGUI:ui_delegate(self._ui.n8)             -- 左上魅力值按钮组件
    local charmData = FashionSystemData:GetState()
    FGUI:GTextField_setText(self.LeftTopCharm.level, ""..charmData.charmLv)
    FGUI:GTextField_setText(self.LeftTopCharm.levelfont, charmData.charmLv.."级")
end

function FashionSystemPanl:UpdateCharmPanl()
    local maxmlzLv = #fashion_charmlevel_data                     -- 魅力值最高等级
    local charmData = FashionSystemData:GetState()
    local nextLv = (charmData.charmLv+1) > maxmlzLv and maxmlzLv or (charmData.charmLv+1)
    
    FGUI:GTextField_setText(self.meilizhiPanl.curmllv, ""..charmData.charmLv.."级")
    FGUI:GTextField_setText(self.meilizhiPanl.nextmllv, ""..nextLv.."级")
    FGUI:GTextField_setText(self.meilizhiPanl.curneed, "当前魅力："..charmData.charmValue)
    FGUI:GTextField_setText(self.meilizhiPanl.nextneed, "需要魅力："..fashion_charmlevel_data[nextLv]['need'])
    FGUI:GRichTextField_setText(self.meilizhiPanl.nextneed, "需要魅力：<font color='#ff0000'>"..fashion_charmlevel_data[nextLv]['need'].."</font>")
    
    -- 更新当前魅力值属性列表
    FGUI:GList_itemRenderer(self.meilizhiPanl.curattrlist,handler(self,self.ListCurAttrRenderer))
    FGUI:GList_setDefaultItem(self.meilizhiPanl.curattrlist,"ui://k09jn1qdrg4i10")
    FGUI:GList_setVirtual(self.meilizhiPanl.curattrlist)
    FGUI:GList_setNumItems(self.meilizhiPanl.curattrlist, #fashion_charmlevel_data[charmData.charmLv]['attrlist'])
    
    -- 更新下一级魅力值属性列表
    FGUI:GList_itemRenderer(self.meilizhiPanl.nextattrlist,handler(self,self.ListNextAttrRenderer))
    FGUI:GList_setDefaultItem(self.meilizhiPanl.nextattrlist,"ui://k09jn1qdrg4i10")
    FGUI:GList_setVirtual(self.meilizhiPanl.nextattrlist)
    FGUI:GList_setNumItems(self.meilizhiPanl.nextattrlist, #fashion_charmlevel_data[nextLv]['attrlist'])
end

-- 当前等级魅力值属性列表
function FashionSystemPanl:ListCurAttrRenderer(idx,item)
    local charmData = FashionSystemData:GetState()
    if fashion_charmlevel_data[charmData.charmLv]['attrlist'][idx+1] then
        local tab = fashion_charmlevel_data[charmData.charmLv]['attrlist'][idx+1]
        local font = FGUI:GetChild(item,"n1")
        local str = ""
        local name = attrConfigs[tab[1]]['Name'].."： "
        local value = tab[2]
        local type = attrConfigs[tab[1]]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.1f", value / 100) * 10 / 10 .. "%"
        end
        str = str.."<font color='#fff5da'>"..name.."</font><font color='#fff5da'>+"..value.."</font>"
        FGUI:GRichTextField_setText(font,str)
    end
end
-- 下一级魅力值属性列表
function FashionSystemPanl:ListNextAttrRenderer(idx,item)
    local maxmlzLv = #fashion_charmlevel_data                     -- 魅力值最高等级
    local charmData = FashionSystemData:GetState()
    local nextLv = (charmData.charmLv+1) > maxmlzLv and maxmlzLv or (charmData.charmLv+1)
    if fashion_charmlevel_data[nextLv]['attrlist'][idx+1] then
        local tab = fashion_charmlevel_data[nextLv]['attrlist'][idx+1]
        local font = FGUI:GetChild(item,"n1")
        local str = ""
        local name = attrConfigs[tab[1]]['Name'].."： "
        local value = tab[2]
        local type = attrConfigs[tab[1]]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.1f", value / 100) * 10 / 10 .. "%"
        end
        str = str.."<font color='#fff5da'>"..name.."</font><font color='#00ff00'>+"..value.."</font>"
        FGUI:GRichTextField_setText(font,str)
    end
end
function FashionSystemPanl:ClearModel()                           -- 清理中间模型数据
    if self._FashionModel then
        self:UIModel_Unbind(self._ui.graph_fashion_role)
    end
end
function FashionSystemPanl:UpdateRoleModel()                      -- 更新中间模型数据
    self:ClearModel()
	self._FashionModel = self:UIModel_Bind(self._ui.graph_fashion_role)
	FGUI:UIModel_setObjectEulerAngles(self._FashionModel, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local Sex = SL:GetValue("SEX")
    local Job = SL:GetValue("JOB")
    local modelData = SL:GetValue("FEATURE")
    -- dump(modelData)
    if modelData then 
		local extData = {}
		extData.sex = Sex
		extData.job = Job
		extData.bodyId = modelData.clothID == 0 and bodyId or modelData.clothID
		extData.helmetId = modelData.helmetID == 0 and helmetId or modelData.helmetID
        extData.weaponId = modelData.weaponID == 0 and weaponId or modelData.weaponID
		extData.faceId = modelData.faceID == 0 and weaponId or modelData.faceID
        -- dump(extData)
        if self.rightPage == _FashionType.PiFeng then           -- 披风界面
            extData.bodyId = self.leftFashionList[self.leftindex][2]
        elseif self.rightPage == _FashionType.HuanWan then      -- 幻武界面
            extData.weaponId = self.leftFashionList[self.leftindex][2]
        elseif self.rightPage == _FashionType.TouShi then       -- 头饰界面
            extData.helmetId = self.leftFashionList[self.leftindex][2]
        end
        -- dump(extData)
        -- print("self.leftFashionList[self.leftindex][2]="..self.leftFashionList[self.leftindex][2])
        self._FashionModelIndex = FGUI:UIModel_addCharacterModel(self._FashionModel, extData, nil, nil,Vector3.one * 1.6)
    end
    FGUI:UIModel_setModelCallback(self._FashionModel, function(index)
        FGUI:UIModel_playAnimation(self._FashionModel, index, "FashionModel", nil, 0)
        self:SetModelRotate(self._ui.panel_touch)
    end)
end

function FashionSystemPanl:SetModelRotate(uiTouch)                -- 设置模型旋转
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    local beginFunc = function (eventData)
        if not self._FashionModel then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._FashionModel:GetObjectEulerAngles(self._FashionModelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._FashionModel then
            return
        end
        local distanceMax = 1000
        local distence = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self._FashionModel:SetObjectEulerAngles(0, angle, 0, self._FashionModelIndex)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

function FashionSystemPanl:UpdateRightAttr()                      -- 更新右侧属性展示
    -- 激活属性 大于1条属性用 attr1_panl 默认第一条为魅力值
    self.attr1_panl = FGUI:ui_delegate(self._ui.attr1_panl)       -- 激活属性组件
    self.attr1_font = FGUI:ui_delegate(self.attr1_panl.attrfont)  -- 激活属性文本组件
    local jhAttrTab,JHCharm = {},0                                -- 初始化激活属性列表,激活可获得魅力值
    local index = self.leftFashionList[self.leftindex][3]         -- 当前选中时装对应配置表下标
    if self.rightPage == _FashionType.PiFeng then                 -- 披风界面
        jhAttrTab = fashion_pifeng_data[index]['fashion_attr']
        JHCharm   = fashion_pifeng_data[index]['charmValue']
    elseif self.rightPage == _FashionType.HuanWan then            -- 幻武界面
        jhAttrTab = fashion_huanwu_data[index]['fashion_attr']
        JHCharm   = fashion_huanwu_data[index]['charmValue']
    elseif self.rightPage == _FashionType.TouShi then             -- 头饰界面
        jhAttrTab = fashion_toushi_data[index]['fashion_attr']
        JHCharm   = fashion_toushi_data[index]['charmValue']
    end
    local str = "<font color='#fff5da'>魅力值：</font><font color='#7dc6b3'>+"..JHCharm.."</font>"
    FGUI:GTextField_setText(self.LeftTopCharm.value, "+"..JHCharm)
    for i=1,#jhAttrTab do
        local name = attrConfigs[jhAttrTab[i][1]]['Name'].."："
        local value = jhAttrTab[i][2]
        local type = attrConfigs[jhAttrTab[i][1]]['Type'] or 0 -- 0 数值 1 万分比
        if type == 1 then
            value = string.format("%.1f", value / 100) * 10 / 10 .. "%"
        end
        str = str.."<br><font color='#fff5da'>"..name.."</font><font color='#7dc6b3'>+"..value.."</font>"
    end  
    FGUI:GRichTextField_setText(self.attr1_font.font,str)
    -- 穿戴属性 大于5条属性用 attr2_panl
    self.attr2_panl = FGUI:ui_delegate(self._ui.attr2_panl)       -- 激活属性组件
    self.attr2_font = FGUI:ui_delegate(self.attr2_panl.attrfont)  -- 激活属性文本组件
    local jhAttrTab,JHCharm = {},0                                -- 初始化激活属性列表,激活可获得魅力值
    local index = self.leftFashionList[self.leftindex][3]         -- 当前选中时装对应配置表下标
    if self.rightPage == _FashionType.PiFeng then                 -- 披风界面
        JHCharm   = fashion_pifeng_data[index]['charmValue']
    elseif self.rightPage == _FashionType.HuanWan then            -- 幻武界面
        JHCharm   = fashion_huanwu_data[index]['charmValue']
    elseif self.rightPage == _FashionType.TouShi then             -- 头饰界面
        JHCharm   = fashion_toushi_data[index]['charmValue']
    end
    local itemData = SL:GetValue("ITEM_DATA", self.leftFashionList[self.leftindex][1])
    local attData = FGUIFunction:GetAttShowData(itemData.Attribute, nil, nil)
    --dump(itemData)
    --dump(attData)
    local str = ""
    for i=1,#attData do
        local name = attData[i]['name'].."："
        local value = attData[i]['value']
        if str ~= "" then
            str = str.."<br>"
        end
        str = str.."<font color='#fff5da'>"..name.."</font><font color='#7dc6b3'>+"..value.."</font>"
    end
    FGUI:GRichTextField_setText(self.attr2_font.font,str)

    -- 热血石属性  暂无
    self.attr3_panl = FGUI:ui_delegate(self._ui.attr3_panl)       -- 热血石属性组件
    FGUI:setVisible(self.attr3_panl.attrimg,true)
end

function FashionSystemPanl:UpdateRightBtn()
    local fashionData = FashionSystemData:GetState().FashionDate
    local huanhuaID, wearID = 0, 0
    
    if fashionData and fashionData["huanhua"] and fashionData["huanhua"]["".._FashionTypeKey[self.rightPage]] then
        huanhuaID = fashionData["huanhua"]["".._FashionTypeKey[self.rightPage]]
    end
    if fashionData and fashionData["wear"] and fashionData["wear"]["".._FashionTypeKey[self.rightPage]] then
        wearID = fashionData["wear"]["".._FashionTypeKey[self.rightPage]][1]
    end
    -- print("更新时装按钮UpdateRightBtn", huanhuaID, wearID)
    if self.leftFashionList[self.leftindex] and self.leftFashionList[self.leftindex][1] == huanhuaID then
        FGUI:GButton_setSelected(self._ui.btn_huanhua, true)
    else
        FGUI:GButton_setSelected(self._ui.btn_huanhua, false)
    end
    if self.leftFashionList[self.leftindex] and self.leftFashionList[self.leftindex][1] == wearID then
        FGUI:GButton_setSelected(self._ui.btn_use, true)
    else
        FGUI:GButton_setSelected(self._ui.btn_use, false)
    end
end



-------------------------------↓↓↓ 网络消息 ↓↓↓---------------------------------------

-- 新增数据更新回调函数
function FashionSystemPanl:OnFashionDataUpdate(data)
    self.fashionData = FashionSystemData:GetState().FashionDate
    self:UpdateRightBtn()                       -- 更新右侧幻化使用按钮
    self:UpdateCharmValue()                     -- 更新左上魅力值
    self:UpdateCharmPanl()                      -- 更新魅力值面板展示
end

return FashionSystemPanl