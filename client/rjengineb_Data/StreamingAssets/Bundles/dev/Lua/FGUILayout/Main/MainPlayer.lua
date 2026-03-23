local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainPlayer = class("MainPlayer", BaseFGUILayout)
local SysConstant = require("game_config/cfgcsv/SysConstant")
local MainPlayerData = require("FGUILayout/Main/MainPlayerData")      -- 主玩家数据层
function MainPlayer:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._curHP = nil
    self._maxHP = nil
    self._curMP = nil
    self._maxMP = nil
    self._angerProV = 0
    self._myBuffDatas = {}
    self._ctrl_isShowBufList = FGUI:getController(self.component,"isShowBufList")
    self._scheduleSet = {}

    self.comboCurV = 0
    self.comboMaxV = 0
    self.imageCombos = {}

    self:InitComboId()
    self:InitModeDatas()
    FGUI:setOnClickEvent(self._ui.Touch_mode, handler(self, self.OnOpenModeSetting), nil, nil)
    FGUI:setOnClickEvent(self._ui.Touch_player, handler(self, self.OnClickPlayer), nil, nil)

    FGUI:setOnClickEvent(self._ui.player_icon, handler(self, self.OpenRole))
    
    FGUI:GList_itemRenderer(self._ui.list_buff, handler(self, self.ListBuffItemRender))
    
    FGUI:GList_itemRenderer(self._ui.list_buff_icon, handler(self, self.ListBuffIconItemRender))
    FGUI:GList_addOnClickItemEvent(self._ui.list_buff_icon, handler(self, self.OnClickBuffIconItem))
    
    FGUI:setOnClickEvent(self._ui.touchArea,handler(self,self.touchAreaClicked))

    FGUI:GProgressBar_setValue(self._ui.ProgressBar_anger, self._angerProV)

    -- 订阅数据层事件
    self._subscriptions = {}
    self._subscriptions.data_petResurrec = MainPlayerData:Subscribe("data_petResurrec", handler(self, self.petResurrec))
    self._subscriptions.data_showPetPro = MainPlayerData:Subscribe("data_showPetPro", handler(self, self.showPetPro)) 
    self._subscriptions.data_setPetInfo = MainPlayerData:Subscribe("data_setPetInfo", handler(self, self.setPetInfo)) 
end

function MainPlayer:Enter()
	self:RegisterEvent()

    self:InitAdapt()
    self:UpdatePropertys()
    self._ctrl_isShowBufList.selectedIndex = 1
    self:UpdateMyBuffs()
end


function MainPlayer:Exit()
	self:RemoveEvent()
    
    self._angerProV = 0
    FGUI:UIModel_clear(self._ui.Graph_angerEffect)
end

function MainPlayer:Destroy()
    self:CleanSchedule()
    self._ui = nil
    -- 取消订阅
    if self._subscriptions then
        for _, token in pairs(self._subscriptions) do
            MainPlayerData:Unsubscribe(token)
        end
        self._subscriptions = nil
    end
end

function MainPlayer:setPetInfo(data)
    local petIcon = FGUI:GetChild(self._ui.petPro,"petIcon")
    if data.icon then
        FGUI:setVisible(self._ui.petPro,true)
        FGUI:GLoader_setUrl(petIcon,"ui://Main/"..data.icon)
    else
        FGUI:setVisible(self._ui.petPro,false)
    end
    
    self:showPetPro(data)
end

function MainPlayer:showPetPro(data)
    if data.type=="red" then
        --50%以上
        local one = FGUI:GetChild(self._ui.petPro,"one") 
        --50%以下
        local two = FGUI:GetChild(self._ui.petPro,"two") 
        local per = data.now * 100 / data.max
        if per >= 50 then
            FGUI:GImage_setFillAmount(one, (per / 50) - 1 )
            FGUI:GImage_setFillAmount(two, 1)
        else
            FGUI:GImage_setFillAmount(one, 0)
            FGUI:GImage_setFillAmount(two, (per/50))
        end
    end 
end

