local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainRightFunc = class("MainRightFunc", BaseFGUILayout)

-- 布局参数：从右往左，从上到下，每列4个控件
local LAYOUT_START_X = 1686
local LAYOUT_START_Y = 426
local LAYOUT_COL_WIDTH = 73   -- 列宽（x方向间隔）
local LAYOUT_ROW_HEIGHT = 77  -- 行高（y方向间隔）
local LAYOUT_ROWS_PER_COL = 4 -- 每列行数

function MainRightFunc:Create()
    self._ui = FGUI:ui_delegate(self.component)

    FGUI:setOnClickEvent(self._ui.Button_guild, handler(self, self.OnOpenGuild))
    FGUI:setOnClickEvent(self._ui.Button_WuGong, handler(self, self.OnOpenWuGong))
    FGUI:setOnClickEvent(self._ui.Button_role, handler(self, self.OnOpenRole))
    FGUI:setOnClickEvent(self._ui.Button_WuXun, handler(self, self.ObOpenWuXun))
    FGUI:setOnClickEvent(self._ui.Button_fashion, handler(self, self.OnOpenFashion))
    FGUI:setOnClickEvent(self._ui.Button_st, handler(self, self.OnOpenShiTu))
    FGUI:setOnClickEvent(self._ui.Button_ZuoQi, handler(self, self.OnOpenZuoQI))
    FGUI:setOnClickEvent(self._ui.Button_zz, handler(self, self.OnOpenZhuanZhi))
    FGUI:setOnClickEvent(self._ui.Button_zbtj, handler(self, self.OnClickZbtj))
    FGUI:setOnClickEvent(self._ui.Button_bagua, handler(self, self.OnOpenBagua))

    -- 初始化按钮配置（使用实际的按钮对象）
    self._buttonConfig = {
        { btn = self._ui.Button_role,    level = 0 },
        { btn = self._ui.Button_WuXun,   level = 0 },
        { btn = self._ui.Button_fashion, level = 0 },
        { btn = self._ui.Button_st,      level = 0 },
        { btn = self._ui.Button_WuGong,  level = 10 },
        { btn = self._ui.Button_zz,      level = 10 },
        { btn = self._ui.Button_ZuoQi,   level = 20 },
        { btn = self._ui.Button_guild,   level = 25 },
        { btn = self._ui.Button_bagua,   level = 0 },
        { btn = self._ui.Button_zbtj,    level = 35 },
    }

    self:InitFuncBtnsShow()

    -- 初始化按钮位置（只执行一次）
    self:InitButtonPositions()
end

-- 初始化按钮位置（在Create中只执行一次）
function MainRightFunc:InitButtonPositions()
    local visibleIndex = 0

    for _, config in ipairs(self._buttonConfig) do
        local btn = config.btn
        if btn then
            -- 计算位置：从右往左，从上到下，每列4个
            local col = math.floor(visibleIndex / LAYOUT_ROWS_PER_COL) -- 0 = 右列, 1 = 左列
            local row = visibleIndex % LAYOUT_ROWS_PER_COL             -- 0-3行
            local x = LAYOUT_START_X - col * LAYOUT_COL_WIDTH
            local y = LAYOUT_START_Y + row * LAYOUT_ROW_HEIGHT

            FGUI:setPosition(btn, x, y)
            visibleIndex = visibleIndex + 1
            print("InitButtonPosition:", btn, "at", x, y)
        end
    end
end

-- 根据等级更新按钮显示（只控制visible，不修改位置）
function MainRightFunc:UpdateFuncBtnsByLevel()
    local playerLevel = SL:GetValue("LEVEL") or 1
    print("UpdateFuncBtnsByLevel playerLevel=", playerLevel)

    for _, config in ipairs(self._buttonConfig) do
        local btn = config.btn
        if btn then
            local isVisible = playerLevel >= config.level
            print("Button isVisible=", isVisible)
            FGUI:setVisible(btn, isVisible)
        end
    end
end

function MainRightFunc:Enter()
    print("MainRightFunc:Enter()")
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootButton, self._ui.Node_attach)
    self:RegisterEvent()
    -- 延迟更新，确保玩家数据已就绪
    SL:ScheduleOnce(handler(self, self.UpdateFuncBtnsByLevel), 0.5)
end

function MainRightFunc:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootButton)
    self:RemoveEvent()
end

function MainRightFunc:Destroy()
    self._ui = nil
end

function MainRightFunc:InitFuncBtnsShow()
    if not SL._DEBUG then
        return
    end

    if SL:GetValue("IS_PC_OPER_MODE") then
        return
    end

    local function ShowOrHideVisible()
        FGUI:setVisible(self._ui.Button_WuGong, not FGUI:getVisible(self._ui.Button_WuGong))
        FGUI:setVisible(self._ui.Button_WuXun, not FGUI:getVisible(self._ui.Button_WuXun))
        FGUI:setVisible(self._ui.Button_fashion, not FGUI:getVisible(self._ui.Button_fashion))
        FGUI:setVisible(self._ui.Button_guild, not FGUI:getVisible(self._ui.Button_guild))
        FGUI:setVisible(self._ui.Button_role, not FGUI:getVisible(self._ui.Button_role))
        FGUI:setVisible(self._ui.Button_bagua, not FGUI:getVisible(self._ui.Button_bagua))
    end
    SL:AddKeyboardEvent("KEY_F12", "MainRightFunc", ShowOrHideVisible)
end

-----------------------------------------------------------------------
function MainRightFunc:ObOpenWuXun()
    FGUI:Open("A_WuXun", "WuXunPanl", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

function MainRightFunc:OnOpenShiTu()
    FGUI:Open("MentorShip", "MentorShipPanel", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

function MainRightFunc:OnOpenZuoQI()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 20 then
        return SL:ShowSystemTips("人物20级解锁灵兽")
    end
    FGUI:Open("Mount", "mountMain", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

function MainRightFunc:OnOpenFashion()
    FGUI:Open("A_Fashion", "FashionSystemPanl", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

function MainRightFunc:OnOpenGuild()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 25 then
        return SL:ShowSystemTips("人物25级解锁门派")
    end
    FGUIFunction:OpenGuildAutoUI()
end

function MainRightFunc:OnOpenWuGong()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 10 then
        return SL:ShowSystemTips("人物10级解锁功法")
    end
    FGUI:Open("Skill", "SkillFramePanel", 1)
end

function MainRightFunc:OnOpenRole()
    FGUI:Open("Bag", "PlayerInfoPanel")
end

function MainRightFunc:OnOpenZhuanZhi()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 10 then
        return SL:ShowSystemTips("人物10级解锁转职")
    end
    FGUI:Open("Transfer", "TransferPanel", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

function MainRightFunc:OnClickZbtj()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 35 then
        return SL:ShowSystemTips("人物35级解锁图鉴")
    end
    FGUI:Open("Z_Jasin", "equipCollect", {}, FGUI_LAYER.NORMAL,
        { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/zbtj/equipCollect" })
end

function MainRightFunc:OnOpenBagua()
    FGUI:Open("A_Compound", "compoundMain", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end

-----------------------------------注册事件--------------------------------------
function MainRightFunc:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainRightFunc", handler(self, self.OnLevelUp))
end

function MainRightFunc:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainRightFunc")
end

function MainRightFunc:OnLevelUp()
    self:UpdateFuncBtnsByLevel()
end

return MainRightFunc
