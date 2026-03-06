local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainSUI = class("MainSUI", BaseFGUILayout)

function MainSUI:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.SUI)
end

function MainSUI:Enter()
	self:RegisterEvent()

    self:InitAdapt()

    
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootLT, self._ui.LT)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootRT, self._ui.RT)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootLB, self._ui.LB)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootRB, self._ui.RB)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootLM, self._ui.LM)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootTM, self._ui.TM)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootRM, self._ui.RM)
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootBM, self._ui.BM)
end

function MainSUI:Exit()
	self:RemoveEvent()

    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootLT)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootRT)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootLB)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootRB)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootLM)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootTM)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootRM)
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootBM)
end

function MainSUI:Destroy()
    self._ui = nil	
end

--------------------------------------------------------------------------------

function MainSUI:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end


-----------------------------------注册事件--------------------------------------
function MainSUI:RegisterEvent()

end

function MainSUI:RemoveEvent()

end


return MainSUI