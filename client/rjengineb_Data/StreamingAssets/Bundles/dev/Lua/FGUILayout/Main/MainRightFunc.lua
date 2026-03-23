local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainRightFunc = class("MainRightFunc", BaseFGUILayout)

function MainRightFunc:Create()
	self._ui = FGUI:ui_delegate(self.component)

    
    FGUI:setOnClickEvent(self._ui.Button_guild, handler(self, self.OnOpenGuild))
    FGUI:setOnClickEvent(self._ui.Button_WuGong, handler(self, self.OnOpenWuGong))
    FGUI:setOnClickEvent(self._ui.Button_role, handler(self, self.OnOpenRole))
    FGUI:setOnClickEvent(self._ui.Button_FuBen, handler(self, self.OnOpenFuBen))
    FGUI:setOnClickEvent(self._ui.Button_QiangHua,handler(self, self.OnOpenQiangHua))
    FGUI:setOnClickEvent(self._ui.Button_BBG,handler(self, self.OnOpenBBG))
    FGUI:setOnClickEvent(self._ui.Button_WuXun,handler(self,self.ObOpenWuXun))
    FGUI:setOnClickEvent(self._ui.Button_fashion, handler(self, self.OnOpenChangeHairColor))

    FGUI:setOnClickEvent(self._ui.Button_test1, handler(self, self.OnTest1))
    FGUI:setOnClickEvent(self._ui.Button_test2, handler(self, self.OnTest2))
    FGUI:setOnClickEvent(self._ui.Button_test3, handler(self, self.OnTest3))

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
        FGUI:setVisible(self._ui.Button_FuBen, not FGUI:getVisible(self._ui.Button_FuBen))
        FGUI:setVisible(self._ui.Button_HuTi, not FGUI:getVisible(self._ui.Button_HuTi))
        FGUI:setVisible(self._ui.Button_QiangHua, not FGUI:getVisible(self._ui.Button_QiangHua))
        FGUI:setVisible(self._ui.Button_WuGong, not FGUI:getVisible(self._ui.Button_WuGong))
        FGUI:setVisible(self._ui.Button_WuXun, not FGUI:getVisible(self._ui.Button_WuXun))
        FGUI:setVisible(self._ui.Button_fashion, not FGUI:getVisible(self._ui.Button_fashion))
        FGUI:setVisible(self._ui.Button_forge, not FGUI:getVisible(self._ui.Button_forge))
        FGUI:setVisible(self._ui.Button_guild, not FGUI:getVisible(self._ui.Button_guild))
        FGUI:setVisible(self._ui.Button_transfer, not FGUI:getVisible(self._ui.Button_transfer))
        FGUI:setVisible(self._ui.Button_role, not FGUI:getVisible(self._ui.Button_role))
        FGUI:setVisible(self._ui.Button_BBG, not FGUI:getVisible(self._ui.Button_BBG))
        FGUI:setVisible(self._ui.Button_test1, not FGUI:getVisible(self._ui.Button_test1))
        FGUI:setVisible(self._ui.Button_test2, not FGUI:getVisible(self._ui.Button_test2))
        FGUI:setVisible(self._ui.Button_test3, not FGUI:getVisible(self._ui.Button_test3))
    end 
    SL:AddKeyboardEvent("KEY_F12", "MainRightFunc", ShowOrHideVisible)
end
-----------------------------------------------------------------------

function MainRightFunc:OnOpenGuild()
    FGUIFunction:OpenGuildAutoUI()
end

function MainRightFunc:OnOpenWuGong()
    FGUI:Open("Skill", "SkillFramePanel", 1)
end

function MainRightFunc:OnOpenRole()
    FGUI:Open("Bag","PlayerInfoPanel")
end

function MainRightFunc:OnOpenFuBen()
    FGUI:Open("ExChange","ExChangeRootPanel")
end

function MainRightFunc:OnOpenQiangHua()
    FGUI:Open("Recharge","RechargePanel")
end

function MainRightFunc:OnOpenBBG()
    -- 发送请求百宝阁数据
    SL:RequestGroupData(0)
end

function MainRightFunc:ObOpenWuXun()
    FGUI:Open("Auction","AuctionRootPanel")
end

-- 头发染色
function MainRightFunc:OnOpenChangeHairColor()
    FGUI:Open("Appearance", "HelmetColorPanel")
end

function MainRightFunc:OnTest1()
    SL:SendNetMsg(9999, 11, nil, nil, nil)
    SL:Print("9999,11")
end

function MainRightFunc:OnTest2()
    SL:SendNetMsg(9999,12, nil, nil, nil)
    SL:Print("9999,12")
end

function MainRightFunc:OnTest3()
    SL:SendNetMsg(9999,13, nil, nil, nil)
    SL:Print("9999,13")
end

-----------------------------------注册事件--------------------------------------
function MainRightFunc:RegisterEvent()
end

function MainRightFunc:RemoveEvent()
end


return MainRightFunc
