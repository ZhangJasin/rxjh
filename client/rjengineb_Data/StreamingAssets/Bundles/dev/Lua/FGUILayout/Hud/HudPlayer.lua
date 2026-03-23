local HudMoveable = require("FGUILayout/Hud/HudMoveable")
local HudConfig = require("FGUILayout/Hud/HudConfig")
local HudPlayer = class("HudPlayer", HudMoveable)
HudPlayer.type = HUDType.PLAYER

function HudPlayer:ctor(uiHud)
    HudPlayer.super.ctor(self, uiHud)
    self._spriteMeshHPBG        = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hpBg, HUDComponentName.CSSpriteMeshScale9)
    self._spriteMeshHP          = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hp,HUDComponentName.CSSpriteMeshScale9)
    self._spriteMeshHPAni       = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.hpAni, HUDComponentName.CSSpriteMeshScale9)
    self._attachTitle           = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.attachTitle)  
    self._labelGuild            = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.guild, HUDComponentName.CSLabel)  

    HUDHelp:SetLabelOutlineDelta(self._labelGuild, HUDVector2Mid)

    self._hudVisibleList[self._spriteMeshHPBG] = true
    self._hudVisibleList[self._spriteMeshHP] = true
    self._hudVisibleList[self._spriteMeshHPAni] = true
    self._hudVisibleList[self._attachTitle] = true

    HUDHelp:SetSpriteName(self._spriteMeshHPBG, HudConfig.HPConfig.HP_NORMAL_BG.res)
    HUDHelp:SetSpriteName(self._spriteMeshHP, HudConfig.HPConfig.HP_RED.res)
    HUDHelp:SetSpriteName(self._spriteMeshHPAni, HudConfig.HPConfig.HP_RED.res)

    self:SetSpriteScale9(self._spriteMeshHPBG,HudConfig.HPConfig.HP_NORMAL_BG.scale9)
    self:SetSpriteScale9(self._spriteMeshHP,HudConfig.HPConfig.HP_RED.scale9)
    self:SetSpriteScale9(self._spriteMeshHPAni,HudConfig.HPConfig.HP_RED.scale9)

    self:SetSpriteScale9Size(self._spriteMeshHPBG,HudConfig.HPConfig.HP_NORMAL_BG.size)
    self:SetSpriteScale9Size(self._spriteMeshHP,HudConfig.HPConfig.HP_RED.size)
    self:SetSpriteScale9Size(self._spriteMeshHPAni,HudConfig.HPConfig.HP_RED.size)
    
    self._cacheGuild = nil
    self._cacheHPPercent = nil
    self._cacheHPAniPercent = nil
    self._cacheHudHpTypeVisible = nil

    self:SetVisible(self._spriteMeshHPAni, false)

    
    self._guildHorizontal = false --行会名字 跟名字横排
    HUDHelp:SetLabelHalfWidthCallBack(self._labelName, handler(self,self.NameHalfWidthCallBack))
    HUDHelp:SetLabelHalfWidthCallBack(self._labelGuild, handler(self,self.GuildHalfWidthCallBack))

    local _, titleY, _ = HUDHelp:GetPosition(self._attachTitle)
    self._titleY = titleY --临时y根据行会名字调整
    local titleY = titleY - 0.3
    
    HUDHelp:SetPosition(self._attachTitle, 0,titleY, 0)
    --有血条的情况下往上移
    local showPlayerHPType = SL:GetValue("GAME_DATA","ShowPlayerHPType")
    if showPlayerHPType and showPlayerHPType ~= 0 then 
        self._titleY = self._titleY + 0.2
        titleY = titleY + 0.2
        HUDHelp:SetPosition(self._attachTitle, 0, titleY, 0)
        local _, y, _  = HUDHelp:GetPosition(self._labelGuild)
        HUDHelp:SetPosition(self._labelGuild, 0, y + 0.2, 0)
        _, y, _  = HUDHelp:GetPosition(self._labelName)
        HUDHelp:SetPosition(self._labelName, 0, y + 0.2, 0)
        _, y, _  = HUDHelp:GetPosition(self._spriteMeshHPBG)
        HUDHelp:SetPosition(self._spriteMeshHPBG, 0, y + 0.2, 0)
        _, y, _  = HUDHelp:GetPosition(self._spriteMeshHP)
        HUDHelp:SetPosition(self._spriteMeshHP, 0, y + 0.2, 0)
        _, y, _  = HUDHelp:GetPosition(self._spriteMeshHPAni)
        HUDHelp:SetPosition(self._spriteMeshHPAni, 0, y + 0.2, 0)
    end
    local labelNameSize = SL:GetValue("GAME_DATA","HUDPlayerNameSize") or 24
    HUDHelp:SetLabelFontSize(self._labelName, labelNameSize)

    local labelGuildSize = SL:GetValue("GAME_DATA","HUDPlayerGuildSize") or 24
    HUDHelp:SetLabelFontSize(self._labelGuild, labelGuildSize)
    local labelGuildColorID = SL:GetValue("GAME_DATA","HUDPlayerGuildColorID") or 255
    local color3B = SL:GetValue("COLOR3B_BY_ID",labelGuildColorID) 
    HUDHelp:SetLabelColor(self._labelGuild, color3B.r,color3B.g, color3B.b, color3B.a)

    SL:RegisterLUAEvent(LUA_EVENT_SETTING_INIT, "HudPlayer", handler(self, self.OnSettingInit))
