local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local equipCollect = class("equipCollect", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local config = require("game_config/cfgcsv/equipCollect")
local attrConfig = require("game_config/cfgcsv/equipCollectAttr")
local equipCollectData = SL:RequireFile("FGUILayout/Z_Jasin/zbtj/equipCollectData")
local AttScoreNames = require("game_config/AttScore")
local categoryCache = nil
local configType = {
    WEAPON_1  = 1,
    WEAPON_2  = 2,
    WEAPON_3  = 3,
    ARMOR_1   = 4,
    ARMOR_2   = 5,
    ARMOR_3   = 6,
    JEWELRY_1 = 7,
    JEWELRY_2 = 8,
    JEWELRY_3 = 9
}

local function getCategoryData(config)
    local job = SL:GetValue("JOB")
    local GOODEVILID = SL:GetValue("GOODEVILID")
    --print("job=", job)
    --print("GOODEVILID=", GOODEVILID)
    if not categoryCache then
        categoryCache = {}
        for _, v in ipairs(config) do
            if job == v.job and GOODEVILID == v.sect then
                categoryCache[v.type] = categoryCache[v.type] or {}
                categoryCache[v.type][v.sort] = v
            end
            if v.type == configType.JEWELRY_1 or v.type == configType.JEWELRY_2 or v.type == configType.JEWELRY_3 then
                categoryCache[v.type] = categoryCache[v.type] or {}
                categoryCache[v.type][v.sort] = v
            end
        end
    end
    return categoryCache
end

function equipCollect:Create()
    --常量设置
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")

    --初始化UI组件
    self._ui = FGUI:ui_delegate(self.component)
    self._showList = {}

    --订阅事件
    self:subscribeEvents()

    --初始化数据
    self:initData()

    --绑定渲染器
    self:initRenderer()

    --绑定事件
    self:bindEvents()

    --请求数据
    equipCollectData:Init()

    --默认页签数据
    self:initPageLists()

    --冗余设置
    FGUI:SetCloseUIWhenClickOutside(self)               --点击空白关闭
    FGUI:setOnClickEvent(self._ui.btn_close, function() --关闭按钮
        FGUI:Close("Z_Jasin", isPC and "equipCollect" or "equipCollect")
    end)
    --适配pc端UI
    if isPC then
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end
end

function equipCollect:Destroy()
    if self._dataSub then
        equipCollectData:Unsubscribe(self._dataSub)
        self._dataSub = nil
    end
    self._ui = nil
end

function equipCollect:subscribeEvents()
    self._dataSub = equipCollectData:Subscribe("EQUIP_COLLECT_UPDATE", function(info)
        print("被激活的id=", info.id)
        local index = FGUI:GList_getSelectedIndex(self._ui.pageList)
        self:updateShowListByIndex(index)
    end)
end

function equipCollect:initData()
    self._categoryData = getCategoryData(config)
    --dump(self._categoryData)
end

function equipCollect:initRenderer()
    FGUI:GList_setAutoResizeItem(self._ui.typeList, true)
    FGUI:GList_itemRenderer(self._ui.typeList, function(idx, item)
        local data = self._showList[idx + 1]
        if not data then return end
        --dump(data)
        local equipLst = FGUI:GetChild(item, "equipList")

        -- equipList 是流式布局，每行5个，需要手动计算高度
        local itemW, itemH = 170, 202 -- equipItem.xml 尺寸
        local lineItemCount = 5       -- 每行显示5个
        local lineGap = 10            -- 行间距
        local itemCount = #data.list
        local lineCount = math.max(1, math.ceil(itemCount / lineItemCount))
        local equipListH = lineCount * itemH + (lineCount - 1) * lineGap

        FGUI:GList_itemRenderer(equipLst, function(sIdx, sItem)
            local itemData = data.list[sIdx + 1]
            if not itemData then return end
            self:equipListRenderer(itemData, sIdx, sItem)
        end)
        FGUI:GList_setNumItems(equipLst, itemCount)

        -- 设置父容器 item 的高度 = 标题栏(57) + equipList高度 + 底部边距(5)
        local itemTotalH = 57 + equipListH + 5
        FGUI:setSize(item, 905, itemTotalH)

        local typeTabs = FGUI:getController(item, "type")
        local controLst = {
            [configType.WEAPON_1]  = 0,
            [configType.WEAPON_2]  = 1,
            [configType.WEAPON_3]  = 2,
            [configType.ARMOR_1]   = 0,
            [configType.ARMOR_2]   = 1,
            [configType.ARMOR_3]   = 2,
            [configType.JEWELRY_1] = 0,
            [configType.JEWELRY_2] = 1,
            [configType.JEWELRY_3] = 2
        }

        --TODO：特殊处理首饰
        if FGUI:GList_getSelectedIndex(self._ui.pageList) == 2 then
            FGUI:Controller_setSelectedIndex(typeTabs, 0)
            local name = FGUI:GetChild(item, "name1")
            local nameLst = {
                [0] = "项链",
                [1] = "耳环",
                [2] = "戒指",
            }
            FGUI:GTextField_setText(name, nameLst[idx])
        else
            local typeIndex = controLst[data.type] or 0
            FGUI:Controller_setSelectedIndex(typeTabs, tonumber(typeIndex))
            local name = FGUI:GetChild(item, "name1")
            FGUI:GTextField_setText(name, "上品")
        end
    end)

    local curAttrLst = FGUI:GetChild(self._ui.showAttr, "cur_attr_list")
    local nextAttrLst = FGUI:GetChild(self._ui.showAttr, "next_attr_list")
    FGUI:GList_itemRenderer(curAttrLst, function(idx, item)
        local curAttr = equipCollectData:GetCurAttr()
        local data = {}
        for index, info in pairs(curAttr) do
            if index == idx + 1 then
                data = info
            end
        end
        self:equipAttrListRenderer(data, idx, item, 0)
    end)
    FGUI:GList_itemRenderer(nextAttrLst, function(idx, item)
        local nextAttr = equipCollectData:GetNextAttr()
        local data = {}
        for index, info in pairs(nextAttr) do
            if index == idx + 1 then
                data = info
            end
        end
        self:equipAttrListRenderer(data, idx, item, 1)
    end)
end

function equipCollect:updateShowListByIndex(index)
    local pageMapping = {
        [0] = { configType.WEAPON_1, configType.WEAPON_2, configType.WEAPON_3 },
        [1] = { configType.ARMOR_1, configType.ARMOR_2, configType.ARMOR_3 },
        [2] = { configType.JEWELRY_1, configType.JEWELRY_2, configType.JEWELRY_3 }
    }
    local targetTypes = pageMapping[index] or {}
    local data = {}
    for _, t in ipairs(targetTypes) do
        local group = self._categoryData[t]
        if group then
            table.insert(data, { type = t, list = group })
        end
    end
    table.sort(data, function(a, b) return a.type < b.type end)
    self:refreshDisplay(data)
end

function equipCollect:bindEvents()
    FGUI:GList_addOnClickItemEvent(self._ui.pageList, function()
        local index = FGUI:GList_getSelectedIndex(self._ui.pageList)
        self:updateShowListByIndex(index)
    end)

    local showAttrControl = FGUI:getController(self.component, "showAttr")
    FGUI:setOnClickEvent(self._ui.tips, function()
        local status = FGUI:Controller_getSelectedIndex(showAttrControl)
        FGUI:Controller_setSelectedIndex(showAttrControl, 1 - status)
        if status == 0 then
            self:refreshAttr()
        end
    end)

    local showAttrBtnClose = FGUI:GetChild(self._ui.showAttr, "btn_close")
    FGUI:setOnClickEvent(showAttrBtnClose, function()
        FGUI:Controller_setSelectedIndex(showAttrControl, 0)
    end)
end

function equipCollect:refreshDisplay(data)
    self._showList = data or {}
    FGUI:GList_setNumItems(self._ui.typeList, #self._showList)

    local totalValue = equipCollectData:GetCurValue()
    local valueText = FGUI:GetChild(self._ui.tips, "level")
    FGUI:GTextField_setText(valueText, totalValue)
end

function equipCollect:refreshAttr()
    local curAttr = equipCollectData:GetCurAttr()
    local nextAttr = equipCollectData:GetNextAttr()
    local curValue = equipCollectData:GetCurValue()
    local nextValue = equipCollectData:GetNextValue()

    local curLevel = FGUI:GetChild(self._ui.showAttr, "cur_level")
    local nextLevel = FGUI:GetChild(self._ui.showAttr, "next_level")
    local curAttrList = FGUI:GetChild(self._ui.showAttr, "cur_attr_list")
    local nextAttrList = FGUI:GetChild(self._ui.showAttr, "next_attr_list")

    FGUI:GTextField_setText(curLevel, curValue)
    FGUI:GTextField_setText(nextLevel, nextValue)

    --序列化属性配表
    local curAttrLens = 0
    local nextAttrLens = 0
    for i, j in pairs(curAttr) do
        curAttrLens = curAttrLens + 1
    end
    for k, v in pairs(nextAttr) do
        nextAttrLens = nextAttrLens + 1
    end
    FGUI:GList_setNumItems(curAttrList, curAttrLens)
    FGUI:GList_setNumItems(nextAttrList, nextAttrLens)
end

function equipCollect:initPageLists()
    --默认页签数据
    FGUI:GList_setSelectedIndex(self._ui.pageList, 0)
    local firstPage = FGUI:GetChildAt(self._ui.pageList, 0)
    FGUI:GButton_FireClick(firstPage, true, true)
end

function equipCollect:equipAttrListRenderer(data, idx, item, type)
    local attrId = data[1]
    local attrValue = data[2]
    local isPercent = data[3]
    local attrName = AttScoreNames[attrId].Name

    local item_name = FGUI:GetChild(item, "name")
    local item_value = FGUI:GetChild(item, "value")

    local valueText = ""
    if isPercent == 1 then
        attrValue = math.floor(attrValue / 100)
        valueText = string.format("+%d%%", attrValue)
    else
        valueText = string.format("+%d", attrValue)
    end

    FGUI:GTextField_setText(item_name, attrName)
    FGUI:GTextField_setText(item_value, valueText)

    local equipAttrControl = FGUI:getController(item, "type")
    FGUI:Controller_setSelectedIndex(equipAttrControl, type)
end

function equipCollect:equipListRenderer(data, idx, item)
    --加载文案
    local name = FGUI:GetChild(item, "n3")
    local value = FGUI:GetChild(item, "n4")
    FGUI:GTextField_setText(name, data.showName)
    FGUI:GTextField_setText(value, string.format("收藏值+%d", data.value))
    local dataConf = SL:GetValue("ITEM_DATA", data.idx)
    local color = SL:GetColorByStyleId(dataConf.Color) or "#000000"
    FGUI:GTextField_setColor(name, color)
    --加载图标
    local itemIcon = FGUI:GetChild(item, "n5")
    if FGUI:GetChildCount(itemIcon) > 0 then
        FGUI:RemoveChildAt(itemIcon, 0, true)
    end
    local extData = {}
    extData.hideTip = false
    extData.itemTipData = dataConf
    extData.clickCallback = false
    extData.doubleClickCallback = false
    extData.bgVisible = true
    ItemUtil:ItemShow_Create(dataConf, itemIcon, extData)

    --激活按钮
    local isActive = equipCollectData:IsActive(data.idx)
    local activeBtn = FGUI:GetChild(item, "n7")
    local stateCtrol = FGUI:getController(item, "active")

    if isActive then
        FGUI:Controller_setSelectedIndex(stateCtrol, 1)
    else
        FGUI:Controller_setSelectedIndex(stateCtrol, 0)
        FGUI:setOnClickEvent(activeBtn, function()
            equipCollectData:ReqActive(data.idx)
        end)
    end
end

return equipCollect
