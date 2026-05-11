local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local compoundMain = class("compoundMain", BaseFGUILayout)
local compoundMainData = SL:RequireFile("FGUILayout/A_Compound/compoundMainData")

-- 一级列表按钮纹理
local GROUP1_BTN_TEXTURE_NORMAL = "ui://A_Compound/yjannh"  -- 灰色未选中背景
local GROUP1_BTN_TEXTURE_SELECTED = "ui://A_Compound/yjann"  -- 金色选中背景

function compoundMain:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._data = compoundMainData:getInstance()

    FGUI:SetCloseUIWhenClickOutside(self)

    -- 适配PC端UI - 参考转职界面的缩放
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then
        local screenW = SL:GetValue("SCREEN_WIDTH")
        local screenH = SL:GetValue("SCREEN_HEIGHT")
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end

    -- 关闭按钮 (n3)
    if self._ui.n3 then
        FGUI:setOnClickEvent(self._ui.n3, function()
            FGUI:Close("A_Compound", "compoundMain")
        end)
    end

    -- 一级列表 (n45 / group_1)
    if self._ui.n45 or self._ui.group_1 then
        local group1List = self._ui.n45 or self._ui.group_1
        print("[compoundMain] 一级列表控件绑定成功 - n45:", self._ui.n45 ~= nil, "group_1:", self._ui.group_1 ~= nil)
        
        FGUI:GList_addOnClickItemEvent(group1List, function(context)
            local childIdx = FGUI:GetChildIndex(group1List, context.data)
            local selectedIndex = FGUI:GList_childIndexToItemIndex(group1List, childIdx)
            local group1ListData = self._data:GetGroup1List()
            
            if group1ListData[selectedIndex + 1] then
                local selectedName = group1ListData[selectedIndex + 1]
                self._data:SelectGroup1(selectedName)
                
                -- 刷新一级列表选中状态和整个UI
                self:RefreshGroup1List()
                self:RefreshGroup2List()
                self:RefreshContent()
            end
        end)
    end

    self._group2List = self._ui.n37 or self._ui.group_2
    self._group3List = nil  -- 三级菜单列表（动态创建）
    self._currentOpenGroup2 = nil  -- 当前展开的二级菜单名称

    -- 二级+三级混合列表 (n37 / group_2)
    if self._group2List then
        -- 设置 itemProvider，根据数据类型返回不同的列表项样式
        FGUI:GList_itemProvider(self._group2List, handler(self, self._MixedItemProvider))

        FGUI:GList_addOnClickItemEvent(self._group2List, function(context)
            local childIdx = FGUI:GetChildIndex(self._group2List, context.data)
            local selectedIndex = FGUI:GList_childIndexToItemIndex(self._group2List, childIdx)

            local info = self:_getMixedItemInfo(selectedIndex)
            if not info then return end

            if info.type == "group" then
                -- 点击二级菜单标题，切换展开/折叠状态
                self:_toggleGroup2(info.group2Name)
            elseif info.type == "item" then
                -- 点击三级菜单项，选中物品
                self._data:SelectItem(info.index, info.itemData)
                self:RefreshGroup2List()
                self:RefreshContent()
            end
        end)
    end

    self:_initListRenderers()
    
    -- 合成按钮 (n55)
    if self._ui.n55 then
        FGUI:setOnClickEvent(self._ui.n55, function()
            self:_OnCompoundButtonClick()
        end)
    end
    
    -- 批量合成组件 (n57)
    self._n57Visible = false  -- 是否显示批量合成
    self._isBatchChecked = false  -- 批量合成checkbox是否勾选

    if self._ui.n57 then
        -- 默认隐藏
        FGUI:setVisible(self._ui.n57, false)

        -- 获取checkbox组件（n57是Button扩展组件，自身就是可点击的）
        FGUI:setOnClickEvent(self._ui.n57, function()
            -- 切换checkbox状态
            self._isBatchChecked = not self._isBatchChecked

            -- 通过控制器设置选中状态
            local btnController = FGUI:getController(self._ui.n57, "button")
            if btnController then
                FGUI:Controller_setSelectedIndex(btnController, self._isBatchChecked and 1 or 0)
            end
        end)
    end
