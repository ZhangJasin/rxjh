AutoRobot = class('AutoRobot')
local AutoUtil = SL:RequireFile("FGUILayout/Auto/AutoUtil")
AutoRobot.TIMER_INTERVAL = 0.1

function AutoRobot.main()
    AutoRobot:Init()
end

function AutoRobot:Init()
    self._launchTime = 0
    self._restoreHpTime = 0
    self._restoreMpTime = 0

    self._petRestoreHpTime = 0
    self._petRestoreMpTime = 0
    self._petRestoreLoyaltyTime = 0

    self._autoEquipArrowTime = 0
    
    self._afkOptTime = 0
    self._usedItem = {}
    self._timerID = nil

    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "AutoRobot",  handler(self,self.OnPropertyInited))
end

function AutoRobot:OnPropertyInited()
    self:TimerBegan()
end

function AutoRobot:TimerBegan()
    if not self._timerID then
        local function callback()
            self:Tick( self.TIMER_INTERVAL )
        end
        self._timerID = SL:Schedule( callback, self.TIMER_INTERVAL )
    end
end

function AutoRobot:Tick( delta )
    -- 自动释放相关
    self:AutoLaunch(delta)

    -- 自动挂机使用物品等相关操作
    self:AFKOpt(delta)

    -- 自动吃药
    self:AutoRestore(delta)

    --宠物 自动吃药
    self:AutoPetRestore(delta)

    --自动装箭
    self:AutoEquipArrow(delta)
    table.clear(self._usedItem)
end

-------------------------------------------------------
-- 自动释放
function AutoRobot:AutoLaunch(delta)
    self._launchTime = self._launchTime + delta
    if self._launchTime <= 1 then
        return false
    end
    self._launchTime = 0

    local skillID, targetID = FGUIFunction:FindRobotLaunchSkill()
    if skillID and targetID then 
        local mainPlayerX = SL:GetValue("X") 
        local mainPlayerZ = SL:GetValue("Z") 
        local launchX = SL:GetValue("ACTOR_MAP_X", targetID) 
        local launchY = SL:GetValue("ACTOR_MAP_Y", targetID) 
        local launchZ = SL:GetValue("ACTOR_MAP_Z", targetID) 
        local launchDir = SL:CalcNorthDirByPos(mainPlayerX, mainPlayerZ, launchX, launchZ)

        SL:SetValue("SELECT_TARGET_ID", targetID, SLDefine.SELECT_TARGET.SYSTEM)
        SL:SetValue("AUTO_INPUT_LAUNCH", skillID, launchX, launchY, launchZ, launchDir)
    end
end

function AutoRobot:AutoEquipArrow(delta)
    self._autoEquipArrowTime = self._autoEquipArrowTime + delta
    if self._autoEquipArrowTime <= 1 then
        return false
    end

    self._autoEquipArrowTime = 0
    SL:onLUAEvent(LUA_EVENT_ARROW_OVER,false)
end


-- 自动挂机使用物品等相关操作
function AutoRobot:AFKOpt(delta)
    self._afkOptTime = self._afkOptTime + delta
    if self._afkOptTime <= 1 then
        return false
    end
    self._afkOptTime = 0

    --周围xx格有xx敌人使用
    if SL:GetValue("SETTING_ENABLE_ENEMIES_NEARBY") then 
        local dis = SL:GetValue("SETTING_DISTANCE_ENEMIES_NEARBY") 
        local count = SL:GetValue("SETTING_NUM_ENEMIES_NEARBY") 
        if dis and count and dis > 0 and count > 0 then 
            if AutoUtil.CheckIsEnoughEnemyPlayer(SL:GetValue("MAIN_PLAYER_ID"), count, dis) then 
                local index = SL:GetValue("SETTING_ITEM_ENEMIES_NEARBY")
                self:autoUseItemByIndex(index)
            end
        end
    end
    --周围xx格有xx红名使用
    if SL:GetValue("SETTING_ENABLE_HOSTILES_NEARBY") then 
        local dis = SL:GetValue("SETTING_DISTANCE_HOSTILES_NEARBY") 
        local count = SL:GetValue("SETTING_NUM_HOSTILES_NEARBY") 
        if dis and count and dis > 0 and count > 0 then 
            if AutoUtil.CheckIsEnoughPKPlayer(SL:GetValue("MAIN_PLAYER_ID"), count, dis) then 
                local index = SL:GetValue("SETTING_ITEM_HOSTILES_NEARBY")
                self:autoUseItemByIndex(index)
            end
        end
    end
    --周围xx格有敌人主动攻击
    if SL:GetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY") then 
        local dis = SL:GetValue("SETTING_DISTANCE_ACTIVE_ATK_ENEMIES_NEARBY") 
        local count = 1
        if dis and dis > 0 then 
            local isFind, actorID = AutoUtil.CheckIsEnoughEnemyNearerPlayer(SL:GetValue("MAIN_PLAYER_ID"), count, dis)
            if isFind then 
                SL:SetValue("SELECT_TARGET_ID", actorID)
            end
        end
    end