end

function HudPlayer:OnSettingInit()
    if self._actorID and SL:GetValue("MAIN_PLAYER_ID") == self._actorID then 
        self:RefreshAllTitleVisible()
    end
end

local defaultStr = ""
function HudPlayer:Init(actorID)
    HudPlayer.super.Init(self, actorID)
    self:SetLabelGuildText(defaultStr)

    self._updateGuildNameLayout = false 
    self._updateKuaFuNameTextLayout = false 
    self._updateKuaFuNameSpriteLayout = false 
    self._updateKuaFuGuildNameTextLayout = false 
    self._updateKuaFuGuildNameSpriteLayout = false 
    self._nameHalfWidth = nil
    self._guildHalfWidth = nil
    self._kuaFuHalfWidth = nil
    self._kuaFuGuildHalfWidth = nil
    if self._kuaFuNode then 
        self:SetVisible(self._kuaFuNode, false)
    end
end

function HudPlayer:Cleanup()
    self:SetLabelGuildText(defaultStr)
    HudPlayer.super.Cleanup(self)
    if self._kuaFuNode then 
        if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
            HUDHelp:RecycelLabel(self._kuaFuNode)
        elseif self._kuaFuType == HudConfig.KuaFuType.SPRITE then 
            HUDHelp:RecycelSprite(self._kuaFuNode)
        end
        self._kuaFuNode = nil
    end
    if self._BoxTitle then 
        HUDHelp:RecycelFx(self._BoxTitle)
        self._BoxTitle = nil
        self._BoxTitleHeight = 0
    end
    if self._BoxTitle then 
        HUDHelp:RecycelFx(self._BoxTitle)
        self._BoxTitle = nil
        self._BoxTitleID = nil
        self._BoxTitleHeight = 0
    end
end

function HudPlayer:SetHUDVisibleByType(iType,visible)   
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
        self:SetVisible(self._labelGuild, visible)
    elseif iType == HudConfig.HUDType.Title then 
        if self._cacheHudTitleTypeVisible == visible then
            return 
        end
        self._cacheHudTitleTypeVisible = visible
        self:SetVisible(self._attachTitle, visible)
    end
end

function HudPlayer:SetHudHPVisible(visible)
    self:SetHUDVisibleByType(HudConfig.HUDType.HP, visible)
end

function HudPlayer:GetHPPercent()
    return self._cacheHPPercent
end 