end

-- 混合列表项 Provider
function compoundMain:_MixedItemProvider(index)
    local info = self:_getMixedItemInfo(index)
    local result = "ui://A_Compound/btn_hc2"

    if info then
        if info.type == "group" then
            result = "ui://A_Compound/btn_hc2"
        elseif info.type == "item" then
            result = "ui://A_Compound/btn_hc3"
        end
    end

    return result
end

function compoundMain:_initListRenderers()
    -- 一级列表渲染器 (n45 / group_1)
    if self._ui.n45 or self._ui.group_1 then
        local group1List = self._ui.n45 or self._ui.group_1
        FGUI:GList_itemRenderer(group1List, function(index, item)
            local group1ListData = self._data:GetGroup1List()
            local group1Name = group1ListData[index + 1] or ""

            -- 打印调试信息（只在第一次渲染时打印item结构）
            if index == 0 and not self._group1ItemDebugged then
                print("[compoundMain] 一级列表项结构调试:")
                -- 使用FGUI API获取子控件
                local childCount = FGUI:GetChildCount(item)
                print("[compoundMain]   子控件数量:", childCount)
                for i = 0, childCount - 1 do
                    local child = FGUI:GetChildAt(item, i)
                    if child then
                        local childName = child.name or "unknown"
                        print("[compoundMain]   子控件[" .. i .. "]:", childName)
                    end
                end
                self._group1ItemDebugged = true
            end

            -- btn_hc1 结构: n3 是按下状态文字(金色), n4 是默认状态文字(灰色)
            local n3 = FGUI:GetChild(item, "n3")
            local n4 = FGUI:GetChild(item, "n4")
            
            if n3 then
                FGUI:GTextField_setText(n3, group1Name)
            end
            if n4 then
                FGUI:GTextField_setText(n4, group1Name)
            end

            -- 选中状态控制：通过设置 button 控制器实现
            local currentGroup1 = self._data._currentGroup1 or ""
            local isSelected = currentGroup1 == group1Name

            local btnController = FGUI:getController(item, "button")
            if btnController then
                FGUI:Controller_setSelectedIndex(btnController, isSelected and 1 or 0)
            end
        end)
    end

    -- 二级+三级混合列表渲染器 (n37 / group_2)
    if self._group2List then
        FGUI:GList_itemRenderer(self._group2List, function(index, item)
            local info = self:_getMixedItemInfo(index)
            if not info then return end

            if info.type == "group" then
                -- 渲染二级菜单标题（使用 btn_hc2 样式）
                local group2Name = info.group2Name

                -- btn_hc2 结构: n1 是文字
                local n1 = FGUI:GetChild(item, "n1")
                if n1 then
                    FGUI:GTextField_setText(n1, group2Name)
                end

                -- 展开/折叠状态控制：通过设置 button 控制器实现
                local isOpen = self._data:IsGroup2Open(group2Name)
                local btnController = FGUI:getController(item, "button")
                if btnController then
                    FGUI:Controller_setSelectedIndex(btnController, isOpen and 1 or 0)
                end

            elseif info.type == "item" then
                -- 渲染三级菜单项（使用 btn_hc3 样式）
                local itemData = info.itemData
                local itemName = itemData and itemData.itemName or ""

                -- btn_hc3 结构: n1 默认文字(浅色), n3 选中文字(金色)
                local n1 = FGUI:GetChild(item, "n1")
                local n3 = FGUI:GetChild(item, "n3")

                if n1 then
                    FGUI:GTextField_setText(n1, itemName)
                end
                if n3 then
                    FGUI:GTextField_setText(n3, itemName)
                end

                -- 选中状态控制：当前选中的物品高亮
                local currentItem = self._data:GetCurrentItem()
                local isSelected = currentItem and currentItem.itemId == itemData.itemId

                local btnController = FGUI:getController(item, "button")
                if btnController then
                    FGUI:Controller_setSelectedIndex(btnController, isSelected and 1 or 0)
                end
            end
        end)
    end
