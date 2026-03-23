local HudMoveable = require("FGUILayout/Hud/HudMoveable")
local HudConfig = require("FGUILayout/Hud/HudConfig")
local HudMonster = class("HudMonster", HudMoveable)
HudMonster.type = HUDType.MONSTER
function HudMonster:ctor(uiHud)
    HudMonster.super.ctor(self, uiHud)

    self._spriteMeshHPBG        = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hpBg, HUDComponentName.CSSpriteMeshScale9)
    self._spriteMeshHP          = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hp, HUDComponentName.CSSpriteMeshScale9)
    self._spriteMeshHPAni       = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hpAni, HUDComponentName.CSSpriteMeshScale9)
    self._attachTitle           = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.attachTitle)  
    self._labelHP               = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hpLabel, HUDComponentName.CSLabel)
    self._hudVisibleList[self._spriteMeshHPBG] = true
    self._hudVisibleList[self._spriteMeshHP] = true
    self._hudVisibleList[self._spriteMeshHPAni] = true
    self._hudVisibleList[self._attachTitle] = true
    self._hudVisibleList[self._labelHP] = true

    HUDHelp:SetSpriteName(self._spriteMeshHPBG, HudConfig.HPConfig.HP_NORMAL_BG.res)
    HUDHelp:SetSpriteName(self._spriteMeshHP, HudConfig.HPConfig.HP_RED.res)
    HUDHelp:SetSpriteName(self._spriteMeshHPAni, HudConfig.HPConfig.HP_RED.res)
    
    self:SetSpriteScale9(self._spriteMeshHPBG,HudConfig.HPConfig.HP_NORMAL_BG.scale9)
    self:SetSpriteScale9(self._spriteMeshHP,HudConfig.HPConfig.HP_RED.scale9)
    self:SetSpriteScale9(self._spriteMeshHPAni,HudConfig.HPConfig.HP_RED.scale9)

    self:SetSpriteScale9Size(self._spriteMeshHPBG,HudConfig.HPConfig.HP_NORMAL_BG.size)
    self:SetSpriteScale9Size(self._spriteMeshHP,HudConfig.HPConfig.HP_RED.size)
    self:SetSpriteScale9Size(self._spriteMeshHPAni,HudConfig.HPConfig.HP_RED.size)
    
    self._cacheLevel = nil
    self._cacheHPLabel = nil
    self._cacheHPResType = nil
    self._cacheHPPercent = nil
    self._cacheHPAniPercent = nil
    self._cacheHudHpTypeVisible = nil
    self._cacheHudHpLabelTypeVisible = nil

    self:SetVisible(self._spriteMeshHPAni, false)
    HUDHelp:SetLabelHalfWidthCallBack(self._labelName, handler(self,self.NameHalfWidthCallBack))

    local _, titleY, _ = HUDHelp:GetPosition(self._attachTitle)
    self._titleY = titleY 
    self._titleYDown = titleY - 0.25
end

function HudMonster:Init(actorID)
    HudMonster.super.Init(self, actorID)
    self:SetHUDVisibleByType(HudConfig.HUDType.Name, false)
    self:SetHUDVisibleByType(HudConfig.HUDType.HP, false)
    self:SetHUDVisibleByType(HudConfig.HUDType.HPLabel, false)

    if self._kuaFuNode then 
        self:SetVisible(self._kuaFuNode, false)
    end
    self._nameHalfWidth = nil
    self._kuafuHalfWidth = nil 
end

function HudMonster:Cleanup()
    HudMonster.super.Cleanup(self)

    if self._kuaFuNode then 
        if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
            HUDHelp:RecycelLabel(self._kuaFuNode)
        elseif self._kuaFuType == HudConfig.KuaFuType.SPRITE then 
            HUDHelp:RecycelSprite(self._kuaFuNode)
        end
        self._kuaFuNode = nil
    end
end

function HudMonster:SetHudHPVisible(visible)
    self:SetHUDVisibleByType(HudConfig.HUDType.HP, visible)
end

function HudMonster:SetHudHPLabelVisible(visible)
    self:SetHUDVisibleByType(HudConfig.HUDType.HPLabel, visible)