function HudPlayer:SetHudHPPercent(percent)
    if self._cacheHPPercent == percent then
        return
    end
    self._cacheHPPercent = percent

    HUDHelp:SetSpritePercent(self._spriteMeshHP, percent)
end 

function HudPlayer:SetHudHPAniPercent(percent)
    if self._cacheHPAniPercent == percent then
        return
    end
    self._cacheHPAniPercent = percent

    HUDHelp:SetSpritePercent(self._spriteMeshHPAni, percent)
end 

function HudPlayer:RefreshLabelNameVisible(visible)
    local isVisible = true
    --屏蔽名字
    local actorID = self._actorID
    local masterID = SL:GetValue("ACTOR_MASTER_ID", self._actorID)
    if masterID ~= 0 then 
        actorID = masterID
    end
    
    if actorID == SL:GetValue("MAIN_PLAYER_ID") then
        if SL:GetValue("SETTING_SELF_NAME_EN") then 
            isVisible = false
        end
    elseif SL:GetValue("ACTOR_IS_ENEMY", actorID) then 
        if SL:GetValue("SETTING_ENEMY_NAME_EN") then 
            isVisible = false
        end
    else 
        if SL:GetValue("SETTING_FRND_NAME_EN") then 
            isVisible = false
        end
    end
    if visible ~= nil then
        isVisible = visible
    end
    self:SetHudNameVisible(isVisible)
end

function HudPlayer:RefreshLabelNameColor()
    if SL:GetValue("ACTOR_IS_HUMAN") then 
        return
    end

    local nameColorID = 255
    local nameColor
    if SL:GetValue("ACTOR_IS_MAINPLAYER", self._actorID) then 
        nameColorID = SL:GetValue("GAME_DATA", "MainPlayerNameColorID") or 250
    else
        local resType = SL:GetValue("ACTOR_RELATION_TYPE", self._actorID)
        if resType == SLDefine.CONTACT.RS_ENEMY then
            nameColorID = 249
        else 
            if SL:GetValue("TEAM_IS_MEMBER", self._actorID) then 
                nameColorID = 94
            end
        end
    end

    nameColor = SL:GetValue("COLOR3B_BY_ID", nameColorID)
    self:SetHudNameColor(nameColor)
end

function HudPlayer:RefreshLabelGuild()
    local guildName =  SL:GetValue("ACTOR_GUILD_NAME", self._actorID)
    self:SetLabelGuildText(guildName)
end

--设置行会名字
function HudPlayer:SetLabelGuildText(guild)
    if self._cacheGuild == guild then 
        return 
    end 
    local lastGuild = self._cacheGuild
    
    self._cacheGuild = guild
    local name2, hudType, kuaFuName, param3, param4 = FGUIFunction:GetHudServerName(guild, self._actorID)
    
    local refAnchor = false
    if self._guildHorizontal then 
        refAnchor = true
        self:SetNameAnchor()
        if hudType == HudConfig.KuaFuType.TEXT then 
            self._updateKuaFuGuildNameTextLayout = true
        elseif hudType == HudConfig.KuaFuType.SPRITE then
            self._updateKuaFuGuildNameSpriteLayout = true
        else
            self._updateGuildNameLayout = true
        end
    else 
        if guild ~= "" and lastGuild == "" then 
            HUDHelp:SetPosition(self._attachTitle, 0, self._titleY, 0)
        end
        if guild == "" and lastGuild ~= "" then 
            HUDHelp:SetPosition(self._attachTitle, 0, self._titleY - 0.3, 0)
        end
    end
    if refAnchor then 
        self:SetGuildAnchor()
    else 
        self:ReSetGuildAnchor()
        self:ReSetGuildPositionX()
    end

    if HUDHelp:GetLabelText(self._labelGuild) ~= name2 then 
        self._guildHalfWidth = nil
        HUDHelp:SetLabelText(self._labelGuild, name2)
    else 
        if self._guildHalfWidth then 
            self:GuildHalfWidthCallBack(self._guildHalfWidth * 100)
        end
    end
    
    HUDHelp:SetLabelText(self._labelGuild, name2)
    if guild and guild ~= "" then
        self:SetVisible(self._labelGuild, true)
    else 
        self:SetVisible(self._labelGuild, false)
    end
