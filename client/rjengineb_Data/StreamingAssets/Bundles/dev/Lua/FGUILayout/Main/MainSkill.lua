local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainSkill = class("MainSkill", BaseFGUILayout)

local MIN_SLOT = 0
local MAX_SLOT = 7

function MainSkill:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self._skillMap = {} -- key:     SkillId
    self._keyMap = {}   -- skillId: key
    self._skillCells = {}
    self._imageCds = {}

    self._normalID = nil    --普攻id

    self._nearActorMap = {}
    self._ignoreList = {}

    FGUI:setOnClickEvent(self._ui.Button_target, handler(self, self.OnFindTarget))
    
    for i = MIN_SLOT, MAX_SLOT do
        local btn = self._ui["Button_skill" .. i]
        FGUI:setOnClickEvent(btn, handler(self, self["OnSkill" .. i]))
        local imgCd = FGUI:getChildByName(btn, "Image_cd")
        self._imageCds[i] = imgCd
        FGUI:GImage_setFillAmount(imgCd, 0)
        FGUI:setVisible(imgCd, false)  
    end
    FGUI:setOnTouchEvent(self._ui.Button_skillBase, handler(self, self.OnSkillBaseTouchBegin), nil, handler(self, self.OnSkillBaseTouchEnd))
    FGUI:setVisible(self._ui.Button_skill0, false)

    FGUI:setTouchEnabled(self._ui.TouchArea_monster, false)
    FGUI:setTouchEnabled(self._ui.TouchArea_player, false)

    FGUI:setOnDropEvent(self._ui.TouchArea_monster, handler(self, self.OnFindNearMonster))
    FGUI:setOnDropEvent(self._ui.TouchArea_player, handler(self, self.OnFindNearPlayer))
end

function MainSkill:Enter()
	self:RegisterEvent()
    if next(self._nearActorMap) then
        self:RegisterClearActorMap()
    end
    self:InitSkills()
end

function MainSkill:Exit()
	self:RemoveEvent()
    self:UnRegisterClearActorMap()
end

function MainSkill:Destroy()
    self._ui = nil	
end


--------------------------------------索敌----------------------------------------

function MainSkill:OnFindTarget()
    FGUIFunction:SwitchPanel("Main","MainFindTarget", nil, FGUI_LAYER.BG)
end


function MainSkill:OnSkillBaseTouchBegin(eventData)
    local touchId = FGUI:InputEvent_getTouchId(eventData)
    FGUI:DragDropManager_startDrag(self._ui.Button_skillBase, "", nil, touchId)
    FGUI:setTouchEnabled(self._ui.TouchArea_monster, true)
    FGUI:setTouchEnabled(self._ui.TouchArea_player, true)
end

function MainSkill:OnSkillBaseTouchEnd()
    self:OnSkill(0)
    FGUI:setTouchEnabled(self._ui.TouchArea_monster, false)
    FGUI:setTouchEnabled(self._ui.TouchArea_player, false)
end

function MainSkill:OnFindNearMonster()
    local root = FGUI:GetParent(self.component)
    local transition = FGUI:GetTransition(root, "TrigNearMonster")
    FGUI:Transition_play(transition)
    local actorList, count = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST")
    self:FindNearestEnemy(actorList, count, false)
end

function MainSkill:OnFindNearPlayer()
    local root = FGUI:GetParent(self.component)
    local transition = FGUI:GetTransition(root, "TrigNearPlayer")
    FGUI:Transition_play(transition)
    local actorList, count = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    self:FindNearestEnemy(actorList, count, false)
end

