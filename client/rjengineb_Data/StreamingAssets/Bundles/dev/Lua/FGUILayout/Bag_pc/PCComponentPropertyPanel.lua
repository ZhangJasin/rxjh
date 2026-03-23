---@diagnostic disable: undefined-field
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCComponentPropertyPanel = class("PCComponentPropertyPanel", BaseFGUILayout)

--角色属性组件
function PCComponentPropertyPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._pageList = {}
    self._tradingIndex = nil
    self:GetAllFGuiData()
    self:InitUI()
end

function PCComponentPropertyPanel:InitUI()
    self._pageList[1] = FGUI:CreateObject(self.list_property,"Bag_pc","page1")
    self._pageList[2] = FGUI:CreateObject(self.list_property,"Bag_pc","page2")
    self._pageList[3] = FGUI:CreateObject(self.list_property,"Bag_pc","page3")
    self._pageList[4] = FGUI:CreateObject(self.list_property,"Bag_pc","page5")
    self._pageList[5] = FGUI:CreateObject(self.list_property,"Bag_pc","page4")
end

function PCComponentPropertyPanel:ClearPageList()
    for k,v in pairs(self._pageList) do
        if v then
            FGUI:RemoveFromParent(v,false)
        end
    end

    self._pageList = {}
end


function PCComponentPropertyPanel:RefreshPropertyPage()
    if self._pageList[1] then
        local page1 = self._pageList[1]
        local mingZi = FGUI:GetChild(page1,"mingZi")
        self:SetValueInText(mingZi,GET_STRING(30000041),FGUIFunction:GetServerName(SL:GetValue("USER_NAME")) or "")
    end

    if self._pageList[2] then
        local page2 = self._pageList[2]
        local transformConfig = SL:GetMetaValue("TRANSFER_MAINPLAYER_CONFIG")
        local mingSheng = ""
        if transformConfig and transformConfig.TransferLV then
            local transferLV = transformConfig.TransferLV == 0 and "" or " [".. GET_STRING(5000 + transformConfig.TransferLV) .."]"
            mingSheng = transformConfig.TransferName .. transferLV
        end

        local showCampStr = ""
        local goodDevilID = tonumber(SL:GetValue("GOODEVILID"))
        if goodDevilID == 0 then
            showCampStr = GET_STRING(30000040)
        elseif goodDevilID == 1 then
            showCampStr = GET_STRING(70000105)
        else
            showCampStr = GET_STRING(70000106)
        end

        local Shili = FGUI:GetChild(page2,"Shili")
        local mingShengComp = FGUI:GetChild(page2,"mingSheng")
        local dengJi = FGUI:GetChild(page2,"dengJi")
        local liLian = FGUI:GetChild(page2,"liLian") 
        self:SetValueInText(Shili,GET_STRING(30000042),showCampStr)
        self:SetValueInText(mingShengComp,GET_STRING(30000043),mingSheng)
        self:SetValueInText(dengJi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.LEVEL),SL:GetValue("LEVEL") or "")
        self:SetValueInText(liLian,GET_STRING(30000044),SL:GetValue("MONEY", 7) or "")
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
        self:SetProgressBar(processHp,"hpBar",SL:GetValue("HP"),SL:GetValue("MAXHP"),1)
        self:SetProgressBar(processNeiLi,"hpNeiLi",SL:GetValue("MP"),SL:GetValue("MAXMP"),1)
        self:SetProgressBar(processExp,"hpExp",SL:GetValue("EXP"),SL:GetValue("MAXEXP"),1)
        self:SetProgressBar(processNuqi,"hpNuqi",SL:GetValue("MAX_ATTR_BY_ID",SLDefine.ATTRIBUTE.ANGER),1000,2)
    end

    if self._pageList[4] then
        local page5 = self._pageList[4]
        local com_wuxun = FGUI:GetChild(page5,"wuxun")
        local com_shane = FGUI:GetChild(page5,"shane")
        -- 武勋
        self:SetValueInText(com_wuxun,GET_STRING(30000103),SL:GetValue("MONEY",8) or 0)
        -- 善恶值 
        self:SetValueInText(com_shane,GET_STRING(30000102),SL:GetValue("PKVALUE") or 0)
    end

    if self._pageList[5] then
        local page4 = self._pageList[5]
        self.attrDymicLoadTable = SL:GetValue("ATTR_BASE_ON_PLAYER")
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
    if self._tradingIndex == 2 then--九九交易行使用 下拉到list底部截图
        FGUI:GList_scrollToView(self.list_property, 4, false, false)
    end
end

function PCComponentPropertyPanel:GetAllFGuiData()
    self.list_property = self._ui.list_property
end

function PCComponentPropertyPanel:SetValueInText(component,attrName,attValue,showStr)
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

function PCComponentPropertyPanel:setTouch(comp,showStr)
    local beginFunc = function (eventData)
        FGUIFunction:OpenAttrTips(showStr,comp)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
    end

    local endFunc = function (eventData)
    end
    FGUI:setOnTouchEvent(comp,beginFunc,moveFunc,endFunc)
end

function PCComponentPropertyPanel:AttrItemRender(idx, item)
    local attrData = self.attrDymicLoadTable[idx+1] 
    self:SetValueInText(item,attrData.data.Name,attrData.value,attrData.data.Desc)
end

-- 进度条设置数值和进度
function PCComponentPropertyPanel:SetProgressBar(component,barName,currentValue,maxValue,mode)
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

function PCComponentPropertyPanel:Enter(tradingIndex)
    self._tradingIndex = tradingIndex
    self:RefreshPropertyPage()
    self:RegisterEvent()
    SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoProperty, self._ui.Node_attach)
end

function PCComponentPropertyPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoProperty)
    self:RemoveEvent()
end

function PCComponentPropertyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "PCComponentPropertyPanel",handler(self, self.RefreshPropertyPage))
end

function PCComponentPropertyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE,"PCComponentPropertyPanel")
end


return PCComponentPropertyPanel