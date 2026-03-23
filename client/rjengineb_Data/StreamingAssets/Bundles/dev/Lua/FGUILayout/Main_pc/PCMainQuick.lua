local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local PCMainQuick = class("PCMainQuick")
local PCGameMain = PCGameMain

local MAX_QUICK_MAX_PAGE = PCGameMain.MAX_QUICK_MAX_PAGE

function PCMainQuick:Create()
	self._ui = FGUI:ui_delegate(self.component)

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
    self._page = nil
    self._autoSetIndex = nil

    for index, quick in pairs(self._quicks) do
        local quickBox = FGUIFunction:BindClass(quick, "Main_pc/PCQuickBox")
        quickBox:Create(self, index)
        self._quickBoxs[index] = quickBox
    end

    FGUI:setOnClickEvent(self._ui.Button_quickUp, handler(self, self.OnUp))
    FGUI:setOnClickEvent(self._ui.Button_quickDown, handler(self, self.OnDown))
    FGUI:setOnClickEvent(self._ui("SkillAutoSet", "Button_auto"), handler(self, self.OnChangeAuto))

    FGUI:GButton_setChangeStateOnClick(self._ui("SkillAutoSet", "Button_auto"), false)
    FGUI:setVisible(self._ui.SkillAutoSet, false)
end

function PCMainQuick:Enter()
	self:RegisterEvent()
    self._page = PCGameMain.GetQuickPage()
    self:UpdatePage()
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

function PCMainQuick:UpdatePage()
    FGUI:GTextField_setText(self._ui.Text_quickIndex, self._page)
end

function PCMainQuick:UpdateQuickBox(index)
    local quickBox = self._quickBoxs[index]
    if not quickBox then return end
    local data = PCGameMain.GetQuickData(self._page, index)
    if not data then
        quickBox:SetEmpty()
    else
        if data.type == FGUIDefine.PCQuickType.Item then
            quickBox:SetItem(data.makeIndex, data.itemIndex)
        elseif data.type == FGUIDefine.PCQuickType.Skill then
            quickBox:SetSkill(data.id, data.auto)
        end
    end
end

function PCMainQuick:SetSkillAuto(index, auto)
    local data = PCGameMain.GetQuickData(self._page, index)
    if not data then return end
    if data.type ~= FGUIDefine.PCQuickType.Skill then return end
    if data.auto == auto then return end
    data.auto = auto
    PCGameMain.SetQuickData(self._page, index, data)
end

function PCMainQuick:OnDelayClickEnd()
    self.delayClick = false
end

function PCMainQuick:DragDrop(index, eventData)
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
        local data1 = PCGameMain.GetQuickData(self._page, index1)
        local data2 = PCGameMain.GetQuickData(self._page, index2)
        PCGameMain.SetQuickData(self._page, index1, data2)
        PCGameMain.SetQuickData(self._page, index2, data1)
    else
        if sourceData.type == FGUIDefine.PCQuickType.Item then
            data = {
                type = sourceData.type,
                itemIndex = sourceData.itemIndex,
                makeIndex = sourceData.makeIndex,
            }
        elseif sourceData.type == FGUIDefine.PCQuickType.Skill then
            data = {
                type = sourceData.type,
                id = sourceData.id,
                auto = false
            }
        end
        PCGameMain.SetQuickData(self._page, index, data)
    end
end

function PCMainQuick:OnUp()
    local page = self._page
    page = page - 1
    if page < 1 then
        page = MAX_QUICK_MAX_PAGE
    end
    PCGameMain.SetQuickPage(page)
end

function PCMainQuick:OnDown()
    local page = self._page
    page = page + 1
    if page > MAX_QUICK_MAX_PAGE then
        page = 1
    end
    PCGameMain.SetQuickPage(page)
end

function PCMainQuick:DragQuickItem(index, eventData)
    if self.delayClick then return end
    local touchId = FGUI:InputEvent_getTouchId(eventData)
    local data = PCGameMain.GetQuickData(self._page, index)
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
    FGUI:DragDropManager_startDrag(quick, "ui://Main_pc/QuickDragBox", sourceData, touchId, handler(self, self.OnDropEnd, index, true))
    local dragIcon = FGUI:DragDropManager_getDragAgent()
    local label = FGUI:GLoader_getComponent(dragIcon)
    FGUI:GLabel_setIcon(label, icon)
end

function PCMainQuick:OnChangeAuto()
    if not self._autoSetIndex then return end
    local isSelect = FGUI:GButton_getSelected(self._ui("SkillAutoSet", "Button_auto"))
    self:SetSkillAuto(self._autoSetIndex, not isSelect)
end

function PCMainQuick:ShowSkillAutoSet(index)
    if self._autoSetIndex == index then return end
    self._autoSetIndex = index
    local quick = self._quicks[index]
    if not quick then return end
    local data = PCGameMain.GetQuickData(self._page, index)
    if not data then return end
    FGUI:AddChild(quick, self._ui.SkillAutoSet)
    local w, h = FGUI:getSize(quick)
    FGUIFunction:SetSafePosition(self._ui.SkillAutoSet, w / 2, 0)
    self:UpdateSkillAuto()
end

function PCMainQuick:HideSkillAutoSet(index)
    if self._autoSetIndex ~= index then return end
    self._autoSetIndex = nil
    self:UpdateSkillAuto()
end

function PCMainQuick:UpdateSkillAuto()
    local show = self._autoSetIndex ~= nil
    if show then
        local data = PCGameMain.GetQuickData(self._page, self._autoSetIndex)
        if (not data) or 
            data.type ~= FGUIDefine.PCQuickType.Skill or
            (not SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", data.id, 1)) then
            show = false
        else
            FGUI:GButton_setSelected(self._ui("SkillAutoSet", "Button_auto"), data.auto or false)
        end
    end
    FGUI:setVisible(self._ui.SkillAutoSet, show)
end

function PCMainQuick:OnDropEnd(index, obj)
    if not obj then
        PCGameMain.SetQuickData(self._page, index, nil)
        self:UpdateQuickBox(index)
    end
end

function PCMainQuick:OnKeyUse(index)
    local quickBox = self._quickBoxs[index]
    if not quickBox then return end
    quickBox:Use()
end

function PCMainQuick:OnQuickDataChange(page, index, data)
    self:UpdateQuickBox(index)
    self:UpdateSkillAuto()
end

function PCMainQuick:OnPageChange(page)
    if page == self._page then return end
    self._page = page
    self:UpdatePage()
    for index, quick in pairs(self._quicks) do
        self:UpdateQuickBox(index)
    end
    self:UpdateSkillAuto()
end

-----------------------------------注册事件--------------------------------------
function PCMainQuick:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_PC_QUICK_PAGE_CHANGE, "PCMainQuick", handler(self, self.OnPageChange))
    SL:RegisterLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, "PCMainQuick", handler(self, self.OnQuickDataChange))
end

function PCMainQuick:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_PC_QUICK_PAGE_CHANGE, "PCMainQuick")
    SL:UnRegisterLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, "PCMainQuick")
end


return PCMainQuick