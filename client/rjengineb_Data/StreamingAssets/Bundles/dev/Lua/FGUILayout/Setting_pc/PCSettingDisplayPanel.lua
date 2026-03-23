local PCSettingPageBase = requireFGUILayout("Setting_pc/PCSettingPageBase")
local PCSettingDisplayPanel = class("PCSettingDisplayPanel", PCSettingPageBase)

function PCSettingDisplayPanel:Enter()
    PCSettingDisplayPanel.super.Enter(self)
    if not self.component then
        release_log_traceback("ERROR PCSettingDisplayPanel component is nil.")
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
    self:RefreshPanel()
    SL:ComponentAttach(SLDefine.SUIComponentTable.SettingPickUp, self._ui.Node_attach)
end

function PCSettingDisplayPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.SettingPickUp)

    PCSettingDisplayPanel.super.Exit(self)
end

function PCSettingDisplayPanel.Create()
    return PCSettingDisplayPanel.new()
end

function PCSettingDisplayPanel:InitData()
    self.infoTable = {{ -- 基础控制
        comName = "enBaseCtrl",
        key = "SETTING_BASE_EN",
        child = {{ -- 怪物名显示
            comName = "enMonsterName",
            key = "SETTING_MONSTER_NAME_EN"
        }, { -- 残血提醒
            comName = "enLowHpWarning",
            key = "SETTING_LOW_HP_WARNING_EN"
        }, { -- 屏蔽震屏
            comName = "enScreenShake",
            key = "SETTING_SCREEN_SHAKE_EN"
        }, { -- 屏蔽摊位
            comName = "enStalls",
            key = "SETTING_STALLS_EN"
        }, { -- 屏蔽怪物
            comName = "enMonster",
            key = "SETTING_MONSTER_EN"
        }, { -- 屏蔽血条
            comName = "enHpHud",
            key = "SETTING_HEALTH_BAR_EN"
        }, { -- 属性飘字开关
            comName = "enPropertyFloatWord",
            key = "SETTING_PROPERTY_TIPS_EN"
        }}
    }, { -- 自身控制
        comName = "enSelfCtrl",
        key = "SETTING_SELF_EN",
        child = {{ -- 屏蔽自身名字
            comName = "enSelfName",
            key = "SETTING_SELF_NAME_EN"
        }, { -- 屏蔽自身称号
            comName = "enSelfTitle",
            key = "SETTING_SELF_TITLE_EN"
        }, { -- 屏蔽自身特效
            comName = "enSelfFix",
            key = "SETTING_SELF_FIX_EN"
        }, { -- 屏蔽自身技能
            comName = "enSelfSkill",
            key = "SETTING_SELF_SKILL_EN"
        }, { -- 屏蔽自身宝宝
            comName = "enSelfCompanions",
            key = "SETTING_SELF_COMPANIONS_EN"
        }}
    }, { -- 友方控制
        comName = "enFriendCtrl",
        key = "SETTING_FRND_EN",
        child = {{ -- 屏蔽友方名字
            comName = "enFrndName",
            key = "SETTING_FRND_NAME_EN"
        }, { -- 屏蔽友方称号
            comName = "enFrndTitle",
            key = "SETTING_FRND_TITLE_EN"
        }, { -- 屏蔽友方特效
            comName = "enFrndfFix",
            key = "SETTING_FRND_FIX_EN"
        }, { -- 屏蔽友方技能
            comName = "enFrndSkill",
            key = "SETTING_FRND_SKILL_EN"
        }, { -- 屏蔽友方人物
            comName = "enFrndCharacter",
            key = "SETTING_FRND_CHARACTER_EN"
        }, { -- 屏蔽友方宝宝
            comName = "enFrndCompanions",
            key = "SETTING_FRND_COMPANIONS_EN"
        }}
    }, { -- 敌方控制
        comName = "enEnemyCtrl",
        key = "SETTING_ENEMY_EN",
        child = {{ -- 屏蔽敌方名字
            comName = "enEnemyName",
            key = "SETTING_ENEMY_NAME_EN"
        }, { -- 屏蔽敌方称号
            comName = "enEnemyTitle",
            key = "SETTING_ENEMY_TITLE_EN"
        }, { -- 屏蔽敌方特效
            comName = "enEnemyFix",
            key = "SETTING_ENEMY_FIX_EN"
        }, { -- 屏蔽敌方技能
            comName = "enEnemySkill",
            key = "SETTING_ENEMY_SKILL_EN"
        }, { -- 屏蔽敌方宝宝
            comName = "enEnemyCompanions",
            key = "SETTING_ENEMY_COMPANIONS_EN"
        }, { -- 怪物血量显示
            comName = "enEnemyHP",
            key = "SETTING_ENEMY_HP_VALUE_EN"
        }, { -- 怪物百分比血量显示
            comName = "enEnemyPercentHP",
            key = "SETTING_ENEMT_HP_SHOW_AS_PERCENTAGE_EN"
        }}
    }}