end

function HudMonster:SetHudHPResType(type)
    if self._cacheHPResType == type then
        return
    end
    self._cacheHPResType = type
    local bg_x, bg_y, bg_z = HUDHelp:GetPosition(self._spriteMeshHPBG)
    local hp_x, hp_y, hp_z = HUDHelp:GetPosition(self._spriteMeshHP)
    local config_bg = HudConfig.HPConfig.HP_NORMAL_BG
    local config_hp = HudConfig.HPConfig.HP_RED
    if type == HUDBloodType.Blood_Normal then
        if self._spriteMeshHPBG.SpriteName ~= HudConfig.HPConfig.HP_NORMAL_BG.res then
            config_bg = HudConfig.HPConfig.HP_NORMAL_BG
        end

        if self._spriteMeshHP.SpriteName ~= HudConfig.HPConfig.HP_RED.res then
            config_hp = HudConfig.HPConfig.HP_RED
        end
    elseif type == HUDBloodType.Blood_Elite then
        if self._spriteMeshHPBG.SpriteName ~= HudConfig.HPConfig.HP_ELITE_BG.res then
            config_bg = HudConfig.HPConfig.HP_ELITE_BG
        end
        if self._spriteMeshHP.SpriteName ~= HudConfig.HPConfig.HP_RED.res then
            config_hp = HudConfig.HPConfig.HP_RED
        end
    elseif type == HUDBloodType.Blood_Boss then
        if self._spriteMeshHPBG.SpriteName ~= HudConfig.HPConfig.HP_BOSS_BG.res then
            config_bg = HudConfig.HPConfig.HP_BOSS_BG
        end
        if self._spriteMeshHP.SpriteName ~= HudConfig.HPConfig.HP_RED_BOSS.res then
            config_hp = HudConfig.HPConfig.HP_RED_BOSS
        end
    end

    HUDHelp:SetSpriteName(self._spriteMeshHPBG, config_bg.res)
    HUDHelp:SetPosition(self._spriteMeshHPBG,bg_x, config_bg.Y, bg_z)
    self:SetSpriteScale9(self._spriteMeshHPBG, config_bg.scale9)
    self:SetSpriteScale9Size(self._spriteMeshHPBG,config_bg.size)


    HUDHelp:SetSpriteName(self._spriteMeshHP, config_hp.res)
    HUDHelp:SetPosition(self._spriteMeshHP,hp_x, config_hp.Y, hp_z)
    self:SetSpriteScale9(self._spriteMeshHP, config_hp.scale9)
    self:SetSpriteScale9Size(self._spriteMeshHP,config_hp.size)

end

function HudMonster:SetHUDVisibleByType(iType,visible)   
    if iType == HudConfig.HUDType.HP then 
        if self._cacheHudHpTypeVisible == visible then
            return 
        end
        self._cacheHudHpTypeVisible = visible
        self:SetVisible(self._spriteMeshHPBG, visible)
        self:SetVisible(self._spriteMeshHP, visible)
        
    elseif iType == HudConfig.HUDType.Name then 
        if self._cacheHudNameTypeVisible == visible then
            return 
        end
        self._cacheHudNameTypeVisible = visible
        self:SetVisible(self._labelName, visible)
    elseif iType == HudConfig.HUDType.Title then 
        if self._cacheHudTitleTypeVisible == visible then
            return 
        end
        self._cacheHudTitleTypeVisible = visible
        self:SetVisible(self._attachTitle, visible)
    elseif iType == HudConfig.HUDType.HPLabel then
        if self._cacheHudHpLabelTypeVisible == visible then
            return 
        end
        self._cacheHudHpLabelTypeVisible = visible
        self:SetVisible(self._labelHP, visible)
    end
end 

function HudMonster:GetHPPercent()
    return self._cacheHPPercent
end 

function HudMonster:SetHudHPPercent(percent)
    if self._cacheHPPercent == percent then
        return
    end
    self._cacheHPPercent = percent

    HUDHelp:SetSpritePercent(self._spriteMeshHP, percent)
end 

