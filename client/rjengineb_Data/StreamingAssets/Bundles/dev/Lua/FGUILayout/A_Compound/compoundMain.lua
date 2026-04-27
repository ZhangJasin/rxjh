local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local compoundMain = class("compoundMain", BaseFGUILayout)
local compoundMainData = SL:RequireFile("FGUILayout/A_Compound/compoundMainData")
local FGUI = SL:RequireFile("FGUI/FGUI")

local SUBSCRIBE_TOKENS = {}

function compoundMain:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._data = compoundMainData:getInstance()

    FGUI:SetCloseUIWhenClickOutside(self)

    -- 关闭按钮 (n3 是 btn_close 组件)
    FGUI:setOnClickEvent(self._ui.n3, function()
        FGUI:Close("A_Compound", "compoundMain")
    end)

    -- 一级菜单按钮 (n35 - btn_hc1) - 点击切换按钮按下状态
    FGUI:setOnClickEvent(self._ui.n35, function()
        self:OnGroup1Click()
    end)

    -- 二级菜单按钮 (n36 - btn_hc2) - 根据一级选择切换数据
    FGUI:setOnClickEvent(self._ui.n36, function()
        self:OnGroup2Click()
    end)

    -- 三级列表 (n37 - 列表，使用 btn_hc3 作为默认项)
    FGUI:GList_addOnClickItemEvent(self._ui.n37, function(context)
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.n37)
        local group3List = self._data:GetGroup3List(self._data._currentGroup1, self._data._currentGroup2)
        if group3List[selectedIndex + 1] then
            self._data:SelectGroup3(group3List[selectedIndex + 1])
        end
    end)

    self:_initListRenderers()
end

function compoundMain:_initListRenderers()
    -- 三级列表渲染 (n37 列表)
    FGUI:GList_setItemRenderer(self._ui.n37, function(item, index)
        local group3List = self._data:GetGroup3List(self._data._currentGroup1, self._data._currentGroup2)
        local text = group3List[index + 1] or ""

        -- btn_hc3 组件结构: n1 是文本
        if item.n1 then
            FGUI:GTextField_setText(item.n1, text)
        end

        -- 选中状态通过按钮的 controller 控制
        local selectedIndex = FGUI:GList_getSelectedIndex(self._ui.n37)
        if item.controller and item.controller.setSelectedPage then
            item.controller:setSelectedPage(selectedIndex == index and "down" or "up")
        end
    end)
end