end

-- 自动吃药
function AutoRobot:AutoRestore(delta)
    self:AutoHp(delta)
    self:AutoMp(delta)
end

--宠物 自动吃药
function AutoRobot:AutoPetRestore(delta)
    self:PetAutoHp(delta)
    self:PetAutoMp(delta)
    --Loyalty
    self:PetAutoRestoreLoyalty(delta)
end

function AutoRobot:AutoHp(delta)
    self._restoreHpTime = self._restoreHpTime + delta
    if self._restoreHpTime <= 1 then
        return false
    end
    self._restoreHpTime = 0

    local fastSetPercent  = SL:GetValue("SETTING_PLAYER_AUTO_FAST_HP_LIMIT")
    local setPercent = SL:GetValue("SETTING_PLAYER_AUTO_HP_LIMIT")
    if setPercent <= fastSetPercent then 
        self:AutoRestoreHp()
        self:AutoRestoreFastHp()
    else
        self:AutoRestoreFastHp()
        self:AutoRestoreHp()
    end
end

function AutoRobot:AutoRestoreFastHp()
    local hpEnable = SL:GetValue("SETTING_PLAYER_AUTO_FAST_HP_ENABLE")
    if not hpEnable then 
        return 
    end
    
    local curHP = SL:GetValue("HP")
    local maxHP = SL:GetValue("MAXHP")
    if curHP == 0 or maxHP == 0 then 
        return false
    end
    local setPercent  = SL:GetValue("SETTING_PLAYER_AUTO_FAST_HP_LIMIT")
    local curPercent = curHP / maxHP * 100
    if curPercent >= setPercent then
        return false
    end

    local hpMedicine = SL:GetValue("SETTING_PLAYER_AUTO_FAST_HP_VALUE")
    if not hpMedicine then
        return false
    end
    for i,v in ipairs(hpMedicine) do
        if self:autoUseItemByIndex(v) then 
            return
        end
    end
end

function AutoRobot:AutoRestoreHp()
    local hpEnable = SL:GetValue("SETTING_PLAYER_AUTO_HP_ENABLE")
    if not hpEnable then 
        return 
    end
    
    local curHP = SL:GetValue("HP")
    local maxHP = SL:GetValue("MAXHP")
    if curHP == 0 or maxHP == 0 then 
        return false
    end
    local setPercent  = SL:GetValue("SETTING_PLAYER_AUTO_HP_LIMIT")
    local curPercent = curHP / maxHP * 100
    if curPercent >= setPercent then
        return false
    end

    local hpMedicine = SL:GetValue("SETTING_PLAYER_AUTO_HP_VALUE")
    if not hpMedicine then
        return false
    end
    for i,v in ipairs(hpMedicine) do
        if self:autoUseItemByIndex(v) then 
            return
        end
    end
end

function AutoRobot:AutoMp(delta)
    self._restoreMpTime = self._restoreMpTime + delta
    if self._restoreMpTime <= 1 then
        return false
    end
    self._restoreMpTime = 0

    local fastSetPercent  = SL:GetValue("SETTING_PLAYER_AUTO_FAST_MP_LIMIT")
    local setPercent = SL:GetValue("SETTING_PLAYER_AUTO_MP_LIMIT")
    if setPercent <= fastSetPercent then 
        self:AutoRestoreMp()
        self:AutoRestoreFastMp()
    else
        self:AutoRestoreFastMp()
        self:AutoRestoreMp()
    end
