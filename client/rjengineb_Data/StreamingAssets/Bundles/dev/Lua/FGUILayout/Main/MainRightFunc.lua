local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainRightFunc = class("MainRightFunc", BaseFGUILayout)

function MainRightFunc:Create()
	self._ui = FGUI:ui_delegate(self.component)

    
    FGUI:setOnClickEvent(self._ui.Button_guild, handler(self, self.OnOpenGuild))
    FGUI:setOnClickEvent(self._ui.Button_WuGong, handler(self, self.OnOpenWuGong))
    FGUI:setOnClickEvent(self._ui.Button_role, handler(self, self.OnOpenRole))
    FGUI:setOnClickEvent(self._ui.Button_WuXun,handler(self,self.ObOpenWuXun))
    FGUI:setOnClickEvent(self._ui.Button_fashion, handler(self, self.OnOpenFashion))
    FGUI:setOnClickEvent(self._ui.Button_st, handler(self, self.OnOpenShiTu))
    FGUI:setOnClickEvent(self._ui.Button_ZuoQi, handler(self, self.OnOpenZuoQI))
    FGUI:setOnClickEvent(self._ui.Button_zz, handler(self, self.OnOpenZhuanZhi))

    self:InitFuncBtnsShow()
end

function MainRightFunc:Enter()
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootButton, self._ui.Node_attach)
end

function MainRightFunc:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootButton)
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
    FGUI:Open("Mount", "mountMain", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end
function MainRightFunc:OnOpenFashion()
    FGUI:Open("A_Fashion", "FashionSystemPanl", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end
function MainRightFunc:OnOpenGuild()
    FGUIFunction:OpenGuildAutoUI()
end

function MainRightFunc:OnOpenWuGong()
    FGUI:Open("Skill", "SkillFramePanel", 1)
end

function MainRightFunc:OnOpenRole()
    FGUI:Open("Bag","PlayerInfoPanel")
end
function MainRightFunc:OnOpenZhuanZhi()
    FGUI:Open("Transfer", "TransferPanel", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
end


-----------------------------------注册事件--------------------------------------
function MainRightFunc:RegisterEvent()
end

function MainRightFunc:RemoveEvent()
end


return MainRightFunc