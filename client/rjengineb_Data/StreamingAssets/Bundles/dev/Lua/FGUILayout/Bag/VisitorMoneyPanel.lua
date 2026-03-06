local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorMoneyPanel = class("VisitorMoneyPanel", BaseFGUILayout)

--角色属性组件
function VisitorMoneyPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._page = {}
    self:InitUI()
end

function VisitorMoneyPanel:InitUI()
    self.list_property = self._ui.list_property
    self._page = FGUI:CreateObject(self.list_property,"Bag","page4")
end

function VisitorMoneyPanel:ClearPageList()
    for k,v in pairs(self._pageList) do
        if v then
            FGUI:RemoveFromParent(v,false)
        end
    end
    self._pageList = {}
end

function VisitorMoneyPanel:RefreshPropertyPage()
    self.attrDymicLoadTable = SL:GetValue("VISITOR_MONEY_DATA")
    if self._page then
        local list_attr = FGUI:GetChild(self._page,"list_attr")
        local column = FGUI:GList_getColumnCount(list_attr)
        local itemHeight = 32
        local lines = math.ceil(#self.attrDymicLoadTable/column)
        FGUI:GList_setLineCount(list_attr, lines)
        local height = lines * itemHeight + lines * FGUI:GList_getLineGap(list_attr)
        FGUI:setHeight(list_attr,height)
        FGUI:GList_itemRenderer(list_attr,handler(self,self.AttrItemRender))
        FGUI:GList_setNumItems(list_attr,table.count(self.attrDymicLoadTable))
    end
end

function VisitorMoneyPanel:SetValueInText(component,attrName,attValue)
    local mask = FGUI:GetChild(component,"mask")
    local attrNameComp = FGUI:GetChild(component,"text_name_attr")
    local textScroll = FGUI:GetChild(component,"text_value_attr")
    FGUI:GTextField_setText(attrNameComp,attrName)
    FGUI:GTextField_setText(textScroll,attValue or 0)
end

function VisitorMoneyPanel:AttrItemRender(idx, item)
    local attrData = self.attrDymicLoadTable[idx+1] 
    self:SetValueInText(item,attrData.name,attrData.v)
end

-- 进度条设置数值和进度
function VisitorMoneyPanel:SetProgressBar(component,barName,currentValue,maxValue,mode)
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

function VisitorMoneyPanel:Enter()
    self:RefreshPropertyPage()
end

function VisitorMoneyPanel:Exit()
end

return VisitorMoneyPanel