end
function AutoRobot:AutoRestoreFastMp(delta)
    local mpEnable = SL:GetValue("SETTING_PLAYER_AUTO_FAST_MP_ENABLE")
    if not mpEnable then 
        return 
    end

    local curMP = SL:GetValue("MP")
    local maxMP = SL:GetValue("MAXMP")
    if maxMP == 0 then 
        return false
    end
    local setPercent  = SL:GetValue("SETTING_PLAYER_AUTO_FAST_MP_LIMIT")
    local curPercent = curMP / maxMP * 100
    if curPercent >= setPercent then
        return false
    end
    local mpMedicine = SL:GetValue("SETTING_PLAYER_AUTO_FAST_MP_VALUE")
    if not mpMedicine then
        return false
    end
    for i,v in ipairs(mpMedicine) do
        if self:autoUseItemByIndex(v) then 
            return
        end
    end
end

function AutoRobot:AutoRestoreMp(delta)
    local mpEnable = SL:GetValue("SETTING_PLAYER_AUTO_MP_ENABLE")
    if not mpEnable then 
        return 
    end

    local curMP = SL:GetValue("MP")
    local maxMP = SL:GetValue("MAXMP")
    if maxMP == 0 then 
        return false
    end
    local setPercent  = SL:GetValue("SETTING_PLAYER_AUTO_MP_LIMIT")
    local curPercent = curMP / maxMP * 100
    if curPercent >= setPercent then
        return false
    end
    local mpMedicine = SL:GetValue("SETTING_PLAYER_AUTO_MP_VALUE")
    if not mpMedicine then
        return false
    end
    for i,v in ipairs(mpMedicine) do
        if self:autoUseItemByIndex(v) then 
            return
        end
    end
end

function AutoRobot:PetAutoHp(delta)
    self._petRestoreHpTime = self._petRestoreHpTime + delta
    if self._petRestoreHpTime <= 1 then
        return false
    end
    self._petRestoreHpTime = 0

    local fastSetPercent  = SL:GetValue("SETTING_PET_AUTO_FAST_HP_LIMIT")
    local setPercent = SL:GetValue("SETTING_PET_AUTO_HP_LIMIT")
    if setPercent <= fastSetPercent then 
        self:PetAutoRestoreHp()
        self:PetAutoRestoreFastHp()
    else
        self:PetAutoRestoreFastHp()
        self:PetAutoRestoreHp()
    end
end

function AutoRobot:PetAutoRestoreFastHp(delta)
    local hpEnable = SL:GetValue("SETTING_PET_AUTO_FAST_HP_ENABLE")
    if not hpEnable then 
        return 
    end
    
    local pets = SL:GetValue("PETS")
    for petID, _ in pairs(pets) do
        repeat
            local curHP = SL:GetValue("ACTOR_HP", petID)
            local maxHP = SL:GetValue("ACTOR_MAXHP", petID)
            if curHP == 0 or maxHP == 0 then 
                break
            end
            local setPercent  = SL:GetValue("SETTING_PET_AUTO_FAST_HP_LIMIT")
            local curPercent = curHP / maxHP * 100
            if curPercent >= setPercent then
                break
            end

            local hpMedicine = SL:GetValue("SETTING_PET_AUTO_FAST_HP_VALUE")
            if not hpMedicine then
                break
            end
            for i,v in ipairs(hpMedicine) do
                if self:autoUseItemByIndex(v) then 
                    break
                end
            end
        until true
    end
end

function AutoRobot:PetAutoRestoreHp(delta)
    local hpEnable = SL:GetValue("SETTING_PET_AUTO_HP_ENABLE")
    if not hpEnable then 
        return 
    end
    
    local pets = SL:GetValue("PETS")
    for petID, _ in pairs(pets) do
        repeat
            local curHP = SL:GetValue("ACTOR_HP", petID)
            local maxHP = SL:GetValue("ACTOR_MAXHP", petID)
            if curHP == 0 or maxHP == 0 then 
                break
            end
            local setPercent  = SL:GetValue("SETTING_PET_AUTO_HP_LIMIT")
            local curPercent = curHP / maxHP * 100
            if curPercent >= setPercent then
                break
            end

            local hpMedicine = SL:GetValue("SETTING_PET_AUTO_HP_VALUE")
            if not hpMedicine then
                break
            end
            for i,v in ipairs(hpMedicine) do
                if self:autoUseItemByIndex(v) then 
                    break
                end
            end
        until true
    end
end

