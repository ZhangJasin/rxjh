local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ssplit = string.split

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainQuickUse = class("MainQuickUse", BaseFGUILayout)

local BOX_COUNT = 4
local SAVE_KEY = "QuickBar"

local ITEM_SIZE = 72
function MainQuickUse:Create()
    FGUI:setFairyBatching(self.component, true)
	self._ui = FGUI:ui_delegate(self.component)

    self._box1 = FGUIFunction:BindClass(self._ui.QuickUseBox1, "Main/QuickUseBox")
    self._box2 = FGUIFunction:BindClass(self._ui.QuickUseBox2, "Main/QuickUseBox")
    self._box3 = FGUIFunction:BindClass(self._ui.QuickUseBox3, "Main/QuickUseBox")
    self._box4 = FGUIFunction:BindClass(self._ui.QuickUseBox4, "Main/QuickUseBox")

    self._boxs = {self._box1, self._box2, self._box3, self._box4}
    self.idMaps = {}
    self.quickBarIds = {}

    self.selectIndex = nil
    self.selectItemDatas = {}

    for idx = 1, BOX_COUNT do
        local box = self._boxs[idx]
        box:Create(self, idx)
    end

    self:InitQuickBarData()
end

function MainQuickUse:Enter()
	self:RegisterEvent()

    for idx = 1, BOX_COUNT do
        local box = self._boxs[idx]
        box:Enter()
    end
end

function MainQuickUse:Exit()
	self:RemoveEvent()

    for idx = 1, BOX_COUNT do
        local box = self._boxs[idx]
        box:Exit()
    end
end

function MainQuickUse:Destroy()
    self._ui = nil

    for idx = 1, BOX_COUNT do
        local box = self._boxs[idx]
        box:Destroy()
    end
end


--------------------------------------------------------------------------------

function MainQuickUse:InitQuickBarData()
    local QuickBar1 = SL:GetValue("GAME_DATA", "QuickBar1") or ""
    local QuickBar2 = SL:GetValue("GAME_DATA", "QuickBar2") or ""
    local QuickBar3 = SL:GetValue("GAME_DATA", "QuickBar3") or ""
    local QuickBar4 = SL:GetValue("GAME_DATA", "QuickBar4") or ""
    local idStrs1 = ssplit(QuickBar1, "|")
    local idStrs2 = ssplit(QuickBar2, "|")
    local idStrs3 = ssplit(QuickBar3, "|")
    local idStrs4 = ssplit(QuickBar4, "|")


    local function setIdData(idStrs, index)
        local idMap = self.idMaps[index]
        if not idMap then
            idMap = {}
            self.idMaps[index] = idMap
        end
        for k, idStr in pairs(idStrs) do
            local id = tonumber(idStr)
            if id and not idMap[id] then
                idMap[id] = k
            end
        end
    end

    setIdData(idStrs1, 1)
    setIdData(idStrs2, 2)
    setIdData(idStrs3, 3)
    setIdData(idStrs4, 4)
    

    self:InitSaveData()
end

function MainQuickUse:InitSaveData()
    if not SL:GetValue("BAG_INIT") then return end
    local saveIdStr = SL:GetLocalString(SAVE_KEY) or ""
    local saveIdStrs = ssplit(saveIdStr, "|")
    -- 配置变更时校验移除
    for i = 1, BOX_COUNT do
        local id = tonumber(saveIdStrs[i]) or nil
        if id and not self.idMaps[i][id] then id = nil end
        self.quickBarIds[i] = id

        local box = self._boxs[i]
        box:SetItem(id)
    end
    -- dump(self.quickBarIds, "quickBarIds")
    ssrMessage:sendmsgEx("quickItem", "AttrData",self.quickBarIds)
end

