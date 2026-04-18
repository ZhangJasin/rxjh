local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCLookPlayerPanel = class("PCLookPlayerPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local IDX_PROPERTY = 0
local IDX_TITLE = 1
local MODEL_SCALE = 0.7

function PCLookPlayerPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)
    -- FGUI:SetCloseUIWhenClickOutside(self)
    self._pageList = {}
    self:GetAllFGuiData()
    self:InitUI()
    self:InitOnClickEvent()
end

function PCLookPlayerPanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.panel_equip = self._ui.panel_equip
    self.panel_property = self._ui.panel_property
    self.panel_title = self._ui.panel_title
    self.panel_touch = FGUI:GetChild(self.panel_equip,"panel_touch")
    self.model_root = FGUI:GetChild(self.panel_equip,"model_root")
    self.list_property = FGUI:GetChild(self.panel_property,"list_property")
    self.list_title = FGUI:GetChild(self.panel_title,"list_title")
    self.btn_tab_1 = self._ui.btn_tab_1
    self.btn_tab_2 = self._ui.btn_tab_2

    self.ctrl_tab_1 = FGUI:getController(self.btn_tab_1,"isSelected")
    self.ctrl_tab_2 = FGUI:getController(self.btn_tab_2,"isSelected")
    self.ctrl_pageTo = FGUI:getController(self.component,"pageTo")
    self.ctrl_ModeWho = FGUI:getController(self.panel_title,"ModeWho")
end

function PCLookPlayerPanel:InitUI()
    self._pageList[1] = FGUI:CreateObject(self.list_property,"Bag_pc","page1")
    self._pageList[2] = FGUI:CreateObject(self.list_property,"Bag_pc","page2")
    self._pageList[3] = FGUI:CreateObject(self.list_property,"Bag_pc","page3")
    self._pageList[4] = FGUI:CreateObject(self.list_property,"Bag_pc","page4")
    self.ctrl_ModeWho.selectedIndex = 1

    local tab_1_text = FGUI:GetChild(self.btn_tab_1,"text_content")
    FGUI:GTextField_setText(tab_1_text,GET_STRING(30000046))
    local tab_2_text = FGUI:GetChild(self.btn_tab_2,"text_content")
    FGUI:GTextField_setText(tab_2_text,GET_STRING(30000110))

    FGUI:GList_itemRenderer(self.list_title,handler(self,self.TitleItemRender))
    FGUI:GList_setVirtual(self.list_title)
end

function PCLookPlayerPanel:RefreshPropertyUI()
    if self._pageList[1] then
        local page1 = self._pageList[1]
        local mingZi = FGUI:GetChild(page1,"mingZi")
        self:SetValueInText(mingZi,GET_STRING(30000041),"")
    end

    if self._pageList[2] then
        local page2 = self._pageList[2]
        local Shili = FGUI:GetChild(page2,"Shili")
        local mingSheng = FGUI:GetChild(page2,"mingSheng")
        local dengJi = FGUI:GetChild(page2,"dengJi")
        local liLian = FGUI:GetChild(page2,"liLian")
        FGUI:setVisible(liLian,false)
        self:SetValueInText(Shili,GET_STRING(30000042),"")
        self:SetValueInText(mingSheng,GET_STRING(30000043),"")
        self:SetValueInText(dengJi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.LEVEL),"")
    end
    if self._pageList[3] then
        local page3 = self._pageList[3]
        local item_attr_hp = FGUI:GetChild(page3,"item_attr_hp")
        local item_attr_mp = FGUI:GetChild(page3,"item_attr_mp")
        local item_attr_exp = FGUI:GetChild(page3,"item_attr_exp")
        local item_attr_nuqi = FGUI:GetChild(page3,"item_attr_nuqi")
        local processHp = FGUI:GetChild(item_attr_hp,"progress")
        local processNeiLi = FGUI:GetChild(item_attr_mp,"progress")
        local processExp = FGUI:GetChild(item_attr_exp,"progress")
        local processNuqi = FGUI:GetChild(item_attr_nuqi,"progress")
        self:SetProgressBar(processHp,"hpBar",0,0,1)
        self:SetProgressBar(processNeiLi,"hpNeiLi",0,0,1)
        self:SetProgressBar(processExp,"hpExp",0,0,1)
        self:SetProgressBar(processNuqi,"hpNuqi",0,1000,2)
    end

    FGUI:setVisible(self._pageList[4],false)