function MainPlayer:petResurrec(data)
    -- print('MainPlayer:petResurrec======================',data)
    local fhtextbg = FGUI:GetChild(self._ui.petPro,"n10")
    local fhtext = FGUI:GetChild(self._ui.petPro,"n11")
    local fhtext2 = FGUI:GetChild(self._ui.petPro,"n12")
    if data > 0 then
        if self.dsqfh then
            SL:UnSchedule(self.dsqfh)
            self.dsqfh = nil
        end
        self.time = data
        local function realivedjs()
            local times =  SL:GetValue("SERVER_TIME")*1000 - self.time
            local min = tonumber(SysConstant["PET_Resurre_CD"].Value) - math.floor(times/1000)
            if min > 0  then
                FGUI:GTextField_setText(fhtext, min.."s")
                FGUI:setVisible(fhtextbg,true)
                FGUI:setVisible(fhtext,true)
                FGUI:setVisible(fhtext2,true)
            else
                SL:UnSchedule(self.dsqfh)
                self.dsqfh = nil
                FGUI:GTextField_setText(fhtext, min.."s")
                FGUI:setVisible(fhtextbg,false)
                FGUI:setVisible(fhtext,false)
                FGUI:setVisible(fhtext2,false)
                ssrMessage:sendmsgEx("mountMain", "fhpet")
            end
        end
        self.dsqfh = SL:Schedule(realivedjs,1)
    else
        if self.dsqfh then
            SL:UnSchedule(self.dsqfh)
            self.dsqfh = nil
        end
        FGUI:setVisible(fhtextbg,false)
        FGUI:setVisible(fhtext,false)
        FGUI:setVisible(fhtext2,false)
    end
end

--------------------------------------------------------

function MainPlayer:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

function MainPlayer:InitModeDatas()
    self._modes = {}
    
    local serverList = SL:GetValue("SERVER_PKMODE_LIST")
    local config = serverList
    if not config then 
        config = SL:GetValue("PKMODE_CONFIG")
    end
    if not config then return end
    
    for k, v in pairs(config) do
        table.insert(self._modes, v)
    end
    if #self._modes > 2 then
        table.sort(self._modes, function(a,b)
            if not a.Order or not b.Order then
                return false
            end
            return a.Order < b.Order
        end)
    end
end

function MainPlayer:InitComboId()
    local isCK = SL:GetValue("JOB") == 3
    if isCK then
        self.comboId = tonumber(SL:GetValue("GAME_DATA", "ComboPointId"))
    else
        self.comboId = nil
    end
end

function MainPlayer:UpdatePropertys()
    --刺客特殊显示
    local controller = FGUI:getController(self.component, "job")
    local isCK = SL:GetValue("JOB") == 3
    FGUI:Controller_setSelectedIndex(controller, isCK and 1 or 0)
    self:InitComboId()
    self:UpdateCombo()

    self:UpdateHead()
    self:UpdateHP()
    self:UpdateMP()
    self:UpdateAnger()
    self:UpdateLevel()
    self:UpdatePKMode()
end

function MainPlayer:UpdateCombo()
    if not self.comboId then return end
    local curV = SL:GetValue("CUR_ATTR_BY_ID", self.comboId)
    local maxV = SL:GetValue("MAX_ATTR_BY_ID", self.comboId)
    --更新上限值
    if self.comboMaxV ~= maxV then
        self.comboMaxV = maxV
        local allW, allH = FGUI:getSize(self._ui.Node_combos)
        local space = 3
        local width = (allW - (maxV - 1) * space) / maxV
        local x = 0
        local max = math.max(1, maxV)
        for i = 1, max do
            if i > maxV then
                local img = self.imageCombos[i]
                if img then
                    self.imageCombos[i] = nil
                    FGUI:RemoveFromParent(img, true)
                end
            else
                local img = self.imageCombos[i]
                if not img then
                    img = FGUI:CreateObject(self._ui.Node_combos, "Main", "main_player_combo")
                    self.imageCombos[i] = img
                    FGUI:setVisible(img, false)
                end
                FGUI:setSize(img, width, allH)
                FGUI:setPositionX(img, x)
                x = x + width + space
            end
        end
    end

    if self.comboCurV ~= curV then 
        local max = math.max(self.comboCurV, curV)
        local min = math.max(math.min(self.comboCurV, curV), 1)
        self.comboCurV = curV
        for i = min, max, 1 do
            local img = self.imageCombos[i]
            if img then
                FGUI:setVisible(img, i <= curV)
            end
        end
    end
end

function MainPlayer:UpdateProperty()
    self:UpdateAnger()
    self:UpdateCombo()
end

function MainPlayer:touchAreaClicked()
    self._ctrl_isShowBufList.selectedIndex = 1
    self:CleanSchedule()