end

function PCSettingDisplayPanel:InitEvent()
    for group, info in ipairs(self.infoTable) do
        self:InitItem(info, group, 0)
        if info.child then
            for idx, v in ipairs(info.child) do
                self:InitItem(v, group, idx)
            end
        end
    end

    FGUI:setOnClickEvent(self._ui.enEnemyCtrlHelp, handler(self, self.OnClickEnemyCtrlHelpBtn))
    FGUI:GButton_setOnChangedCallback(self._ui.tog_damage1, handler(self, self.OnDamageStyle1Changed))
    FGUI:GButton_setOnChangedCallback(self._ui.tog_damage2, handler(self, self.OnDamageStyle2Changed))
    FGUI:GButton_setOnChangedCallback(self._ui.tog_quickWindow, handler(self, self.OnQuickWindowChanged))
end

function PCSettingDisplayPanel:RefreshPanel()
    local style = SL:GetValue("SETTING_DAMAGE_STYLE")
    FGUI:GButton_setSelected(self._ui.tog_damage1, style == 2)
    FGUI:GButton_setSelected(self._ui.tog_damage2, style == 1)

    FGUI:GButton_setSelected(self._ui.tog_quickWindow, SL:GetValue("SETTING_QUICKWINDOW_NOT_REPEATED_SHOW"))
end

function PCSettingDisplayPanel:InitItem(info, group, idx)
    local tog = FGUI:GetChild(self._ui[info.comName], "tog")
    local enable = SL:GetValue(info.key)
    FGUI:SetIntData(tog, self:GetTogId(group, idx))
    self:ResetSwitch(tog, enable)
    FGUI:GButton_setOnChangedCallback(tog, handler(self, self.OnSwtichChanged))
end

function PCSettingDisplayPanel:OnSwtichChanged(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local id = FGUI:GetIntData(eventData.sender)
    local group, idx = self:GetInfo(id)
    local info = nil
    if idx == 0 then
        info = self.infoTable[group]
    else
        info = self.infoTable[group].child[idx]
    end
    local enable = FGUI:GButton_getSelected(eventData.sender)
    SL:SetValue(info.key, enable)
    if idx == 0 then
        for idx, v in ipairs(info.child) do
            local tog = FGUI:GetChild(self._ui[v.comName], "tog")
            SL:SetValue(v.key, enable)
            self:PlaySwitchTransition(tog, enable)
        end
    end
end

function PCSettingDisplayPanel:OnDamageStyle1Changed(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local enable = FGUI:GButton_getSelected(eventData.sender)
    if not enable then
        FGUI:GButton_setSelected(eventData.sender, true)    
        return
    end
    SL:SetValue("SETTING_DAMAGE_STYLE", 2)
    FGUI:GButton_setSelected(self._ui.tog_damage2, not enable)
end

function PCSettingDisplayPanel:OnDamageStyle2Changed(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local enable = FGUI:GButton_getSelected(eventData.sender)
    if not enable then
        FGUI:GButton_setSelected(eventData.sender, true)    
        return
    end
    SL:SetValue("SETTING_DAMAGE_STYLE", 1)
    FGUI:GButton_setSelected(self._ui.tog_damage1, not enable)
end

function PCSettingDisplayPanel:OnQuickWindowChanged(context)
    local enable = FGUI:GButton_getSelected(self._ui.tog_quickWindow)
    SL:SetValue("SETTING_QUICKWINDOW_NOT_REPEATED_SHOW", enable)
end

function PCSettingDisplayPanel:GetTogId(group, idx)
    return group * 1000 + idx
end

function PCSettingDisplayPanel:GetInfo(id)
    local idx = id % 1000
    local group = math.floor(id / 1000)
    return group, idx
end

function PCSettingDisplayPanel:OnClickEnemyCtrlHelpBtn(context)
    local data = {}
    data.title = GET_STRING(80000511)
    data.str = GET_STRING(80000512)
    SL:OpenCommonHelpDialog(data)
end

function PCSettingDisplayPanel:PlaySwitchTransition(widget, enable)
    if FGUI:GButton_getSelected(widget) == enable then
        return
    end
    local transition = FGUI:GetTransition(widget, (enable == true) and "open" or "close")
    FGUI:Transition_play(transition)
    FGUI:GButton_setSelected(widget, enable)
end

function PCSettingDisplayPanel:ResetSwitch(widget, enable)
    if FGUI:GButton_getSelected(widget) == enable then
        return
    end
    local transition = FGUI:GetTransition(widget, (enable == true) and "open" or "close")
    local time = FGUI:Transition_getTotalDuration(transition)
    FGUI:Transition_play(transition, nil, nil, nil, time)
    FGUI:GButton_setSelected(widget, enable)
end
return PCSettingDisplayPanel
