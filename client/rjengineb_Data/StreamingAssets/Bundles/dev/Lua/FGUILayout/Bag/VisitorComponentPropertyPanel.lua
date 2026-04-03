local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorComponentPropertyPanel = class("VisitorComponentPropertyPanel", BaseFGUILayout)

--角色属性组件
function VisitorComponentPropertyPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._pageList = {}
    self:GetAllFGuiData()
    self:InitUI()
end

function VisitorComponentPropertyPanel:InitUI()
    self._pageList[1] = FGUI:CreateObject(self.list_property,"Bag","page1")
    self._pageList[2] = FGUI:CreateObject(self.list_property,"Bag","page2")
    self._pageList[3] = FGUI:CreateObject(self.list_property,"Bag","page3")
    self._pageList[4] = FGUI:CreateObject(self.list_property,"Bag","page5")
    self._pageList[5] = FGUI:CreateObject(self.list_property,"Bag","page4")
end

function VisitorComponentPropertyPanel:ClearPageList()
    for k,v in pairs(self._pageList) do
        if v then
            FGUI:RemoveFromParent(v,false)
        end
    end

    self._pageList = {}
end


function VisitorComponentPropertyPanel:RefreshPropertyPage()
    if self._pageList[1] then
        local page1 = self._pageList[1]
        local mingZi = FGUI:GetChild(page1,"mingZi")
        self:SetValueInText(mingZi,GET_STRING(30000041),SL:GetValue("VISITOR_NAME") or "")
    end
    if self._pageList[2] then
        local page2 = self._pageList[2]
        --job, goodDevilID, reLevel = self:_getMainPlayerJobTypeLevel()
        --local transformConfig = SL:GetMetaValue("TRANSFER_MAINPLAYER_CONFIG")
        local transformConfig = SL:GetValue("VISITOR_TRANSFER_MAINPLAYER_CONFIG",SL:GetValue("VISITOR_JOB") or 0, SL:GetValue("VISITOR_GOOD_DEBIL_ID") or 0,SL:GetValue("VISITOR_RE_LEVEL") or 0)
        local mingSheng = ""
        if transformConfig and transformConfig.TransferLV then
            local transferLV = transformConfig.TransferLV == 0 and "" or " [".. GET_STRING(5000 + transformConfig.TransferLV) .."]"
            if transformConfig.TransferName then
                mingSheng = transformConfig.TransferName .. transferLV
            end
        end
        --势力 无   名声 弓手
        --等级 1    历练 0
        local showCampStr = ""
        local goodDevilID = tonumber(SL:GetValue("VISITOR_GOOD_DEBIL_ID"))
        if goodDevilID == 0 then
            showCampStr = GET_STRING(30000040)
        elseif goodDevilID == 1 then
            showCampStr = GET_STRING(70000105)
        else
            showCampStr = GET_STRING(70000106)
        end
        if mingSheng == "" or mingSheng == nil then
            mingSheng = GET_STRING(30000040)
        end
        local level = tostring(SL:GetValue("VISITOR_CUR_LEVEL")) or ""
        local Shili = FGUI:GetChild(page2,"Shili")
        local mingShengComp = FGUI:GetChild(page2,"mingSheng")
        local dengJi = FGUI:GetChild(page2,"dengJi")
        local liLian = FGUI:GetChild(page2,"liLian") 
        self:SetValueInText(Shili,GET_STRING(30000042),showCampStr)
        self:SetValueInText(mingShengComp,GET_STRING(30000043),mingSheng)
        self:SetValueInText(dengJi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.LEVEL),level)

        local money = tostring(tostring(SL:GetValue("VISITOR_MONEY_BY_ID",7) or 0) or 0)
        self:SetValueInText(liLian,GET_STRING(30000044),money)
    end

    if self._pageList[3] then
        local page3 = self._pageList[3]
        local item_attr_hp   = FGUI:GetChild(page3,"item_attr_hp")
        local item_attr_mp   = FGUI:GetChild(page3,"item_attr_mp")
        local item_attr_exp  = FGUI:GetChild(page3,"item_attr_exp")
        local item_attr_nuqi = FGUI:GetChild(page3,"item_attr_nuqi")
        local processHp      = FGUI:GetChild(item_attr_hp,"progress")
        local processNeiLi   = FGUI:GetChild(item_attr_mp,"progress")
        local processExp     = FGUI:GetChild(item_attr_exp,"progress")
        local processNuqi    = FGUI:GetChild(item_attr_nuqi,"progress")

        local hp        = SL:GetValue("VISITOR_HP") or 0
        local maxhp     = SL:GetValue("VISITOR_MAXHP") or 0
        local mp        = SL:GetValue("VISITOR_MP") or 0
        local maxmp     = SL:GetValue("VISITOR_MAXMP") or 0
        local maxattId  = SL:GetValue("VISITOR_MAX_ATTR_BY_ID",SLDefine.ATTRIBUTE.ANGER) or 0
        local exp       = SL:GetValue("VISITOR_EXP") or 0
        local maxexp    = SL:GetValue("VISITOR_MAXEXP") or 0

        self:SetProgressBar(processHp,"hpBar",hp,maxhp,1)
        self:SetProgressBar(processNeiLi,"hpNeiLi",mp,maxmp,1)
        self:SetProgressBar(processExp,"hpExp",exp,maxexp,1)
        self:SetProgressBar(processNuqi,"hpNuqi",maxattId,1000,2)
    end

    if self._pageList[4] then
        local page5 = self._pageList[4]
        local com_wuxun = FGUI:GetChild(page5,"wuxun")
        local com_shane = FGUI:GetChild(page5,"shane")
        -- 武勋
        local wuxun = tostring(SL:GetValue("VISITOR_MONEY_BY_ID", 8) or 0)
        self:SetValueInText(com_wuxun,GET_STRING(30000103),wuxun)
        -- 善恶值 
        self:SetValueInText(com_shane,GET_STRING(30000102), SL:GetValue("VISITOR_PK_POINT") or 0)
    end

    if self._pageList[5] then
        local page4 = self._pageList[5]
        self.attrDymicLoadTable = SL:GetValue("VISITOR_ATTR_BASE_ON_PLAYER")
        local list_attr = FGUI:GetChild(page4,"list_attr")
        local column = FGUI:GList_getColumnCount(list_attr)
        local itemHeight = 32
        local lines = math.ceil(#self.attrDymicLoadTable/column)
        FGUI:GList_setLineCount(list_attr, lines)
        local height = lines * itemHeight + lines * FGUI:GList_getLineGap(list_attr)
        FGUI:setHeight(list_attr,height)
        FGUI:GList_itemRenderer(list_attr,handler(self,self.AttrItemRender))
        FGUI:GList_setNumItems(list_attr,table.count(self.attrDymicLoadTable))
        FGUI:setVisible(self._pageList[4],table.count(self.attrDymicLoadTable) > 0)
    end
   
end
 
function VisitorComponentPropertyPanel:GetAllFGuiData()
    self.list_property = self._ui.list_property
end

function VisitorComponentPropertyPanel:SetValueInText(component,attrName,attValue,showStr)
    local mask = FGUI:GetChild(component,"mask")
    local attrNameComp = FGUI:GetChild(component,"text_name_attr")
    local textScroll = FGUI:GetChild(component,"text_value_attr")
    FGUI:GTextField_setText(attrNameComp,attrName)
    FGUI:GTextField_setText(textScroll,attValue or 0)

    if not string.isNullOrEmpty(showStr) and mask then
        FGUI:setOnClickEvent(mask,function(eventData)
            FGUIFunction:OpenAttrTips(showStr,mask)
        end)
    end
end

function VisitorComponentPropertyPanel:AttrItemRender(idx, item)
    local attrData = self.attrDymicLoadTable[idx+1]
    local value = attrData.value

    -- Type==1为百分比类型，去掉小数点（如 "0.0%" -> "0%"）
    if attrData.data.Type == 1 and value then
        value = string.match(value, "^([0-9]+)%.?.*")
        if value then
            value = value .. "%"
        end
    end

    self:SetValueInText(item,attrData.data.Name,value,attrData.data.Desc)
end

-- 进度条设置数值和进度
function VisitorComponentPropertyPanel:SetProgressBar(component,barName,currentValue,maxValue,mode)
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

function VisitorComponentPropertyPanel:Enter()
    self:RefreshPropertyPage()
    SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorPlayerInfoProperty, self._ui.Node_attach)
end

function VisitorComponentPropertyPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorPlayerInfoProperty)
end

return VisitorComponentPropertyPanel