local SettingKeyFunc = require("FGUILayout/Setting_pc/SettingKeyFunc")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local PCMainQuick = class("PCMainQuick")

local MAX_QUICK_DATA = 3

function PCMainQuick:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self.saveKeys = {}
    for i = 1, MAX_QUICK_DATA do
        self.saveKeys[i] = "PCMainQuick" .. i .. "_" .. SL:GetValue("USER_ID")
    end

    self._quicks = {
        self._ui.QuickBox1,
        self._ui.QuickBox2,
        self._ui.QuickBox3,
        self._ui.QuickBox4,
        self._ui.QuickBox5,
        self._ui.QuickBox6,
        self._ui.QuickBox7,
        self._ui.QuickBox8,
        self._ui.QuickBox9,
        self._ui.QuickBox10,
    }
    self._quickBoxs = {}

    self._index = 1
    self._datas = {}
    self._data = nil

    self:InitQuickData()
    
    for index, quick in pairs(self._quicks) do
        local quickBox = FGUIFunction:BindClass(quick, "Main_pc/PCQuickBox")
        quickBox:Create(index)
        FGUI:setOnDropEvent(quick, handler(self, self.OnDragDrop, index))
        FGUI:setOnClickEvent(quick, handler(self, self.OnClickQuick, index))
        FGUI:setOnRightClickEvent(quick, handler(self, self.OnRightClickQuick, index))
        self._quickBoxs[index] = quickBox
    end

    FGUI:setOnClickEvent(self._ui.Button_quickUp, handler(self, self.OnUp))
    FGUI:setOnClickEvent(self._ui.Button_quickDown, handler(self, self.OnDown))

    FGUI:GTextField_setText(self._ui.Text_quickIndex, self._index)
end

function PCMainQuick:Enter()
	self:RegisterEvent()
    for index, quickBox in pairs(self._quickBoxs) do
        quickBox:Enter()
        self:UpdateQuickBox(index)
    end
    PCGameMain.RegisterQuickUseFunc(handler(self, self.OnKeyUse))
end

function PCMainQuick:Exit()
	self:RemoveEvent()
    for index, quickBox in pairs(self._quickBoxs) do
        quickBox:Exit()
    end
    PCGameMain.UnRegisterQuickUseFunc()
end

function PCMainQuick:Destroy()
    self._ui = nil
end



----------------------------------------------------------------------------

function PCMainQuick:InitQuickData()
    for i = 1, MAX_QUICK_DATA do
        local saveKey = self.saveKeys[i]
        local saveStr = SL:GetLocalString(saveKey) or ""
        local data = {}
	    if saveStr and saveStr ~= "" then
	    	data = SL:JsonDecode(saveStr)
	    end
        self._datas[i] = data
    end
    self._data = self._datas[self._index]
end

function PCMainQuick:SaveQuickData(index)
    local saveKey = self.saveKeys[index]
    if not saveKey then return end
    local data = self._datas[index]
    if not data then return end
    local str = SL:JsonEncode(data)
    SL:SetLocalString(saveKey, str)
end

function PCMainQuick:UpdateQuickBox(index)
    local quickBox = self._quickBoxs[index]
    if not quickBox then return end
    local data = self._data[index]
    if not data then
        quickBox:Clear()
    else
        if data.type == FGUIDefine.PCQuickType.Item then
            quickBox:SetItem(data.makeIndex, data.itemIndex)
        elseif data.type == FGUIDefine.PCQuickType.Skill then
            quickBox:SetSkill(data.id)
        end
    end
end

function PCMainQuick:OnDelayClickEnd()
    self.delayClick = false
end

function PCMainQuick:OnDragDrop(index, eventData)
    self.delayClick = true
    SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
    local sender = eventData.sender
    local sourceData = eventData.data
    if not sourceData then return end
    local data
    if sourceData.index then
        if sourceData.index == index then return end
        --交互数据位置
        local index1 = sourceData.index
        local index2 = index
        local data1 = self._data[index1]
        local data2 = self._data[index2]
        self._data[index1] = data2
        self._data[index2] = data1
        self:UpdateQuickBox(index1)
        self:UpdateQuickBox(index2)
        self:SaveQuickData(self._index)
    else
        if sourceData.type == FGUIDefine.PCQuickType.Item then
            --去重
            for k, v in pairs(self._data) do
                if v.makeIndex == sourceData.makeIndex then
                    self._data[k] = nil
                    self:UpdateQuickBox(k)
                end
            end
            data = {
                type = sourceData.type,
                itemIndex = sourceData.itemIndex,
                makeIndex = sourceData.makeIndex,
            }
        elseif sourceData.type == FGUIDefine.PCQuickType.Skill then
            --去重
            for k, v in pairs(self._data) do
                if v.id == sourceData.id then
                    self._data[k] = nil
                    self:UpdateQuickBox(k)
                end
            end
            data = {
                type = sourceData.type,
                id = sourceData.id,
            }
        end
        self._data[index] = data
        self:UpdateQuickBox(index)
        self:SaveQuickData(self._index)
    end
end

function PCMainQuick:OnUp()
    self._index = self._index - 1
    if self._index < 1 then
        self._index = MAX_QUICK_DATA
    end
    self._data = self._datas[self._index]
    for index, quick in pairs(self._quicks) do
        self:UpdateQuickBox(index)
    end
    FGUI:GTextField_setText(self._ui.Text_quickIndex, self._index)
end

function PCMainQuick:OnDown()
    self._index = self._index + 1
    if self._index > MAX_QUICK_DATA then
        self._index = 1
    end
    self._data = self._datas[self._index]
    for index, quick in pairs(self._quicks) do
        self:UpdateQuickBox(index)
    end
    FGUI:GTextField_setText(self._ui.Text_quickIndex, self._index)
end

function PCMainQuick:OnClickQuick(index, eventData)
    if self.delayClick then return end
    local touchId = FGUI:InputEvent_getTouchId(eventData)
    local data = self._data[index]
    if not data then return end
    local sourceData = {index = index}
    local quick = self._quicks[index]
    local icon
    if data.type == FGUIDefine.PCQuickType.Item then
        icon = ItemUtil:GetIconResPathByItemID(data.itemIndex)
    elseif data.type == FGUIDefine.PCQuickType.Skill then
        icon = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", data.id)
    else
        return
    end
    self.isDragging = true
    -- FGUI:setAlpha(quick, 0)
    FGUI:DragDropManager_startDrag(quick, "ui://Main_pc/QuickDragBox", sourceData, touchId, handler(self, self.OnDropEnd, index, true))
    local dragIcon = FGUI:DragDropManager_getDragAgent()
    local label = FGUI:GLoader_getComponent(dragIcon)
    FGUI:GLabel_setIcon(label, icon)
end

function PCMainQuick:OnDropEnd(index, obj)
    if not obj then
        self._data[index] = nil
        self:UpdateQuickBox(index)
        self:SaveQuickData(self._index)
    end
end


function PCMainQuick:OnRightClickQuick(index, eventData)
    if self.delayClick then return end
    local quickBox = self._quickBoxs[index]
    quickBox:Use()
end

function PCMainQuick:OnKeyUse(index)
    local quickBox = self._quickBoxs[index]
    if not quickBox then return end
    quickBox:Use()
end


-----------------------------------注册事件--------------------------------------
function PCMainQuick:RegisterEvent()

end

function PCMainQuick:RemoveEvent()

end


return PCMainQuick