end

function PCLookPlayerPanel:Destory()
    self:ClearPageList()
end

function PCLookPlayerPanel:ClearPageList()
    for k,v in pairs(self._pageList) do
        if v then
            FGUI:RemoveFromParent(v,false)
        end
    end
end

function PCLookPlayerPanel:SetValueInText(component,attrName,attValue,showStr)
    local mask = FGUI:GetChild(component,"mask")
    local attrNameComp = FGUI:GetChild(component,"text_name_attr")
    local textScroll = FGUI:GetChild(component,"text_value_attr")
    FGUI:GTextField_setText(attrNameComp,attrName)
    FGUI:GTextField_setText(textScroll,attValue)

    if not string.isNullOrEmpty(showStr) and mask then
        FGUI:setOnClickEvent(mask,function(eventData)
                FGUIFunction:OpenAttrTips(showStr,mask)
            end)
    end
end

function PCLookPlayerPanel:Enter(page)
    self:RegisterEvent()
    if not page then
        page = IDX_PROPERTY
    end
    
    self:InitData()
    self:PageTo(page)
end

function PCLookPlayerPanel:RefreshView()
    local data = SL:GetValue("L.M.PLAYER_DATA")
    if not data or not next(data) then
        return
    end

    self:UpdateRoleModel()
    self:UpdatePlayerEquip()

    if self.ctrl_pageTo.selectedIndex == IDX_PROPERTY then
        self:UpdatePlayerInfo()
    else
        self:RefreshTitleUI()
    end
end

