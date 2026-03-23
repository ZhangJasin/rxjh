local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCPropertyBar = class("PCPropertyBar", BaseFGUILayout)

function PCPropertyBar:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function PCPropertyBar:GetAllFGuiData()
    self.comProperty = self._ui.comProperty
end

function PCPropertyBar:InitOnClickEvent()
end

function PCPropertyBar:OnClose()
end

function PCPropertyBar:InitUI()
    self._pageList = {}
    self._pageList[1] = FGUI:CreateObject(self.comProperty,"Bag_pc","page_pc_"..1)
    self._pageList[2] = FGUI:CreateObject(self.comProperty,"Bag_pc","page_pc_"..2)
    self._pageList[3] = FGUI:CreateObject(self.comProperty,"Bag_pc","page_pc_"..3)
    self._pageList[4] = FGUI:CreateObject(self.comProperty,"Bag_pc","page_pc_"..5)
    self._pageList[5] = FGUI:CreateObject(self.comProperty,"Bag_pc","page_pc_"..4)
end

function PCPropertyBar:RefreshPropertyPage()
    if self._pageList[1] then
        local page1 = self._pageList[1]
        local nickNameComp = FGUI:GetChild(page1,"nickNameComp")
        self:SetValueInText(nickNameComp,GET_STRING(30000041),SL:GetValue("USER_NAME") or "")
    end
    

    if self._pageList[2] then
        local shiliComp = FGUI:GetChild(self._pageList[2],"shili")
        local dengjiComp = FGUI:GetChild(self._pageList[2],"dengji")
        local mingshengComp = FGUI:GetChild(self._pageList[2],"mingsheng")
        local lilianComp = FGUI:GetChild(self._pageList[2],"lilian")

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

        self:SetValueInText(shiliComp,GET_STRING(30000042),showCampStr or "")
        self:SetValueInText(mingshengComp,GET_STRING(30000043),mingSheng or "")
        self:SetValueInText(dengjiComp,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.LEVEL),SL:GetValue("LEVEL") or "")
        self:SetValueInText(lilianComp,GET_STRING(30000044),SL:GetValue("MONEY", 7) or "")
    end

    if self._pageList[3] then
        local page3 = self._pageList[3]
        local processHp = FGUI:GetChild(page3,"hp")
        local processNeiLi = FGUI:GetChild(page3,"mp")
        local processExp = FGUI:GetChild(page3,"exp")
        local processNuqi = FGUI:GetChild(page3,"nuqi")
        self:SetValueInProgress(processHp,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.HP),SL:GetValue("HP"),SL:GetValue("MAXHP"),1,0)
        self:SetValueInProgress(processNeiLi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.MP),SL:GetValue("MP"),SL:GetValue("MAXMP"),1,1)
        self:SetValueInProgress(processExp,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.EXP),SL:GetValue("EXP"),SL:GetValue("MAXEXP"),1,2)
        self:SetValueInProgress(processNuqi,SL:GetValue("ATTR_CONFIG_NAME_BY_ID", SLDefine.ATTRIBUTE.ANGER),SL:GetValue("MAX_ATTR_BY_ID",SLDefine.ATTRIBUTE.ANGER),1000,1,3)
    end

    if self._pageList[4] then
        local page4 = self._pageList[4]
        local wuxun = FGUI:GetChild(page4,"wuxun")
        local shane = FGUI:GetChild(page4,"shane")
            
        self:SetValueInText(wuxun,GET_STRING(30000102),SL:GetValue("PKVALUE") or 0)
        self:SetValueInText(shane,GET_STRING(30000103),SL:GetValue("MONEY",8) or 0)
    end

    if self._pageList[5] then
        local page5 = self._pageList[5]
        self.attrDymicLoadTable = SL:GetValue("ATTR_BASE_ON_PLAYER")
        local list_attr = FGUI:GetChild(page5,"list_attr")
        local column = FGUI:GList_getColumnCount(list_attr)
        local itemHeight = 25
        local lines = math.ceil(#self.attrDymicLoadTable / column)
        FGUI:GList_setLineCount(list_attr, lines)
        local height = lines * itemHeight + (lines + 1) * FGUI:GList_getLineGap(list_attr)
        FGUI:setHeight(list_attr,height)
        FGUI:GList_itemRenderer(list_attr,handler(self,self.AttrItemRender))
        FGUI:GList_setNumItems(list_attr,table.count(self.attrDymicLoadTable))
        FGUI:setVisible(page5,table.count(self.attrDymicLoadTable) > 0)
    end
end


function PCPropertyBar:AttrItemRender(idx, item)
    local attrData = self.attrDymicLoadTable[idx+1]
    self:SetValueInText(item,attrData.data.Name,attrData.value)
end

function PCPropertyBar:SetValueInProgress(comp,name,currentValue,maxValue,mode,ctrlValue)
    if not comp then
        return
    end

    local comName = FGUI:GetChild(comp,"comName")
    local textName = FGUI:GetChild(comName,"textName")
    FGUI:GTextField_setText(textName,name)
    local comProgress = FGUI:GetChild(comp,"comProgress")
    local ctrl = FGUI:getController(comProgress,"progressType")
    ctrl.selectedIndex = ctrlValue or 0
    local imageFill = FGUI:GetChild(comProgress,ctrl.selectedPage)
    if maxValue ~= 0 then
        fillAmount = tonumber(currentValue)/tonumber(maxValue)
    end
    FGUI:GImage_setFillAmount(imageFill,fillAmount)
    local compText = FGUI:GetChild(comProgress,"text_progress")
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

function PCPropertyBar:SetValueInText(comp,name,value)
    if not comp then
       return
    end
    local comName = FGUI:GetChild(comp,"comName")
    local textName = FGUI:GetChild(comName,"textName")
    local comValue = FGUI:GetChild(comp,"comValue")
    local textValue = FGUI:GetChild(comValue,"textValue")
    FGUI:GTextField_setText(textName,name)
    FGUI:GTextField_setText(textValue,value)
end

function PCPropertyBar:Enter()
    self:RefreshPropertyPage()
    self:RegisterEvent()
end

function PCPropertyBar:Exit()
    self:RemoveEvent()
end

function PCPropertyBar:RegisterEvent()
end
--移除事件
function PCPropertyBar:RemoveEvent()
end

return PCPropertyBar