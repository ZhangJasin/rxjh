local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local equipCollect = class("equipCollect", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local config = require("game_config/cfgcsv/equipCollect")
local equipCollectData = SL:RequireFile("FGUILayout/Z_Jasin/zbtj/equipCollectData")
local categoryCache = nil
local configType = {
    WEAPON_1 = 1,
    WEAPON_2 = 2,
    WEAPON_3 = 3,
    ARMOR_1  = 4,
    ARMOR_2  = 5,
    ARMOR_3  = 6,
    JEWELRY  = 7,
}

local function getCategoryData(config)
    if not categoryCache then
        categoryCache = {}
        for _, v in ipairs(config) do
            categoryCache[v.type] = categoryCache[v.type] or {}
            categoryCache[v.type][v.sort] = v
        end
    end
    return categoryCache
end

function equipCollect:Create()
    --常量设置
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")

    --初始化请求数据
    self:initData()

    --初始化UI组件
    self._ui = FGUI:ui_delegate(self.component)
    self._showList = {}

    --加载渲染器
    self:initRenderer()

    --绑定事件
    self:bindEvents()

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
            [configType.WEAPON_1] = 0,
            [configType.WEAPON_2] = 1,
            [configType.WEAPON_3] = 2,
            [configType.ARMOR_1]  = 0,
            [configType.ARMOR_2]  = 1,
            [configType.ARMOR_3]  = 2,
            [configType.JEWELRY]  = 0
        }
        local typeIndex = controLst[data.type] or 0
        FGUI:Controller_setSelectedIndex(typeTabs, tonumber(typeIndex))
    end)
end

function equipCollect:bindEvents()
    FGUI:GList_addOnClickItemEvent(self._ui.pageList, function()
        local index = FGUI:GList_getSelectedIndex(self._ui.pageList)
        print("index==", index)
        local pageLst = {
            [0] = { configType.WEAPON_1, configType.WEAPON_2, configType.WEAPON_3 },
            [1] = { configType.ARMOR_1, configType.ARMOR_2, configType.ARMOR_3 },
            [2] = { configType.JEWELRY }
        }
        local targetTypes = pageLst[index]
        if not targetTypes then return end
        local data = {}
        for _, t in ipairs(targetTypes) do
            local group = self._categoryData[t]
            if group then
                table.insert(data, { type = t, list = group })
            end
        end
        table.sort(data, function(a, b) return a.type < b.type end)
        print("执行一次refreshDisplay")
        --dump(data)
        self:refreshDisplay(data)
    end)
end

function equipCollect:refreshDisplay(data)
    self._showList = data or {}
    print("self._showList长度=", #self._showList)
    FGUI:GList_setNumItems(self._ui.typeList, #self._showList)
    --FGUI:GList_resizeToFit(self._ui.typeList, 5)
end

function equipCollect:initPageLists()
    print("equipCollect:initPageLists()")
    --默认页签数据
    FGUI:GList_setSelectedIndex(self._ui.pageList, 0)
    local firstPage = FGUI:GetChildAt(self._ui.pageList, 0)
    FGUI:GButton_FireClick(firstPage, true, true)
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
    local active = FGUI:GetChild(item, "n7")
    FGUI:setOnClickEvent(active, function()
        print("点击激活")
    end)

    --TODO:激活状态
    --dump(dataConf)
end

return equipCollect