end

-- 设置名字
function HudPlayer:SetHudName(name)
    if self._cacheName == name then 
        return 
    end 
    self._cacheName = name
    local name2, hudType, kuaFuName, param3, param4 = FGUIFunction:GetHudServerName(name,self._actorID)
    self._kuaFuType = hudType
    if hudType then 
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
    local refAnchor = false
    if self._guildHorizontal then 
        refAnchor = true
        if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
            self._updateKuaFuGuildNameTextLayout = true
        elseif hudType == HudConfig.KuaFuType.SPRITE then
            self._updateKuaFuGuildNameSpriteLayout = true
        else
            self._updateGuildNameLayout = true
        end
    else 
        if self._kuaFuType == HudConfig.KuaFuType.TEXT then 
            self._updateKuaFuNameTextLayout = true
            refAnchor = true
        elseif self._kuaFuType == HudConfig.KuaFuType.SPRITE then 
            self._updateKuaFuNameSpriteLayout = true
        end
    end

    if refAnchor then 
        self:SetNameAnchor()
    else 
        self:ReSetNameAnchor()
        self:ReSetNamePositionX()
    end
    if HUDHelp:GetLabelText(self._labelName) ~= name2 then 
        self._nameHalfWidth = nil
        HUDHelp:SetLabelText(self._labelName, name2)
    else 
        if self._nameHalfWidth then 
            self:NameHalfWidthCallBack(self._nameHalfWidth * 100)
        end
    end
end

function HudPlayer:SetGuildAnchor()
    local guildLastAnchor = HUDHelp:GetLabelAnchor(self._labelGuild) 
    local guildAnchor = HUDAnchor.Center
    if self._guildHorizontal then 
        guildAnchor = HUDAnchor.Right
    else
        if self._kuaFuType == HudConfig.KuaFuType.TEXT then
            guildAnchor = HUDAnchor.Left
        end
    end    
    if guildAnchor ~= guildLastAnchor then 
        HUDHelp:SetLabelAnchor(self._labelGuild, guildAnchor)  
        local str = HUDHelp:GetLabelText(self._labelGuild)
        HUDHelp:SetLabelText(self._labelGuild, "")
        HUDHelp:SetLabelText(self._labelGuild, str)
    end
end

function HudPlayer:ReSetGuildAnchor()
    local guildLastAnchor = HUDHelp:GetLabelAnchor(self._labelGuild) 
    local guildAnchor = HUDAnchor.Center
    if guildAnchor ~= guildLastAnchor then 
        HUDHelp:SetLabelText(self._labelGuild, "") 
        HUDHelp:SetLabelAnchor(self._labelGuild, guildAnchor)  
    end
end

function HudPlayer:ReSetGuildPositionX()
    local guildPosX, guildPosY, guildPosZ = HUDHelp:GetPosition(self._labelGuild)
    HUDHelp:SetPosition(self._labelGuild, 0, guildPosY, guildPosZ)
end

function HudPlayer:SetNameAnchor()
    local nameLastAnchor =  HUDHelp:GetLabelAnchor(self._labelName) 
    local nameAnchor = HUDAnchor.Left
    if nameAnchor ~= nameLastAnchor then 
        HUDHelp:SetLabelAnchor(self._labelName, nameAnchor) 
        local str = HUDHelp:GetLabelText(self._labelName)
        HUDHelp:SetLabelText(self._labelName, "")
        HUDHelp:SetLabelText(self._labelName, str)
    end
end

function HudPlayer:ReSetNameAnchor()
    local nameLastAnchor = HUDHelp:GetLabelAnchor(self._labelName) 
    local nameAnchor = HUDAnchor.Center
    if nameAnchor ~= nameLastAnchor then 
        HUDHelp:SetLabelText(self._labelName, "") 
        HUDHelp:SetLabelAnchor(self._labelName, nameAnchor) 
    end