end

function MainPlayer:UpdateHead()
    local data = {}
    data.AvatarID = SL:GetValue("AVATAR")
    data.Job  = SL:GetValue("JOB")
    data.Sex = SL:GetValue("SEX")
    data.FrameID = SL:GetValue("AVATAR_FRAME_DATA")
    FGUIFunction:SetCommonPlayerFrame(self._ui.player_icon,data)
end

function MainPlayer:UpdateHP(hp, maxHp)
    hp = hp or SL:GetValue("HP")
    maxHp = maxHp or SL:GetValue("MAXHP")
    if hp == self._curHP and maxHp == self._maxHP then return end
    self._curHP = hp
    self._maxHP = maxHp
    FGUI:GTextField_setText(self._ui.Text_hp, hp .. "/" .. maxHp)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_hp, hp / maxHp * 100)
end

function MainPlayer:UpdateMP(mp, maxMp)
    mp = mp or SL:GetValue("MP")
    maxMp = maxMp or SL:GetValue("MAXMP")
    if mp == self._curMP and maxMp == self._maxMP then return end
    self._curMP = mp
    self._maxMP = maxMp
    FGUI:GTextField_setText(self._ui.Text_mp, mp .. "/" .. maxMp)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_mp, mp / maxMp * 100)
end

function MainPlayer:UpdateAnger()
    local cur = SL:GetValue("MAX_ATTR_BY_ID", SLDefine.ATTRIBUTE.ANGER) or 0
	local max = 1000
    max = max > 0 and max or 1
    local v = cur / max * 100
    if v == self._angerProV then return end
    if self._angerProV < 100 and v >= 100 then
        FGUI:UIModel_addFx(self._ui.Graph_angerEffect, 100040, true, nil, nil, {x = 0.5, y = 0.5, z = 0.5})
    elseif self._angerProV >= 100 and v < 100 then
        FGUI:UIModel_clear(self._ui.Graph_angerEffect)
    end
    self._angerProV = v
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_anger, v)
end

function MainPlayer:UpdatePKMode()
    local pkMode = SL:GetValue("PKMODE")
    local cfg = SL:GetValue("PKMODE_CONFIG_BY_ID", pkMode)
    local id = cfg and cfg.ID or 0
    FGUI:GLoader_setUrl(self._ui.Loader_mode, "ui://Main/main_player_mode" .. id)

end

function MainPlayer:UpdateLevel()
    local lv = SL:GetValue("LEVEL")
    FGUI:GTextField_setText(self._ui.Text_lv, tostring(lv))
end

function MainPlayer:OnClickPlayer()
    SL:SetValue("SELECT_TARGET_ID", SL:GetValue("USER_ID"))
end

function MainPlayer:OpenRole()
    FGUI:Open("Bag","PlayerInfoPanel",2)
end

function MainPlayer:OnOpenModeSetting()
    FGUI:Open("Main","ModeSetting")
end

-- 主角buff显示
function MainPlayer:UpdateMyBuffs()
    self._myBuffDatas = SL:GetMetaValue("ACTOR_BUFF_DATA")
    self:RefreshListBuff()
end

function MainPlayer:ListBuffIconItemRender(idx,cell)
    if not cell then
        return
    end
    
    local index = idx
    local gloader_buff_icon = FGUI:GetChild(cell,"buffIcon_loader")
    
    local curBuffData = self._myBuffDatas[self.buffCounts - index]
    if curBuffData.id then
        local iconPath = SL:GetValue("BUFF_ICON_PATH_BY_ID",curBuffData.id)
        FGUI:GLoader_setUrl(gloader_buff_icon,iconPath,nil,true)
    end
end