function HudMonster:SetHudHPAniPercent(percent)
    if self._cacheHPAniPercent == percent then
        return
    end
    self._cacheHPAniPercent = percent

    HUDHelp:SetSpritePercent(self._spriteMeshHPAni, percent)
end 

function HudMonster:RefHudHPLabel()
    if not SL:GetValue("IS_PC_OPER_MODE") then 
    end
    local curValue = SL:GetValue("ACTOR_HP", self._actorID)
    local maxValue = SL:GetValue("ACTOR_MAXHP", self._actorID)
    local hpLabel = string.format("%d/%d", curValue, maxValue)
    
    if SL:GetValue("SETTING_ENEMT_HP_SHOW_AS_PERCENTAGE_EN") then --百分比显示 
        maxValue = math.max(maxValue, 1)
        local curPercent = curValue / maxValue * 100
        hpLabel = string.format("%.1f%%", curPercent)
    end
    if hpLabel == self._cacheHPLabel then
        return
    end
    self._cacheHPLabel = hpLabel
    HUDHelp:SetLabelText(self._labelHP, hpLabel)
end 

function HudMonster:UpdateTitleY(HPLabelVisible)
    local titleX, titleY, titleZ = HUDHelp:GetPosition(self._attachTitle)
    if HPLabelVisible then 
        if titleY ~= self._titleY then 
            HUDHelp:SetPosition(self._attachTitle, titleX, self._titleY, titleZ)
        end
    else 
        if titleY ~= self._titleYDown then 
            HUDHelp:SetPosition(self._attachTitle, titleX, self._titleYDown, titleZ)
        end
    end
end

function HudMonster:RefreshLabelNameVisible()
    local isVisible = true
    repeat
        if SL:GetValue("ACTOR_IS_COLLECTION", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_ESCORT", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_DIE", self._actorID) then 
            isVisible = false
            break
        end

        --屏蔽名字
        local masterID = SL:GetValue("ACTOR_MASTER_ID", self._actorID)
        if masterID ~= 0 then 
            if masterID == SL:GetValue("MAIN_PLAYER_ID") then
                if SL:GetValue("SETTING_SELF_NAME_EN") then 
                    isVisible = false
                    break
                end
            elseif SL:GetValue("ACTOR_IS_ENEMY", masterID) then 
                if SL:GetValue("SETTING_ENEMY_NAME_EN") then 
                    isVisible = false
                    break
                end
            else 
                if SL:GetValue("SETTING_FRND_NAME_EN") then 
                    isVisible = false
                    break
                end
            end
        else
            local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", self._actorID)
            local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", typeIndex) or 0
            
            if bossSign == 0 and SL:GetValue("SELECT_TARGET_ID") ~= self._actorID then
                isVisible = false
                break
            end

            --怪物显名
            if not SL:GetValue("SETTING_MONSTER_NAME_EN") then 
                isVisible = false
                break
            end
        end
    until true

    self:SetHudNameVisible(isVisible)
end

function HudMonster:RefreshHPBarVisible()
    local isVisible = true
    repeat
        if SL:GetValue("ACTOR_IS_COLLECTION", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_ESCORT", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_DIE", self._actorID) then 
            isVisible = false
            break
        end

        --屏蔽血条
        if SL:GetValue("SETTING_HEALTH_BAR_EN") then 
            isVisible = false
            break
        end
        
        local masterID = SL:GetValue("ACTOR_MASTER_ID", self._actorID)
        if masterID == 0 then 
            local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", self._actorID)
            local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", typeIndex) or 0
            
            if bossSign == 0 and SL:GetValue("SELECT_TARGET_ID") ~= self._actorID then
                isVisible = false
                break
            end
        end

    until true

    self:SetHudHPVisible(isVisible)
end