end

function HudPlayer:ReSetNamePositionX()
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    HUDHelp:SetPosition(self._labelName, 0, namePosY, namePosZ)
end

function HudPlayer:RefreshHPBarVisible()
    local isVisible = true
    repeat
        if SL:GetValue("ACTOR_IS_DIE", self._actorID) then 
            isVisible = false
            break
        end

        --屏蔽血条
        if SL:GetValue("SETTING_HEALTH_BAR_EN") then 
            isVisible = false
            break
        end

        local showPlayerHPType = SL:GetValue("GAME_DATA","ShowPlayerHPType")
        if SL:GetValue("MAIN_PLAYER_ID") == self._actorID then 
            if not showPlayerHPType or showPlayerHPType == 0 then 
                isVisible = false
                break
            end
        else
            if not showPlayerHPType or showPlayerHPType == 0 or (showPlayerHPType == 2 and not SL:GetValue("ACTOR_IS_BE_ATTACKED",self._actorID)) then
                isVisible = false
                break
            end
        end
        
    until true

    self:SetHudHPVisible(isVisible)
end

function HudPlayer:RefreshAllTitleVisible()
    local isVisible = true
    repeat
        if SL:GetValue("MAIN_PLAYER_ID") == self._actorID then 
            if SL:GetValue("SETTING_SELF_TITLE_EN") then 
                isVisible = false
                break
            end
        elseif SL:GetValue("ACTOR_IS_ENEMY", self._actorID)  then 
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

function HudPlayer:SetSpriteScale9(spriteNode, scale9Config)
    HUDHelp:SetSpriteScale9(spriteNode, scale9Config[1], scale9Config[2], scale9Config[3], scale9Config[4])
end

function HudPlayer:SetSpriteScale9Size(spriteNode, sizeConfig)
    HUDHelp:SetSpriteScale9Size(spriteNode, sizeConfig[1], sizeConfig[2])
end

function HudPlayer:SetKuaFuName(hudType, kuaFuName, kuaFuColor)
    if not self._kuaFuNode then 
        local x, y, _=  HUDHelp:GetPosition(self._labelName)
        self._cacheKuaFu = kuaFuName
        if hudType == HudConfig.KuaFuType.TEXT then 
            self._kuaFuNode = HUDHelp:CreateHudLabel(self._uiHud, "kuaFuText", x, y, kuaFuName)
            HUDHelp:SetLabelAnchor(self._kuaFuNode, HUDAnchor.Right)  
            HUDHelp:SetLabelText(self._kuaFuNode, kuaFuName)
            HUDHelp:SetLabelColor(self._kuaFuNode, kuaFuColor.r,kuaFuColor.g, kuaFuColor.b, kuaFuColor.a)
            HUDHelp:SetLabelHalfWidthCallBack(self._kuaFuNode, handler(self,self.KuaFuHalfWidthCallBack))
            self._updateKuaFuNameTextLayout = true
            if self._guildHorizontal then 
                self._updateKuaFuGuildNameTextLayout = true
            end
            self._kuafuHalfWidth = nil
        elseif hudType == HudConfig.KuaFuType.SPRITE then 
            self._kuaFuNode = HUDHelp:CreateSprite(self._uiHud, "kuaFuIcon", x, y, kuaFuName)
        end
        
    else 
        self:SetVisible(self._kuaFuNode, true)
        if hudType == HudConfig.KuaFuType.TEXT then 
            if self._cacheKuaFu ~= kuaFuName then 
                self._updateKuaFuNameTextLayout = true
                if self._guildHorizontal then 
                    self._updateKuaFuGuildNameTextLayout = true
                end
                self._kuafuHalfWidth = nil
                HUDHelp:SetLabelText(self._kuaFuNode, kuaFuName)
            end
        elseif hudType == HudConfig.KuaFuType.SPRITE then 
            if self._cacheKuaFu ~= kuaFuName then 
                HUDHelp:SetSpriteName(self._kuaFuNode, kuaFuName)
            end
        end
    end