function MainSkill:FindNearestEnemy(actorList, count, isFor)
    local actorMap = self._nearActorMap
    local ignoreList = self._ignoreList
    local nearestActorId = nil
    local range = SL:GetValue("SETTING_AUTO_FIGHT_RANGE") or 9
    local nearestDis = range ^ 2
    local myUid = SL:GetValue("USER_ID")
    local playerX = SL:GetValue("ACTOR_POSITION_X", myUid)
    local playerZ = SL:GetValue("ACTOR_POSITION_Z", myUid)
    local targetId = SL:GetValue("SELECT_TARGET_ID")
    local ignoreCount = 0
    if targetId then
        --过滤当前目标
        actorMap[targetId] = true
    end
    for i = 1, count do
        local actorId = actorList[i]
        if not actorMap[actorId] then
            if SL:GetValue("ACTOR_IS_ENEMY", actorId)
                and not SL:GetValue("ACTOR_IS_DIE", actorId) then
                local x = SL:GetValue("ACTOR_POSITION_X", actorId)
                local z = SL:GetValue("ACTOR_POSITION_Z", actorId)
                local dis = (playerX - x) ^ 2 + (playerZ - z) ^ 2
                if dis < nearestDis then
                    nearestDis = dis
                    nearestActorId = actorId
                end
            end
        else
            ignoreCount = ignoreCount + 1
            ignoreList[ignoreCount] = actorId
        end
    end
    if nearestActorId then
        actorMap[nearestActorId] = true
        SL:SetValue("SELECT_TARGET_ID", nearestActorId)
    elseif ignoreCount > 0 and not isFor then
        -- 目标被全部过滤,清理重新寻找
        table.clear(actorMap)
        self:FindNearestEnemy(ignoreList, ignoreCount, true)
        table.clear(ignoreList)
    end
    if not isFor then
        if next(actorMap) then
            self:RegisterClearActorMap()
        else
            self:UnRegisterClearActorMap()
        end
    end
end

function MainSkill:OnActorOutOfView(actorId)
    self._nearActorMap[actorId] = nil
end

function MainSkill:OnChangeMap()
    table.clear(self._nearActorMap)
end

function MainSkill:RegisterClearActorMap()
    if self.isRegisterClear then return end
    self.isRegisterClear = true
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainSkill", handler(self, self.OnChangeMap))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainSkill", handler(self, self.OnActorOutOfView))
end

function MainSkill:UnRegisterClearActorMap()
    if not self.isRegisterClear then return end
    self.isRegisterClear = false
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainSkill")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainSkill")
end



------------------------------------Skill---------------------------------------

function MainSkill:OnSkill0() self:OnSkill(0) end
function MainSkill:OnSkill1() self:OnSkill(1) end
function MainSkill:OnSkill2() self:OnSkill(2) end
function MainSkill:OnSkill3() self:OnSkill(3) end
function MainSkill:OnSkill4() self:OnSkill(4) end
function MainSkill:OnSkill5() self:OnSkill(5) end
function MainSkill:OnSkill6() self:OnSkill(6) end
function MainSkill:OnSkill7() self:OnSkill(7) end

function MainSkill:OnSkill(key)
    local skillId = self._skillMap[key]
    if (not skillId) and key ~= MIN_SLOT then
        FGUI:Open("Skill", "SkillFramePanel", 1)
        return
    end
    self:LaunchSkill(skillId)
end

function MainSkill:InitSkills()
    local skills = SL:GetValue("SKILL_ALL_DATA")
    local scheme = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    for id, data in pairs(skills) do
        local isNormal = SL:GetValue("SKILL_CHECK_IS_ATTACK", data.SkillId)
        if isNormal then
            self._normalID = data.SkillId
            self:CheckNormalSkill()
        end
        
        local skillKey = data.Key and data.Key[scheme] 
        if skillKey and skillKey >= MIN_SLOT and skillKey <= MAX_SLOT then 
            self:UpdateSkill(skillKey, id)
        end
    end
end

-- 检查0号位无技能就设置普攻
function MainSkill:CheckNormalSkill()
    if not self._normalID then return end
    if self._skillMap[MIN_SLOT] then return end
    self:UpdateSkill(MIN_SLOT, self._normalID)
end