function MainQuickUse:ShowSelect(index, x, y)
    if not index then return end
    self.selectIndex = index
    table.clear(self.selectItemDatas)
    local idMap = self.idMaps[index]
    local bagData = SL:GetValue("BAG_DATA")
    -- 道具数量不叠加
    -- for k, data in pairs(bagData) do
    --     if idMap[data.Index] then
    --         table.insert(self.selectItemDatas, data)
    --     end
    -- end
    -- 道具数量叠加
    local itemMap = {}
    local isCopyMap = {}
    for k, data in pairs(bagData) do
        local index = data.Index
        if idMap[data.Index] then
            local saveData = itemMap[index]
            if saveData then
                if not isCopyMap[index] then
                    isCopyMap[index] = true
                    --克隆个假道具数据
                    saveData = SL:CopyData(saveData)
                    itemMap[index] = saveData
                end
                --数量叠加
                saveData.OverLap = (saveData.OverLap or 1) + (data.OverLap or 1)
            else
                itemMap[index] = data
            end
        end
    end
    for k, itemData in pairs(itemMap) do
        table.insert(self.selectItemDatas, itemData)
    end
    -------------------------------------------------
    table.sort(self.selectItemDatas, function(a, b)
        local k1 = idMap[a.Index]
        local k2 = idMap[b.Index]
        return k1 < k2
    end)

    if not self.QuickUseSelect then
        self.QuickUseSelect = FGUI:CreateObject(self.component, "Main", "QuickUseSelect", false)
        self.selectUI = FGUI:ui_delegate(self.QuickUseSelect)
        FGUI:GList_setVirtual(self.selectUI.List_quick, true)
        FGUI:GList_itemRenderer(self.selectUI.List_quick, handler(self, self.OnItemRenderListQuick))
        FGUI:setOnClickEvent(self.selectUI.Graphic_mask, handler(self, self.OnHideSelect))
    end
    x, y = FGUI:WorldToLocal(self.component, x, y)
    FGUI:setSize(self.selectUI.Graphic_mask, SL:GetValue("SCREEN_WIDTH") * 2,  SL:GetValue("SCREEN_HEIGHT") * 2)
    FGUI:setVisible(self.QuickUseSelect, true)
    FGUI:setPosition(self.QuickUseSelect, x - 20, y + 20)

    local len = #self.selectItemDatas
    if len <= 0 then
        FGUI:GList_setNumItems(self.selectUI.List_quick, 0)
        FGUI:setVisible(self.selectUI.Text_empty, true)
    else
        FGUI:GList_setNumItems(self.selectUI.List_quick, len)
        FGUI:setVisible(self.selectUI.Text_empty, false)
    end
    --列表横向流动模式不能自适应最小宽度,需计算调整
    --因itemSize与编辑器默认item的size不同,不能使用GList_resizeToFit
    local columnGap = FGUI:GList_getColumnGap(self.selectUI.List_quick)
    local lineGap = FGUI:GList_getLineGap(self.selectUI.List_quick)

    local columnLen = math.max(1, math.min(5, len))
    local lineLen = math.ceil(len / 5)
    local width = math.max(ITEM_SIZE, columnLen * ITEM_SIZE + columnGap * (columnLen - 1))
    local height = math.max(ITEM_SIZE, lineLen * ITEM_SIZE + lineGap * (lineLen - 1))
    FGUI:setSize(self.selectUI.List_quick, width, height)
end

function MainQuickUse:OnHideSelect()
    if not self.QuickUseSelect then return end
    FGUI:setVisible(self.QuickUseSelect, false)

    self.selectIndex = nil
end

function MainQuickUse:OnItemRenderListQuick(index, item)
    local data = self.selectItemDatas[index + 1]
    if not data then return end
    FGUI:setSize(item, ITEM_SIZE, ITEM_SIZE)
    local itemShow = FGUIFunction:BindClass(item, "Item/ItemShow")
    itemShow:UpdateUIByData(data, {hideTip = true, clickCallback = function(eventData)
        local holdTime = FGUI:InputEvent_getHoldTime(eventData)
        if holdTime > 0.5 then return end
        local selectIndex = self.selectIndex
        self:OnHideSelect()
        if not selectIndex then return end
        local itemIndex = nil
        if self.quickBarIds[selectIndex] ~= data.Index then
            itemIndex = data.Index
        end  
        self:SetItemIndex(selectIndex, itemIndex)
        local box = self._boxs[selectIndex]
        if box then
            box:SetItem(itemIndex)
        end
    end})
    ItemUtil:SetLongPressOrClick(itemShow.component, nil, function()
        itemShow:ShowTips()
    end, 0.5)
end

function MainQuickUse:SetItemIndex(boxIndex, itemIndex)
    local curIndex = self.quickBarIds[boxIndex]
    if curIndex == itemIndex then return end
    self.quickBarIds[boxIndex] = itemIndex
    self:SaveQuickIds()
end

function MainQuickUse:SaveQuickIds()
    local str = ""
    for i = 1, BOX_COUNT do
        str = str .. (self.quickBarIds[i] or "") .. "|"
    end
    SL:SetLocalString(SAVE_KEY, str)
    -- dump(self.quickBarIds, "quickBarIds2")
    ssrMessage:sendmsgEx("quickItem", "AttrData",self.quickBarIds)
end

function MainQuickUse:OnItemInit()
    self:InitSaveData()
end


-----------------------------------注册事件--------------------------------------
function MainQuickUse:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_INIT, "MainQuickUse", handler(self, self.OnItemInit))
end

function MainQuickUse:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_INIT, "MainQuickUse")
end


return MainQuickUse