end

function HudPlayer:NameHalfWidthCallBack(halfWidth)
    self._nameHalfWidth = halfWidth / 100
    if self._updateGuildNameLayout then 
        self:UpdateGuildNameLayout()
    end
    if self._updateKuaFuNameTextLayout then 
        self:UpdateKuaFuNameTextLayout()
    end
    if self._updateKuaFuNameSpriteLayout then 
        self:UpdateKuaFuNameSpriteLayout()
    end
    if self._updateKuaFuGuildNameTextLayout then 
        self:UpdateKuaFuGuildNameTextLayout()
    end
    if self._updateKuaFuGuildNameSpriteLayout then 
        self:UpdateKuaFuGuildNameSpriteLayout()
    end
end

function HudPlayer:GuildHalfWidthCallBack(halfWidth)
    self._guildHalfWidth = halfWidth / 100
    if self._updateGuildNameLayout then 
        self:UpdateGuildNameLayout()
    end
    if self._updateKuaFuGuildNameTextLayout then 
        self:UpdateKuaFuGuildNameTextLayout()
    end
    if self._updateKuaFuGuildNameSpriteLayout then 
        self:UpdateKuaFuGuildNameSpriteLayout()
    end
end

function HudPlayer:KuaFuHalfWidthCallBack(halfWidth)
    self._kuafuHalfWidth = halfWidth / 100
    if self._updateKuaFuNameTextLayout then 
        self:UpdateKuaFuNameTextLayout()
    end
    if self._updateKuaFuGuildNameTextLayout then 
        self:UpdateKuaFuGuildNameTextLayout()
    end
end


--更新行会跟名字的位置
function HudPlayer:UpdateGuildNameLayout()
    if not self._nameHalfWidth 
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    if self._cacheGuild ~= "" and self._guildHalfWidth then 
        local halfWidth = self._nameHalfWidth + self._guildHalfWidth
        local guildOffsetX = 2 *self._guildHalfWidth - halfWidth
        local nameOffsetX = halfWidth - 2*self._nameHalfWidth
        HUDHelp:SetPosition(self._labelGuild, guildOffsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)
    else
        HUDHelp:SetPosition(self._labelName, -self._nameHalfWidth,namePosY, namePosZ)
    end
end
----------------------------------------------
--更新跨服文本跟名字的位置
function HudPlayer:UpdateKuaFuNameTextLayout()
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
    local offsetX = 2 *self._kuafuHalfWidth - halfWidth
    local nameOffsetX = halfWidth - 2*self._nameHalfWidth
    HUDHelp:SetPosition(self._kuaFuNode, offsetX,namePosY, namePosZ)
    HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)

    self._updateKuaFuNameTextLayout = false
end

--更新跨服图标跟名字的位置
function HudPlayer:UpdateKuaFuNameSpriteLayout()
    if not self._nameHalfWidth 
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    HUDHelp:SetPosition(self._kuaFuNode, -self._nameHalfWidth + self._kuaFuIconOffsetX ,namePosY + self._kuaFuIconOffsetY, namePosZ)

    self._updateKuaFuNameSpriteLayout = false
end
------------------------------------------------------
--更新跨服文字跟行会文字还有名字的位置
function HudPlayer:UpdateKuaFuGuildNameTextLayout()
    if not self._nameHalfWidth 
        or not self._kuafuHalfWidth
        or not self._cacheKuaFu 
        or self._cacheKuaFu == ""
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    if self._cacheGuild ~= "" and self._guildHalfWidth then 
        local halfWidth = self._nameHalfWidth + self._kuafuHalfWidth + self._guildHalfWidth
        local guildOffsetX = 2 *(self._kuafuHalfWidth + self._guildHalfWidth) - halfWidth
        local kuafuOffsetX = guildOffsetX - 2 * self._guildHalfWidth
        local nameOffsetX = guildOffsetX
        HUDHelp:SetPosition(self._kuaFuNode, kuafuOffsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._labelGuild, guildOffsetX,namePosY, namePosZ)
    else 
        local halfWidth = self._nameHalfWidth + self._kuafuHalfWidth 
        local offsetX = 2 *self._kuafuHalfWidth - halfWidth
        local nameOffsetX = halfWidth - 2*self._nameHalfWidth
        HUDHelp:SetPosition(self._kuaFuNode, offsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)
    end