function MainSkill:UpdateSkill(key, skillId)
    if skillId then
        self:UpdateSkillCD(skillId, 0, 0)
        local curKey = self._keyMap[skillId]
        if curKey then
            self:UpdateSkill(curKey, nil)
        end
        self._keyMap[skillId] = key
    end
    if key then
        local curSkillId = self._skillMap[key]
        if curSkillId then
            self:UpdateSkillCD(curSkillId, 0, 0)
            self._keyMap[curSkillId] = nil
        end
        self._skillMap[key] = skillId
    end
    if not key then return end
    if key < MIN_SLOT or key > MAX_SLOT then return end
    if key == MIN_SLOT then
        if not skillId or SL:GetValue("SKILL_CHECK_IS_ATTACK", skillId) then
            FGUI:setVisible(self._ui.Button_skillBase, true)
            FGUI:setVisible(self._ui.Button_skill0, false)
        else
            FGUI:setVisible(self._ui.Button_skillBase, false)
            FGUI:setVisible(self._ui.Button_skill0, true)
            local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skillId)
            FGUI:GButton_setIcon(self._ui.Button_skill0, path, true)
        end
    else
        if not skillId then
            FGUI:GButton_setIcon(self._ui["Button_skill" .. key], "")
        else
            local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skillId)
            FGUI:GButton_setIcon(self._ui["Button_skill" .. key], path, true)
        end
    end
end

function MainSkill:UpdateSkillCD(skillID, percent, time)
    if time and time <= 0 then 
        percent = 0
    end 

    local key = self._keyMap[skillID]
    if not key then return end
    local imageCd = self._imageCds[key]
    if not imageCd then return end
    FGUI:setVisible(imageCd, percent > 0)
    FGUI:GImage_setFillAmount(imageCd, percent)
end

function MainSkill:LaunchSkill(launchId)
    FGUIFunction:LaunchSkill(launchId)
end

function MainSkill:OnSkillAdd(data)
    if not data then return end
    if not data.SkillId then return end

    local isForbid = SL:GetValue("SKILL_CHECK_IS_FORBID", data.SkillId)
    if isForbid then 
        return 
    end 

    local isNormal = SL:GetValue("SKILL_CHECK_IS_ATTACK", data.SkillId)
    if isNormal then
        self._normalID = data.SkillId
        self:CheckNormalSkill()
    end
    if not data.Key then return end
    self:UpdateSkill(data.Key, data.SkillId)
end

function MainSkill:OnSkillDel(data)
    if not data then return end
    if not data.SkillId then return end
    local isNormal = SL:GetValue("SKILL_CHECK_IS_ATTACK", data.SkillId)
    if isNormal then
        self._normalID = nil
    end
    if not data.Key then return end
    self:UpdateSkill(nil, data.SkillId)
    self:CheckNormalSkill()
end

function MainSkill:OnSkillSetKey(data)
    if not data or not data.SkillId then return end
    if data.Key then
        self:UpdateSkill(data.Key, data.SkillId)
    end
    self:CheckNormalSkill()
end

function MainSkill:OnSkillDeleteKey(data)
    -- remove
    self:OnSkillDel(data)
end

-- 刷新技能CD
function MainSkill:OnSkillCDTimeChange(data)
    self:UpdateSkillCD(data.skillID, data.percent, data.time)
end

function MainSkill:OnKeyboardLaunch(key)
    self:OnSkill(key)
end


-----------------------------------注册事件--------------------------------------
function MainSkill:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_ADD, "MainSkill", handler(self, self.OnSkillAdd))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_DEL, "MainSkill", handler(self, self.OnSkillDel))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_SET_KEY, "MainSkill", handler(self, self.OnSkillSetKey))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_DEL_KEY, "MainSkill", handler(self, self.OnSkillDeleteKey))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, "MainSkill", handler(self, self.OnSkillCDTimeChange))
end

function MainSkill:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_ADD, "MainSkill")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_DEL, "MainSkill")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_SET_KEY, "MainSkill")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_DEL_KEY, "MainSkill")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, "MainSkill")
end


return MainSkill