-- 一级菜单点击事件 - 只切换按钮按下状态
function compoundMain:OnGroup1Click()
    local group1List = self._data:GetGroup1List()
    if #group1List == 0 then
        return
    end

    -- 循环切换一级菜单
    local currentIndex = 1
    for i, g1 in ipairs(group1List) do
        if g1 == self._data._currentGroup1 then
            currentIndex = i
            break
        end
    end
    local nextIndex = (currentIndex % #group1List) + 1
    self._data:SelectGroup1(group1List[nextIndex])
end

-- 二级菜单点击事件 - 根据一级选择切换当前数据
function compoundMain:OnGroup2Click()
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    if #group2List == 0 then
        return
    end

    -- 循环切换二级菜单
    local currentIndex = 1
    for i, g2 in ipairs(group2List) do
        if g2 == self._data._currentGroup2 then
            currentIndex = i
            break
        end
    end
    local nextIndex = (currentIndex % #group2List) + 1
    self._data:SelectGroup2(group2List[nextIndex])
end

function compoundMain:Enter(data)
    self:_subscribeEvents()
    self:RefreshUI()
end

function compoundMain:Refresh(data)
    self:RefreshUI()
end

function compoundMain:Exit()
    self:_unsubscribeEvents()
end

function compoundMain:Destroy()
    self:_unsubscribeEvents()
end

function compoundMain:_subscribeEvents()
    -- 清除旧订阅
    for _, token in ipairs(SUBSCRIBE_TOKENS) do
        self._data:Unsubscribe(token)
    end
    SUBSCRIBE_TOKENS = {}

    -- 订阅一级分组变化
    local token1 = self._data:Subscribe("compound_group1_changed", handler(self, self.OnGroup1Changed))
    table.insert(SUBSCRIBE_TOKENS, token1)

    -- 订阅二级分组变化
    local token2 = self._data:Subscribe("compound_group2_changed", handler(self, self.OnGroup2Changed))
    table.insert(SUBSCRIBE_TOKENS, token2)

    -- 订阅三级分组变化
    local token3 = self._data:Subscribe("compound_group3_changed", handler(self, self.OnGroup3Changed))
    table.insert(SUBSCRIBE_TOKENS, token3)
end

function compoundMain:_unsubscribeEvents()
    for _, token in ipairs(SUBSCRIBE_TOKENS) do
        self._data:Unsubscribe(token)
    end
    SUBSCRIBE_TOKENS = {}
end

-- 一级菜单变化事件 - 刷新二级列表
function compoundMain:OnGroup1Changed(data)
    -- 切换一级菜单时，只刷新二级列表显示和三级列表
    self:RefreshGroup2List()
    self:RefreshGroup3List()
    self:RefreshContent()
end

-- 二级菜单变化事件 - 只更新当前列表
function compoundMain:OnGroup2Changed(data)
    -- 切换二级菜单时，只刷新三级列表
    self:RefreshGroup3List()
    self:RefreshContent()
end

-- 三级菜单变化事件
function compoundMain:OnGroup3Changed(data)
    self:RefreshContent()
end

function compoundMain:RefreshUI()
    self:RefreshGroup1Button()
    self:RefreshGroup2List()
    self:RefreshGroup3List()
    self:RefreshContent()
end

-- 刷新一级菜单按钮状态
function compoundMain:RefreshGroup1Button()
    -- btn_hc1 组件: n3 和 n4 是文本（高亮和普通状态）
    local group1Name = self._data._currentGroup1 or ""
    if self._ui.n35 and self._ui.n35.n3 then
        FGUI:GTextField_setText(self._ui.n35.n3, group1Name)
    end
    if self._ui.n35 and self._ui.n35.n4 then
        FGUI:GTextField_setText(self._ui.n35.n4, group1Name)
    end
end

-- 刷新二级菜单按钮数据
function compoundMain:RefreshGroup2List()
    -- btn_hc2 组件: n1 是文本
    -- 根据一级选择，刷新二级列表的第一个项
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    if #group2List > 0 then
        -- 默认选中第一个二级菜单
        local group2Name = self._data._currentGroup2 or group2List[1]
        if self._ui.n36 and self._ui.n36.n1 then
            FGUI:GTextField_setText(self._ui.n36.n1, group2Name)
        end
    else
        if self._ui.n36 and self._ui.n36.n1 then
            FGUI:GTextField_setText(self._ui.n36.n1, "")
        end
    end
end

-- 刷新三级列表
function compoundMain:RefreshGroup3List()
    local group3List = self._data:GetGroup3List(self._data._currentGroup1, self._data._currentGroup2)
    FGUI:GList_setNumItems(self._ui.n37, #group3List)

    -- 选中当前分组
    local currentIndex = 0
    for i, g3 in ipairs(group3List) do
        if g3 == self._data._currentGroup3 then
            currentIndex = i - 1
            break
        end
    end
    FGUI:GList_setSelectedIndex(self._ui.n37, currentIndex)
    FGUI:GList_RefreshVirtualList(self._ui.n37)
end

function compoundMain:RefreshContent()
    local content = self._data:GetCurrentContent()
    if not content then
        return
    end

    -- 根据三级菜单选择的内容刷新显示
    -- 这里可以添加自定义的内容显示逻辑
    -- 如果有内容显示区域，可以在这里更新
end

return compoundMain