end

--更新跨服图标跟行会文字还有名字的位置
function HudPlayer:UpdateKuaFuGuildNameSpriteLayout()
    if not self._nameHalfWidth 
        or not self._cacheName
        or self._cacheName == "" then 
        return
    end
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    if self._cacheGuild ~= "" and self._guildHalfWidth then 
        local halfWidth = self._nameHalfWidth + self._guildHalfWidth
        local guildOffsetX = 2 *self._guildHalfWidth - halfWidth
        local nameOffsetX = halfWidth - 2*self._nameHalfWidth
        local kuafuOffsetX = guildOffsetX - 2 * self._guildHalfWidth
        HUDHelp:SetPosition(self._labelGuild, guildOffsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)
        HUDHelp:SetPosition(self._kuaFuNode, kuafuOffsetX + self._kuaFuIconOffsetX,namePosY + self._kuaFuIconOffsetY, namePosZ)
    else 
        HUDHelp:SetPosition(self._labelName, -self._nameHalfWidth,namePosY, namePosZ)
        HUDHelp:SetPosition(self._kuaFuNode, -self._nameHalfWidth + self._kuaFuIconOffsetX,namePosY + self._kuaFuIconOffsetY, namePosZ)
    end
end
------------------------------------------------------

function HudPlayer:RefIcons() 
    HudPlayer.super.RefIcons(self)
    self:RefBoxTitleHeight()
end

function HudPlayer:RefBoxTitle() 
    local boxTitleID = SL:GetValue("ACTOR_BOX_TITLE_ID", self._actorID)
    if self._BoxTitle and self._BoxTitleID ~= boxTitleID then 
        HUDHelp:RecycelFx(self._BoxTitle)
        self._titleHeight = self._titleHeight - self._BoxTitleHeight - 0.01
        self._BoxTitle = nil
        self._BoxTitleHeight = 0
        self._BoxTitleID = nil
    end
    if boxTitleID and boxTitleID ~= 0 and not self._BoxTitle then 
        self._BoxTitleID = boxTitleID
        boxTitleID = boxTitleID + 5099
        --序列帧特效
        self._BoxTitleHeight = SL:GetValue("ICON_HEIGHT_BY_ID", boxTitleID)
        self._BoxTitle = HUDHelp:CreateFx(self._attachTitle, "BoxTitle_"..boxTitleID, 0, self._titleHeight + self._BoxTitleHeight / 2, boxTitleID)
        self._titleHeight = self._titleHeight + self._BoxTitleHeight + 0.01
    end
end

function HudPlayer:RefBoxTitleVisible() 
    local isVisible = true
    repeat
        if SL:GetValue("ACTOR_IS_MAINPLAYER", self._actorID) then 
            if not SL:GetValue("MY_BOX_TITLE_STATE", self._actorID) then
                isVisible = false
                break
            end
        else
            if not SL:GetValue("OTHER_BOX_TITLE_STATE", self._actorID) then
                isVisible = false
                break
            end
        end
        
    until true
    if self._BoxTitle then 
        HUDHelp:SetFxVisible(self._BoxTitle, isVisible)
    end
end

function HudPlayer:RefBoxTitleHeight() 
    if self._BoxTitle then 
        HUDHelp:SetFxPosition(self._BoxTitle, 0, self._titleHeight + self._BoxTitleHeight / 2, 0)
        self._titleHeight = self._titleHeight + self._BoxTitleHeight + 0.01
    end
end
return HudPlayer