function PCLookPlayerPanel:UpdatePlayerInfo()
    local data = SL:GetValue("L.M.PLAYER_DATA")
    if self._pageList[1] then
        local page1 = self._pageList[1]
        local mingZi = FGUI:GetChild(page1,"mingZi")

        self:SetValueInText(mingZi,GET_STRING(30000041),FGUIFunction:GetServerName(data.Name))
    end
    if self._pageList[2] then
        local page2 = self._pageList[2]
        local mingSheng = ""
        local transformConfig = SL:GetMetaValue("TRANSFER_CONFIG_BY_JOBTYPELV",data.Job,data.GoodEvilId,data.Relevel)
        if transformConfig and transformConfig.TransferLV then
            local transferLV = transformConfig.TransferLV == 0 and "" or " [".. GET_STRING(5000 + transformConfig.TransferLV) .."]"
            mingSheng = transformConfig.TransferName .. transferLV
        end

        local showCampStr = ""
        if data.GoodEvilId == 0 then
            showCampStr = GET_STRING(30000040)
        elseif data.GoodEvilId == 1 then
            showCampStr = GET_STRING(70000105)
        else
            showCampStr = GET_STRING(70000106)
        end

        local Shili = FGUI:GetChild(page2,"Shili")
        local mingShengComp = FGUI:GetChild(page2,"mingSheng")
        local dengJi = FGUI:GetChild(page2,"dengJi")
        local liLian = FGUI:GetChild(page2,"liLian")
        FGUI:setVisible(liLian,false)
        self:SetValueInText(Shili,GET_STRING(30000042),showCampStr)
        self:SetValueInText(mingShengComp,GET_STRING(30000043),mingSheng)
        self:SetValueInText(dengJi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.LEVEL),data.Level or "")
        -- self:SetValueInText(liLian,GET_STRING(30000044),data.LLPoint)
    end
    
    if self._pageList[3] then
        local page3 = self._pageList[3]
        local item_attr_hp = FGUI:GetChild(page3,"item_attr_hp")
        local item_attr_mp = FGUI:GetChild(page3,"item_attr_mp")
        local item_attr_exp = FGUI:GetChild(page3,"item_attr_exp")
        local item_attr_nuqi = FGUI:GetChild(page3,"item_attr_nuqi")
        local processHp = FGUI:GetChild(item_attr_hp,"progress")
        local processNeiLi = FGUI:GetChild(item_attr_mp,"progress")
        local processExp = FGUI:GetChild(item_attr_exp,"progress")
        local processNuqi = FGUI:GetChild(item_attr_nuqi,"progress")
        local hpData = data.Abil[2]
        self:SetProgressBar(processHp,"hpBar",hpData.curValue,hpData.maxValue,1)
        local mpData = data.Abil[3]
        self:SetProgressBar(processNeiLi,"hpNeiLi",mpData.curValue,mpData.maxValue,1)
        self:SetProgressBar(processExp,"hpExp",data.Exp,data.MaxExp,1)
        self:SetProgressBar(processNuqi,"hpNuqi",data.Abil[5].maxValue,1000,2)
    end

    if self._pageList[4] then
        FGUI:setVisible(self._pageList[4],false)
        local page4 = self._pageList[4]
        if data and data.Abil then
            self.attrDymicLoadTable = {}
            for k,v in pairs(data.Abil) do
                local cfg = SL:GetValue("ATTR_CONFIG",v.id)
                if cfg then
                    if v.id ~= SLDefine.ATTRIBUTE.HP and v.id ~= SLDefine.ATTRIBUTE.MP
                        and v.id ~= SLDefine.ATTRIBUTE.LEVEL and v.id ~= SLDefine.ATTRIBUTE.EXP
                        and v.id ~= SLDefine.ATTRIBUTE.ANGER and cfg.Isshow == 1 and cfg.Attribute == 0
                    then
                        local data = v
                        if not cfg.Name then
                            SL:PrintEx("[ERROR] attscore["..v.id.."]没有属性名字")
                        end
                        data.Name = cfg.Name or GET_STRING(30000054)
                        data.Sort = cfg.Sort
                        data.Desc = cfg.Desc
                        data.ShowValue = data.maxValue
                        if cfg.Type == 1 then
                            data.ShowValue = string.format("%.1f%%", data.maxValue / 100)
                        elseif cfg.Type == 0 then
                        else
                            SL:PrintEx("未知属性ID = "..v.id.."属性Type" .. cfg.Type)
                        end
                        table.insert(self.attrDymicLoadTable,data)
                    end
                end
            end

            table.sort(self.attrDymicLoadTable,function(a,b)
                if a.Sort and b.Sort then
                    return a.Sort < b.Sort
                end
            end)

            SL:print_t(self.attrDymicLoadTable)
            local list_attr = FGUI:GetChild(page4,"list_attr")
            local column = FGUI:GList_getColumnCount(list_attr)
            local itemHeight = 24
            local lines = math.ceil(#self.attrDymicLoadTable/column)
            FGUI:GList_setLineCount(list_attr, lines)
            local height = lines * itemHeight + lines * FGUI:GList_getLineGap(list_attr)
            FGUI:setHeight(list_attr,height)
            FGUI:GList_itemRenderer(list_attr,handler(self,self.AttrItemRender))
            FGUI:GList_setNumItems(list_attr,table.count(self.attrDymicLoadTable))
            FGUI:setVisible(self._pageList[4],table.count(self.attrDymicLoadTable) > 0)
        end
    end
end

function PCLookPlayerPanel:AttrItemRender(idx, item)
    local attrData = self.attrDymicLoadTable[idx+1]
    self:SetValueInText(item,attrData.Name,attrData.ShowValue,attrData.Desc)
end

-- 进度条设置数值和进度
function PCLookPlayerPanel:SetProgressBar(component,barName,currentValue,maxValue,mode)
    local compProgress = FGUI:GetChild(component,barName)
    local fillAmount = 0
    if maxValue ~= 0 then
        fillAmount = tonumber(currentValue)/tonumber(maxValue)
    end
    FGUI:GImage_setFillAmount(compProgress,fillAmount)
    local compText = FGUI:GetChild(component,"text_progress")
    if currentValue <= 0 then
        currentValue  = 0
    end
    if mode == 1 then
        FGUI:GTextField_setText(compText,currentValue.."/"..maxValue)
    else
        if maxValue == 0 then
            FGUI:GTextField_setText(compText,"0%")
        else    
            FGUI:GTextField_setText(compText,math.floor(currentValue*100/maxValue) .."%")
        end
    end
end

function PCLookPlayerPanel:Exit()
    self:RemoveEvent()
    self:ClearModel()
    self:ClearAllEquipItem()
    self:CleanSchedule()
end

function PCLookPlayerPanel:Close()
	self.super.Close(self)
end
function PCLookPlayerPanel:InitData()
    self.equipMentObjList = {}
    self._scheduleSet = {}
end

function PCLookPlayerPanel:InitOnClickEvent()
	FGUI:setOnClickEvent(self.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self.btn_tab_1, handler(self, self.BtnTab1Clicked))
    FGUI:setOnClickEvent(self.btn_tab_2, handler(self, self.BtnTab2Clicked))
end

function PCLookPlayerPanel:PageTo(index)
    self.ctrl_pageTo.selectedIndex = index
    self.ctrl_tab_1.selectedIndex = index == IDX_PROPERTY and 0 or 1
    self.ctrl_tab_2.selectedIndex = index == IDX_TITLE and 0 or 1

    self:RefreshView()
end

function PCLookPlayerPanel:RefreshTitleUI()
    self.titleData = SL:GetValue("L.M.PLAYER_TITLE") or {}
    FGUI:GList_setNumItems(self.list_title,table.count(self.titleData or {}))
end

function PCLookPlayerPanel:CleanSchedule()
    for k,v in pairs(self._scheduleSet) do
        if v then
            SL:UnSchedule(v)
            v = nil
        end
    end
end

function PCLookPlayerPanel:TitleItemRender(idx,item)
    local ctrl_state = FGUI:getController(item,"titleState")
    local ctrl_selected = FGUI:getController(item,"isSelected")
    local ctrl_isTimer = FGUI:getController(item,"isTimer")
    local time_left = FGUI:GetChild(item,"time_left")
    local gloader_title = FGUI:GetChild(item,"gloader_title")
    local ctrl_isShowPin = FGUI:getController(item,"isShowPin")
    local data = self.titleData[idx + 1]
    ctrl_isShowPin.selectedIndex = 0
    if self._scheduleSet[data.cfg.ID] then
        SL:UnSchedule(self._scheduleSet[data.cfg.ID])
        self._scheduleSet[data.cfg.ID] = nil
    end

    if data.isActive == false then
        ctrl_state.selectedIndex = 0
    elseif data.isActive == true and data.isUsed == false then
        ctrl_state.selectedIndex = 1
    elseif data.isActive == true and data.isUsed == true then
        ctrl_state.selectedIndex = 2
    end

    ctrl_selected.selectedIndex = 1
    if data.endTime and data.endTime > 0 then
        local callBack = function()
            local curTime  = SL:GetValue("SERVER_TIME") or 0
            if data.endTime - curTime <= 0 then
                if self._scheduleSet[data.cfg.ID] then
                    SL:UnSchedule(self._scheduleSet[data.cfg.ID])
                    self._scheduleSet[data.cfg.ID] = nil
                end
                FGUI:GTextField_setText(time_left,"")
                ctrl_isTimer.selectedIndex = 1
                FGUI:setVisible(item,false)
            else
                local leftTime = SecondToHMS(math.ceil(data.endTime - curTime),true, false)
                print("leftTime",leftTime)
                FGUI:GTextField_setText(time_left,leftTime)
                ctrl_isTimer.selectedIndex = 0
            end
        end
        
        FGUI:GTextField_setText(time_left,"")
        self._scheduleSet[data.cfg.ID] = SL:Schedule(callBack, 1)
    else
        ctrl_isTimer.selectedIndex = 1
        FGUI:GTextField_setText(time_left,"")
    end

    local url =  FGUIFunction:GetTitleIconURL(data.cfg.Icon)
    FGUI:GLoader_setUrl(gloader_title, url, nil, true)
end


function PCLookPlayerPanel:BtnTab1Clicked()
    self:PageTo(IDX_PROPERTY)
end

function PCLookPlayerPanel:BtnTab2Clicked()
    self:PageTo(IDX_TITLE)
end

function PCLookPlayerPanel:UpdatePlayerEquip()
    -- equips
    self:ClearAllEquipItem()
    local tEquipt = SL:GetValue("L.M.EQUIP_POS_DATAS") or {}
    print("玩家装备")
    SL:print_t(tEquipt)
    for pos, equip in pairs(tEquipt) do
        local equipData = SL:GetValue("L.M.EQUIP_BY_MAKEINDEX",equip.MakeIndex)
        if equipData then  
            if self.equipMentObjList[pos] then
                ItemUtil:ItemShow_Release(self.equipMentObjList[pos])
            end

            local parent = FGUI:GetChild(self.panel_equip,"pos"..(equip.Where + 1))
            if parent then
                self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent)
                if self.equipMentObjList[pos].hideArrow then
                    self.equipMentObjList[pos]:hideArrow()
                end
            end
        end
    end