function AutoRobot:PetAutoMp(delta)
    self._petRestoreMpTime = self._petRestoreMpTime + delta
    if self._petRestoreMpTime <= 1 then
        return false
    end
    self._petRestoreMpTime = 0

    local fastSetPercent  = SL:GetValue("SETTING_PET_AUTO_FAST_MP_LIMIT")
    local setPercent = SL:GetValue("SETTING_PET_AUTO_MP_LIMIT")
    if setPercent <= fastSetPercent then 
        self:PetAutoRestoreMp()
        self:PetAutoRestoreFastMp()
    else
        self:PetAutoRestoreFastMp()
        self:PetAutoRestoreMp()
    end
end
function AutoRobot:PetAutoRestoreFastMp(delta)
    local mpEnable = SL:GetValue("SETTING_PET_AUTO_FAST_MP_ENABLE")
    if not mpEnable then 
        return 
    end
    
    local pets = SL:GetValue("PETS")
    for petID, _ in pairs(pets) do
        repeat
            local curMP = SL:GetValue("ACTOR_MP", petID)
            local maxMP = SL:GetValue("ACTOR_MAXMP", petID)
            if maxMP == 0 then 
                break
            end
            local setPercent  = SL:GetValue("SETTING_PET_AUTO_FAST_MP_LIMIT")
            local curPercent = curMP / curMP * 100
            if curPercent >= setPercent then
                break
            end

            local mpMedicine = SL:GetValue("SETTING_PET_AUTO_FAST_MP_VALUE")
            if not mpMedicine then
                break
            end
            for i,v in ipairs(mpMedicine) do
                if self:autoUseItemByIndex(v) then 
                    break
                end
            end
        until true
    end
end

function AutoRobot:PetAutoRestoreMp(delta)
    local mpEnable = SL:GetValue("SETTING_PET_AUTO_MP_ENABLE")
    if not mpEnable then 
        return 
    end
    
    local pets = SL:GetValue("PETS")
    for petID, _ in pairs(pets) do
        repeat
            local curMP = SL:GetValue("ACTOR_MP", petID)
            local maxMP = SL:GetValue("ACTOR_MAXMP", petID)
            if maxMP == 0 then 
                break
            end
            local setPercent  = SL:GetValue("SETTING_PET_AUTO_MP_LIMIT")
            local curPercent = curMP / curMP * 100
            if curPercent >= setPercent then
                break
            end

            local mpMedicine = SL:GetValue("SETTING_PET_AUTO_MP_VALUE")
            if not mpMedicine then
                break
            end
            for i,v in ipairs(mpMedicine) do
                if self:autoUseItemByIndex(v) then 
                    break
                end
            end
        until true
    end
end

function AutoRobot:PetAutoRestoreLoyalty(delta)
    self._petRestoreLoyaltyTime = self._petRestoreLoyaltyTime + delta
    if self._petRestoreLoyaltyTime <= 1 then
        return false
    end
    self._petRestoreLoyaltyTime = 0

    local loyaltyEnable = SL:GetValue("SETTING_PET_AUTO_FAVORITE_ENABLE")
    if not loyaltyEnable then 
        return 
    end
    
    local pets = SL:GetValue("PETS")
    for petID, _ in pairs(pets) do
        repeat
            local curLoyalty = SL:GetValue("PET_LOYALTY", petID) or -1
            local maxLoyalty = SL:GetValue("PET_MAX_LOYALTY", petID)
            if curLoyalty == -1 then 
                break
            end
            local setPercent  = SL:GetValue("SETTING_PET_AUTO_FAVORITE_LIMIT")
            local curPercent = curLoyalty / maxLoyalty * 100
            if curPercent >= setPercent then
                break
            end

            local loyaltyMedicine = SL:GetValue("SETTING_PET_AUTO_FAVORITE_VALUE")
            if not loyaltyMedicine then
                break
            end
            for i,v in ipairs(loyaltyMedicine) do
                if self:autoUseItemByIndex(v) then 
                    break
                end
            end
        until true
    end
end

function AutoRobot:autoUseItemByIndex(index)
    local isInCD = false
    local endTime = SL:GetValue("ITEM_CD_ENDTIME",index)
    if endTime then
        local serverTime = SL:GetValue("SERVER_TIME")
        if serverTime < endTime then
            isInCD = true
        end
    end
    if isInCD then 
        return false
    end

    if self._usedItem[index] then 
        return false
    end

    local useSuccess = SL:RequestUseItemByIndex(index,true) 
    if useSuccess then 
        self._usedItem[index] = true
    end
    return useSuccess
end