end

function compoundMain:Enter(data)
    self:RefreshUI()
end

function compoundMain:Exit()
end

function compoundMain:Destroy()
    self._ui = nil
    self._group2List = nil
    self._group3List = nil
end

-- 刷新整个界面
function compoundMain:RefreshUI()
    self:RefreshGroup1List()
    self:RefreshGroup2List()
    self:RefreshContent()
end

-- 刷新一级列表
function compoundMain:RefreshGroup1List()
    local group1List = self._ui.n45 or self._ui.group_1
    if not group1List then
        print("[compoundMain] 警告: 一级列表控件未找到! n45和group_1都为nil")
        return
    end
    
    print("[compoundMain] 一级列表控件已找到:", group1List)

    local group1Data = self._data:GetGroup1List()
    print("[compoundMain] 一级列表数据:", #group1Data, "项", table.concat(group1Data, " | "))

    -- 先计算选中项索引
    local currentIndex = 0
    for i, g1 in ipairs(group1Data) do
        if g1 == self._data._currentGroup1 then
            currentIndex = i - 1
            break
        end
    end

    -- 设置列表数量（这会触发渲染器）
    FGUI:GList_setNumItems(group1List, #group1Data)

    -- 再设置选中项
    FGUI:GList_setSelectedIndex(group1List, currentIndex)
    print("[compoundMain] 一级列表刷新完成 - 设置数量:", #group1Data, "选中索引:", currentIndex)
end

-- ========================================
-- 混合列表辅助函数
-- ========================================

-- 根据index获取混合项信息（二级菜单标题或三级菜单项）
function compoundMain:_getMixedItemInfo(index)
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    local rowIdx = 0

    for i, group2Name in ipairs(group2List) do
        rowIdx = rowIdx + 1  -- 二级菜单标题行
        if rowIdx - 1 == index then
            return { type = "group", group2Name = group2Name }
        end

        -- 展开状态下的三级菜单项
        if self._data:IsGroup2Open(group2Name) then
            local itemList = self._data:GetItemList(self._data._currentGroup1, group2Name)
            for j, itemData in ipairs(itemList) do
                rowIdx = rowIdx + 1  -- 三级菜单项行
                if rowIdx - 1 == index then
                    return { type = "item", itemData = itemData, group2Name = group2Name, index = j }
                end
            end
        end
    end

    return nil
end

-- 切换二级菜单的展开/折叠状态
function compoundMain:_toggleGroup2(group2Name)
    self._data:ToggleGroup2Open(group2Name)
    self:RefreshGroup2List()
    self:RefreshContent()
end

-- 刷新二级+三级混合列表
function compoundMain:RefreshGroup2List()
    if not self._group2List then return end

    -- 计算总行数
    local totalRows = self:_calcMixedListTotalRows()

    -- 先清空列表，强制重新创建所有项
    FGUI:GList_removeChildrenToPool(self._group2List)
    FGUI:GList_setNumItems(self._group2List, 0)
    FGUI:GList_setNumItems(self._group2List, totalRows)
end

-- 计算混合列表总行数
function compoundMain:_calcMixedListTotalRows()
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    local totalRows = 0

    for i, group2Name in ipairs(group2List) do
        totalRows = totalRows + 1  -- 二级菜单标题行

        -- 只统计展开的二级菜单下的三级菜单项
        if self._data:IsGroup2Open(group2Name) then
            local itemList = self._data:GetItemList(self._data._currentGroup1, group2Name)
            totalRows = totalRows + #itemList
        end
    end

    return totalRows
end

-- 根据index获取混合项信息（二级菜单标题或三级菜单项）
function compoundMain:_getMixedItemInfo(index)
    local group2List = self._data:GetGroup2List(self._data._currentGroup1)
    local rowIdx = 0

    for i, group2Name in ipairs(group2List) do
        rowIdx = rowIdx + 1  -- 二级菜单标题行
        if rowIdx - 1 == index then
            return { type = "group", group2Name = group2Name }
        end

        -- 展开状态下的三级菜单项
        if self._data:IsGroup2Open(group2Name) then
            local itemList = self._data:GetItemList(self._data._currentGroup1, group2Name)
            for j, itemData in ipairs(itemList) do
                rowIdx = rowIdx + 1  -- 三级菜单项行
                if rowIdx - 1 == index then
                    return { type = "item", itemData = itemData, group2Name = group2Name, index = j }
                end
            end
        end
    end

    return nil
end

function compoundMain:RefreshContent()
    local item = self._data:GetCurrentItem()
    if not item then
        return
    end

    -- 刷新消耗道具显示 (n46)
    self:_RefreshPayItems(item.payItems)

    -- 刷新合成目标显示 (n47)
    self:_RefreshTargetItem(item)

    -- 刷新消耗货币显示 (n52)
    self:_RefreshPayCost(item.payCost)

    -- 刷新成功率显示 (n54)
    self:_RefreshSuccessRate(item)
end

-- 刷新消耗道具显示 (n46是list，每个item有n4 loader)
function compoundMain:_RefreshPayItems(payItems)
    if not self._ui.n46 then return end
    
    if not payItems or #payItems == 0 then
        FGUI:GList_setNumItems(self._ui.n46, 0)
        return
    end

    -- 先设置渲染器，再设置数量
    FGUI:GList_itemRenderer(self._ui.n46, function(index, item)
        local payItem = payItems[index + 1]
        if not payItem then return end
        
        local itemId = payItem.id or 0
        local count = payItem.count or 0
        
        -- 设置图标 (n4是loader)
        local iconLoader = FGUI:GetChild(item, "n4")
        if iconLoader then
            local itemData = SL:GetValue("ITEM_DATA", itemId)
            if itemData and itemData.Looks then
                local path = itemData.Looks >= 100000 and string.format("ui://ItemIcon/%d", itemData.Looks) or string.format("ui://ItemIcon/%06d", itemData.Looks)
                FGUI:GLoader_setUrl(iconLoader, path)
                -- 设置图标大小
                FGUI:setSize(iconLoader, 50, 50)
                
                -- 添加tips事件 - PC端hover，移动端点击
                local isPC = SL:GetValue("IS_PC_OPER_MODE")
                if isPC then
                    FGUI:setOnRollOverEvent(iconLoader, function()
                        FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
                    end)
                    FGUI:setOnRollOutEvent(iconLoader, function()
                        FGUIFunction:CloseItemTips()
                    end)
                else
                    FGUI:setOnClickEvent(iconLoader, function()
                        FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
                    end)
                end
            end
        end
        
        -- 设置名字x数量 (n1是名字，格式为"道具名称x数量")
        local n1 = FGUI:GetChild(item, "n1")
        if n1 then
            local itemName = "未知物品"
            local ItemConfig = SL:GetValue("ITEM_CONFIG")
            if ItemConfig and ItemConfig[itemId] then
                itemName = ItemConfig[itemId].Name or itemName
            end
            FGUI:GTextField_setText(n1, string.format("%sx%d", itemName, count))
        end
    end)
    
    -- 清空并重新设置数量，触发渲染
    FGUI:GList_removeChildrenToPool(self._ui.n46)
    FGUI:GList_setNumItems(self._ui.n46, 0)
    FGUI:GList_setNumItems(self._ui.n46, #payItems)
end

-- 刷新合成目标显示 (n47是component，n4是loader，n1是名字)
function compoundMain:_RefreshTargetItem(item)
    if not self._ui.n47 then return end
    
    if not item then return end

    -- 设置目标物品图标 (n4是loader)
    local iconLoader = FGUI:GetChild(self._ui.n47, "n4")
    if iconLoader then
        local itemId = item.itemId or 0
        local itemData = SL:GetValue("ITEM_DATA", itemId)
        if itemData and itemData.Looks then
            local path = itemData.Looks >= 100000 and string.format("ui://ItemIcon/%d", itemData.Looks) or string.format("ui://ItemIcon/%06d", itemData.Looks)
            FGUI:GLoader_setUrl(iconLoader, path)
            -- 设置图标大小
            FGUI:setSize(iconLoader, 50, 50)
            
            -- 添加tips事件 - PC端hover，移动端点击
            local isPC = SL:GetValue("IS_PC_OPER_MODE")
            if isPC then
                FGUI:setOnRollOverEvent(iconLoader, function()
                    FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
                end)
                FGUI:setOnRollOutEvent(iconLoader, function()
                    FGUIFunction:CloseItemTips()
                end)
            else
                FGUI:setOnClickEvent(iconLoader, function()
                    FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
                end)
            end
        end
    end

    -- 设置物品名称 (n1是名字)
    local n1 = FGUI:GetChild(self._ui.n47, "n1")
    if n1 then
        FGUI:GTextField_setText(n1, item.itemName or "未知物品")
    end

    -- 根据 isBatch 配置显示/隐藏批量合成组件
    if self._ui.n57 then
        local isBatch = item.isBatch or 0
        if isBatch > 1 then
            -- 显示批量合成组件
            FGUI:setVisible(self._ui.n57, true)
            self._n57Visible = true
            self._isBatchChecked = false  -- 重置checkbox状态

            -- 设置文本格式：批量合成%d次
            local titleText = FGUI:GetChild(self._ui.n57, "title")
            if titleText then
                FGUI:GTextField_setText(titleText, string.format("批量合成%d次", isBatch))
            end
        else
            -- 隐藏批量合成组件
            FGUI:setVisible(self._ui.n57, false)
            self._n57Visible = false
            self._isBatchChecked = false
        end
    end
end

-- 刷新消耗货币显示 (n52是component，n1是loader，n2是货币名)
function compoundMain:_RefreshPayCost(payCost)
    if not self._ui.n52 then return end
    
    if not payCost or #payCost == 0 then return end

    -- 先设置货币图标
    local iconLoader = FGUI:GetChild(self._ui.n52, "n1")
    if iconLoader and payCost[1] then
        local costType = payCost[1].id or 0
        local itemData = SL:GetValue("ITEM_DATA", costType)
        if itemData and itemData.Looks then
            local path = itemData.Looks >= 100000 and string.format("ui://ItemIcon/%d", itemData.Looks) or string.format("ui://ItemIcon/%06d", itemData.Looks)
            FGUI:GLoader_setUrl(iconLoader, path)
            -- 设置图标大小
            FGUI:setSize(iconLoader, 28, 28)
        end
    end

    -- 设置货币名称 (n2是货币名)
    local cost = payCost[1]
    if cost then
        local costType = cost.id or 0
        local amount = cost.count or 0

        local costTypeName = "未知货币"
        if costType == 1 then
            costTypeName = "银两"
        elseif costType == 2 then
            costTypeName = "元宝"
        end

        local n2 = FGUI:GetChild(self._ui.n52, "n2")
        if n2 then
            -- 显示格式：货币名 x数量
            FGUI:GTextField_setText(n2, string.format("%s x%d", costTypeName, amount))
        end
    end
end

-- 检查背包道具是否足够
-- @param payItems 所需道具列表
-- @param batchCount 批量次数（默认1）
function compoundMain:_CheckPayItems(payItems, batchCount)
    if not payItems or #payItems == 0 then
        return true
    end

    batchCount = batchCount or 1

    for i, payItem in ipairs(payItems) do
        local itemId = payItem.id or 0
        local needCount = (payItem.count or 0) * batchCount  -- 乘以批量次数

        -- 获取背包中该物品的数量（使用新的MetaValue API）
        local haveCount = tonumber(SL:GetMetaValue("ITEM_COUNT", itemId) or 0) or 0

        if haveCount < needCount then
            -- 获取道具名称（使用新的MetaValue API）
            local itemName = SL:GetMetaValue("ITEM_NAME", itemId) or "未知道具"
            SL:ShowSystemTips(string.format("%s 不足，需要 %d 个", itemName, needCount))
            return false
        end
    end

    return true
end

-- 检查货币是否足够
-- @param payCost 所需货币列表
-- @param batchCount 批量次数（默认1）
function compoundMain:_CheckPayCost(payCost, batchCount)
    if not payCost or #payCost == 0 then
        return true
    end

    batchCount = batchCount or 1

    for i, cost in ipairs(payCost) do
        local costType = cost.id or 0
        local needCount = (cost.count or 0) * batchCount  -- 乘以批量次数

        -- 获取玩家货币数量（使用新的MetaValue API）
        local haveCount = tonumber(SL:GetMetaValue("MONEY", costType) or 0) or 0
        local costTypeName = nil
        if costType == 1 then
            costTypeName = "银两"
        elseif costType == 2 then
            costTypeName = "元宝"
        end

        -- 如果是未知货币类型，直接阻止合成
        if not costTypeName then
            SL:ShowSystemTips(string.format("不支持的货币类型(ID:%d)", costType))
            return false
        end

        if haveCount < needCount then
            SL:ShowSystemTips(string.format("%s 不足，需要 %d 个", costTypeName, needCount))
            return false
        end
    end

    return true
end

-- 综合检查是否可以合成
function compoundMain:_CheckCanCompound()
    local item = self._data:GetCurrentItem()
    if not item then
        return false
    end

    -- 判断是否批量合成
    local isBatchParam = (self._n57Visible and self._isBatchChecked) and (item.isBatch or 0) or 0
    local batchCount = math.max(1, isBatchParam)  -- 批量次数，至少为1

    -- 检查道具
    if not self:_CheckPayItems(item.payItems, batchCount) then
        return false
    end

    -- 检查货币
    if not self:_CheckPayCost(item.payCost, batchCount) then
        return false
    end

    return true
end

-- 合成按钮点击事件
function compoundMain:_OnCompoundButtonClick()
    -- 节流控制：每秒最多执行1次
    local now = os.time() * 1000  -- 毫秒
    if self._lastCompoundTime and (now - self._lastCompoundTime) < 1000 then
        SL:ShowSystemTips("请勿频繁操作")
        return
    end

    local item = self._data:GetCurrentItem()
    if not item then
        SL:ShowSystemTips("未选中物品")
        return
    end

    if not self:_CheckCanCompound() then
        return
    end

    -- 更新最后请求时间
    self._lastCompoundTime = now

    -- 发送合成请求，添加 isBatch 参数
    local isBatchParam = (self._n57Visible and self._isBatchChecked) and (item.isBatch or 0) or 0
    self:_SendCompoundRequest(item.itemId, isBatchParam)
end

-- 发送合成网络请求
function compoundMain:_SendCompoundRequest(itemId, isBatchParam)
    -- 使用 ssrMessage:sendmsgEx 发送请求
    -- 格式: 模块名, 方法名, 参数数据
    ssrMessage:sendmsgEx("Compound", "compound", {itemId, isBatchParam or 0})
end
-- 刷新成功率显示 (n54是component，n2是唯一文本)
function compoundMain:_RefreshSuccessRate(item)
    if not self._ui.n54 then return end

    -- 默认100%
    local successRate = 100

    -- 如果物品配置中有成功率，使用配置中的值
    if item and item.successRate then
        successRate = tonumber(item.successRate) or 100
    end

    local n2 = FGUI:GetChild(self._ui.n54, "n2")
    if n2 then
        -- 显示格式：成功率100%
        FGUI:GTextField_setText(n2, string.format("成功率%.0f%%", successRate))
    end
end

-- ========================================
-- 公共辅助方法
-- ========================================

return compoundMain