end

-- 释放所有挂载的Item
function PCLookPlayerPanel:ClearAllEquipItem()
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self.equipMentObjList = {}
end

function PCLookPlayerPanel:ClearModel()
    if self._model then
        self:UIModel_Unbind(self.model_root)
    end
end

function PCLookPlayerPanel:UpdateRoleModel()
    self:ClearModel()
	self._model = self:UIModel_Bind(self.model_root)
	FGUI:UIModel_setObjectEulerAngles(self._model, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local lookSex = SL:GetValue("L.M.SEX")
    local lookJob = SL:GetValue("L.M.JOB")
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", lookJob)
    if classConfig then 
		faceId = FGUIFunction:GetFaceIDBySex(lookSex,classConfig)
    end 
    
    local modelData = SL:GetValue("L.M.PLAYER_MODEL")
    if modelData then 
		local extData = {}
		extData.sex = lookSex
    		extData.job = lookJob
		extData.bodyId = modelData.bodyId == 0 and bodyId or modelData.bodyId
		extData.helmetId = modelData.headId == 0 and helmetId or modelData.headId
        extData.weaponId = modelData.rWeapon == 0 and weaponId or modelData.rWeapon
        extData.wingId = modelData.wingId or 0
		extData.faceId = faceId
        self._modelIndex = FGUI:UIModel_addCharacterModel(
            self._model, extData, Vector3.New(0,0,0),nil,Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
    end
    FGUI:UIModel_setModelCallback(self._model, function(index)
        FGUI:UIModel_playAnimation(self._model, index, global.MMO.ANIM_IDLE, nil, 0)
        self:SetModelRotate(self.panel_touch)
    end)
end

function PCLookPlayerPanel:Destroy()
    self:ClearAllEquipItem()
end

-- 设置模型旋转
function  PCLookPlayerPanel:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    local beginFunc = function (eventData)
        if not self._model then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._model:GetObjectEulerAngles(self._modelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._model then
            return
        end
        local distanceMax = 1000
        local distence = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self._model:SetObjectEulerAngles(0, angle, 0, self._modelIndex)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

-----------------------------------注册事件--------------------------------------
function PCLookPlayerPanel:RegisterEvent() 
end

function PCLookPlayerPanel:RemoveEvent()
end

return PCLookPlayerPanel