function MainPlayer:ListBuffItemRender(idx,cell)
    if not cell then
        return
    end

    local index = idx
    local countTotal = table.nums(self._myBuffDatas)
    local text_buff_name = FGUI:GetChild(cell,"text_buff_name")
    local text_buff_tip = FGUI:GetChild(cell,"text_buff_tip")
    local text_buff_time = FGUI:GetChild(cell,"text_buff_time")
    local comp = FGUI:GetChild(cell,"buff_icon")
    local gloader_buff_icon = FGUI:GetChild(comp,"buffIcon_loader")
    local curBuffData = self._myBuffDatas[countTotal-index]
    FGUI:GTextField_setUBBEnabled(text_buff_tip, true)

    if curBuffData.id then
        local iconPath = SL:GetValue("BUFF_ICON_PATH_BY_ID",curBuffData.id)
        FGUI:GLoader_setUrl(gloader_buff_icon,iconPath,nil,true)
    end

    if curBuffData.config.Name then
        FGUIFunction:ScrollText_setString(text_buff_name, curBuffData.config.Name,1, 0)
    else
        FGUI:GTextField_setText(text_buff_name,"")
    end

    if curBuffData.config.Tips then
        FGUI:GTextField_setText(text_buff_tip,curBuffData.config.Tips)
    else
        FGUI:GTextField_setText(text_buff_tip,"")
    end

    if self._scheduleSet[curBuffData.id] then
        SL:UnSchedule(self._scheduleSet[curBuffData.id])
        self._scheduleSet[curBuffData.id] = nil
    end
    if curBuffData.endTime then
        local callBack = function()
            if curBuffData.endTime - SL:GetValue("SERVER_TIME") <= 0 then
                if self._scheduleSet[curBuffData.id] then
                    SL:UnSchedule(self._scheduleSet[curBuffData.id])
                    self._scheduleSet[curBuffData.id] = nil
                end
                FGUI:GTextField_setText(text_buff_time,"")
            else
                local leftTime = SL:SecondToHMS(math.ceil(curBuffData.endTime - SL:GetValue("SERVER_TIME")),true, true)
                FGUI:GTextField_setText(text_buff_time,leftTime)

            end
        end

        self._scheduleSet[curBuffData.id] = SL:Schedule(callBack, 1)
        callBack()
    else
        FGUI:GTextField_setText(text_buff_time,"")
    end
end

function MainPlayer:CleanSchedule()
    for k,v in pairs(self._scheduleSet) do
        SL:UnSchedule(v)
    end

    self._scheduleSet = {}
end

function MainPlayer:OnClickBuffIconItem(eventData)
    self:RefreshListBuff(true)
end

function MainPlayer:RefreshListBuff(isFromClicked)
    self:CleanSchedule()
    self.buffCounts = table.nums(self._myBuffDatas) > 10 and 10 or table.nums(self._myBuffDatas)
    FGUI:GList_setNumItems(self._ui.list_buff_icon,self.buffCounts)
    if self._ctrl_isShowBufList.selectedIndex == 0 then
        if self.buffCounts > 0 then
            FGUI:GList_setNumItems(self._ui.list_buff,table.nums(self._myBuffDatas))
        else
            self._ctrl_isShowBufList.selectedIndex = 1
        end
    else
        if isFromClicked then
            if self.buffCounts > 0 then
                self._ctrl_isShowBufList.selectedIndex = 0
                FGUI:GList_setNumItems(self._ui.list_buff,table.nums(self._myBuffDatas))
            end
        end     
    end
end

function MainPlayer:OnUpdateHead(actorID)
    if SL:GetValue("USER_ID") ~= actorID then return end
    self:UpdateHead()
end

-----------------------------------注册事件--------------------------------------
function MainPlayer:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainPlayer", handler(self, self.UpdatePropertys))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "MainPlayer", handler(self, self.UpdateProperty))
    SL:RegisterLUAEvent(LUA_EVENT_HP_CHANGE, "MainPlayer", handler(self, self.UpdateHP))
    SL:RegisterLUAEvent(LUA_EVENT_MP_CHANGE, "MainPlayer", handler(self, self.UpdateMP))
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainPlayer", handler(self, self.UpdateLevel))
    SL:RegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "MainPlayer", handler(self, self.UpdatePKMode))
    SL:RegisterLUAEvent(LUA_EVENT_MAIN_BUFF_UPDATE,"MainPlayer",handler(self, self.UpdateMyBuffs))
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"MainPlayer",handler(self, self.OnUpdateHead))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"MainPlayer",handler(self, self.OnUpdateHead))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"MainPlayer",handler(self, self.OnUpdateHead))
end

function MainPlayer:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "MainPlayer")
	SL:UnRegisterLUAEvent(LUA_EVENT_HP_CHANGE, "MainPlayer")
	SL:UnRegisterLUAEvent(LUA_EVENT_MP_CHANGE, "MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIN_BUFF_UPDATE,"MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"MainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"MainPlayer")
end


return MainPlayer