function HudMonster:RefreshLabelHPVisible()
    local isVisible = true
    repeat
        if not SL:GetValue("IS_PC_OPER_MODE") then 
            isVisible = false
            break
        end
        
        if SL:GetValue("ACTOR_IS_COLLECTION", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_ESCORT", self._actorID) then 
            isVisible = false
            break
        end

        if SL:GetValue("ACTOR_IS_DIE", self._actorID) then 
            isVisible = false
            break
        end

        --屏蔽血条文本
        if not SL:GetValue("SETTING_ENEMY_HP_VALUE_EN") then 
            isVisible = false
            break
        end
        
        local masterID = SL:GetValue("ACTOR_MASTER_ID", self._actorID)
        if masterID == 0 then 
            local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", self._actorID)
            local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", typeIndex) or 0
            
            if bossSign == 0 and SL:GetValue("SELECT_TARGET_ID") ~= self._actorID then
                isVisible = false
                break
            end
        end

    until true

    self:SetHudHPLabelVisible(isVisible)
    self:UpdateTitleY(isVisible)
end

function HudMonster:RefreshAllTitleVisible()
    local isVisible = true
    repeat
        if SL:GetValue("ACTOR_IS_ENEMY", self._actorID)  then 
            if SL:GetValue("SETTING_ENEMY_TITLE_EN") then 
                isVisible = false
                break
            end
        else
            if SL:GetValue("SETTING_FRND_TITLE_EN") then 
                isVisible = false
                break
            end
        end
        if not SL:GetValue("ACTOR_IN_FOV", self._actorID) then
            isVisible = false
            break
        end

        if not SL:GetValue("ACTOR_MODEL_IS_VSIBLE", self._actorID) then
            isVisible = false
            break
        end
    until true

    self:SetHudAllTitleVisible(isVisible)
end

function HudMonster:SetSpriteScale9(spriteNode, scale9Config)
    HUDHelp:SetSpriteScale9(spriteNode, scale9Config[1], scale9Config[2], scale9Config[3], scale9Config[4])
end

function HudMonster:SetSpriteScale9Size(spriteNode, sizeConfig)
    HUDHelp:SetSpriteScale9Size(spriteNode, sizeConfig[1], sizeConfig[2])
end


-- 设置名字
function HudMonster:SetHudName(name, refLevel)
    if self._cacheName == name and not refLevel then 
        return 
    end 
    self._cacheName = name

    local name2, hudType, kuaFuName, param3, param4 = FGUIFunction:GetHudServerName(name, self._actorID)
    self._kuaFuType = hudType
    if self._kuaFuType then 
        self:SetKuaFuName(hudType, kuaFuName, param3)
        if self._kuaFuType == HudConfig.KuaFuType.SPRITE then 
            self._kuaFuIconOffsetX = param3
            self._kuaFuIconOffsetY = param4
        end
    else 
        if self._kuaFuNode then 
            HUDHelp:SetVisible(self._kuaFuNode, false)
        end
    end
    if self._kuaFuType == HudConfig.KuaFuType.TEXT then  
        self:SetNameAnchor()
    else 
        self:ReSetNameAnchor()
        self:ReSetNamePositionX()
    end

    if HUDHelp:GetLabelText(self._labelName) ~= name2 then 
        self._nameHalfWidth = nil
        local nameStr = name2
        if self._cacheLevel then 
            nameStr = string.format("%s[Lv:%d]", name2, self._cacheLevel)
        end
        HUDHelp:SetLabelText(self._labelName, nameStr)
    else 
        if self._nameHalfWidth then 
            self:NameHalfWidthCallBack(self._nameHalfWidth * 100)
        end
    end
end

-- 刷新level
function HudMonster:RefLevel()
    local level = SL:GetValue("ACTOR_LEVEL", self._actorID)
    if self._cacheLevel == level then 
        return 
    end
    self._cacheLevel = level
    if self._cacheName then 
        self:SetHudName(self._cacheName, true)
    end
end
function HudMonster:SetNameAnchor()
    if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
        local nameLastAnchor =  HUDHelp:GetLabelAnchor(self._labelName) 
        local nameAnchor = HUDAnchor.Left
        if nameAnchor ~= nameLastAnchor then 
            HUDHelp:SetLabelAnchor(self._labelName, nameAnchor)
            local str = HUDHelp:GetLabelText(self._labelName)
            HUDHelp:SetLabelText(self._labelName, "")
            HUDHelp:SetLabelText(self._labelName, str)
        end
    end 
end

function HudMonster:ReSetNameAnchor()
    if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
        local nameLastAnchor =  HUDHelp:GetLabelAnchor(self._labelName) 
        local nameAnchor = HUDAnchor.Center
        if nameAnchor ~= nameLastAnchor then 
            HUDHelp:SetLabelAnchor(self._labelName, nameAnchor) 
        end
    end 
end

function HudMonster:ReSetNamePositionX()
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    HUDHelp:SetPosition(self._labelName, 0, namePosY, namePosZ)
end

function HudMonster:SetKuaFuName(hudType, kuaFuName, kuaFuColor)
    if not self._kuaFuNode then 
        local x, y, _=  HUDHelp:GetPosition(self._labelName)
        self._cacheKuaFu = kuaFuName
        if hudType == HudConfig.KuaFuType.TEXT then 
            self._kuaFuNode = HUDHelp:CreateHudLabel(self._uiHud, "kuaFuText", x, y, kuaFuName)
            HUDHelp:SetLabelText(self._kuaFuNode, kuaFuName)
            HUDHelp:SetLabelAnchor(self._kuaFuNode, HUDAnchor.Right)  
            HUDHelp:SetLabelColor(self._kuaFuNode, kuaFuColor.r,kuaFuColor.g, kuaFuColor.b, kuaFuColor.a)
            HUDHelp:SetLabelHalfWidthCallBack(self._kuaFuNode, handler(self,self.KuaFuHalfWidthCallBack))
            self._updateKuaFuNameText = true
            self._kuafuHalfWidth = nil
        elseif hudType == HudConfig.KuaFuType.SPRITE then 
            self._kuaFuNode = HUDHelp:CreateSprite(self._uiHud, "kuaFuIcon", x, y, kuaFuName)
            self._updateKuaFuNameSpriteLayout = true
        end
        
    else 
        self:SetVisible(self._kuaFuNode, true)
        if hudType == HudConfig.KuaFuType.TEXT then 
            if self._cacheKuaFu ~= kuaFuName then 
                self._updateKuaFuNameText = true
                self._kuafuHalfWidth = nil
                HUDHelp:SetLabelText(self._kuaFuNode, kuaFuName)
            end
        elseif hudType == HudConfig.KuaFuType.SPRITE then 
            if self._cacheKuaFu ~= kuaFuName then 
                HUDHelp:SetSpriteName(self._kuaFuNode, kuaFuName)
                self._updateKuaFuNameSpriteLayout = true
            end
        end
    end
end

function HudMonster:KuaFuHalfWidthCallBack(halfWidth)
    self._kuafuHalfWidth = halfWidth / 100
    if self._updateKuaFuNameText then 
        self:UpdateKuaFuNameTextLayout()
    end
end

function HudMonster:NameHalfWidthCallBack(halfWidth)
    self._nameHalfWidth = halfWidth / 100
    if self._updateKuaFuNameText then 
        self:UpdateKuaFuNameTextLayout()
    end
    if self._updateKuaFuNameSpriteLayout then 
        self:UpdateKuaFuNameSpriteLayout()
    end
end

-----------------------------------------------------
--更新跨服跟名字的位置
function HudMonster:UpdateKuaFuNameTextLayout()
    if not self._nameHalfWidth 
        or not self._kuafuHalfWidth
        or not self._cacheKuaFu 
        or self._cacheKuaFu == ""
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    local halfWidth = self._nameHalfWidth + self._kuafuHalfWidth
    local kuafuOffsetX = 2 *self._kuafuHalfWidth - halfWidth
    local nameOffsetX = halfWidth - 2*self._nameHalfWidth
    HUDHelp:SetPosition(self._kuaFuNode, kuafuOffsetX,namePosY, namePosZ)
    HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)

    self._updateGuildNameLayout = false
end

--更新跨服图标跟名字的位置
function HudMonster:UpdateKuaFuNameSpriteLayout()
    if not self._nameHalfWidth 
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    HUDHelp:SetPosition(self._kuaFuNode, -self._nameHalfWidth + self._kuaFuIconOffsetX,namePosY + self._kuaFuIconOffsetY, namePosZ)

    self._updateKuaFuNameSpriteLayout = false
end
-----------------------------------------------------
return HudMonster