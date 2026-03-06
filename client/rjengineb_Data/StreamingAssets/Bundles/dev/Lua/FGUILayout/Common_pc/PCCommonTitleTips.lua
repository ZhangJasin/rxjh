local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCCommonTitleTips = class("PCCommonTitleTips", BaseFGUILayout)
local CELL_HEIGHT = 32


function PCCommonTitleTips:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitData()
end

function PCCommonTitleTips:GetAllFGuiData()
    self.panel = self._ui.panel
    self.mask = self._ui.mask
    self.list_attrbute = FGUI:GetChild(self.panel,"list_attrbute")
    self.text_titleName = FGUI:GetChild(self.panel,"text_titleName")
    self.text_getWayDetail = FGUI:GetChild(self.panel,"text_getWayDetail")
    self.ctrl_Attribute_mode = FGUI:getController(self.panel,"Attribute_mode")
    self.ctrl_isHaveAttribute = FGUI:getController(self.panel,"isHaveAttribute")

    FGUI:GList_itemRenderer(self.list_attrbute,handler(self,self.TitleAttributeItemRender))
end

function PCCommonTitleTips:InitData()
    self.attrData = {}
end


-- data.itemID    对饮itemEquip配置中的ID
-- data.titleCfg  对应称号配置
-- data.pos       设置tip的位置 不传值默认在中间显示
function PCCommonTitleTips:Enter(data)
    if data then
        self.data = data
    end

    self:InitUI()
end

function PCCommonTitleTips:TitleAttributeItemRender(idx,item)
    local ctrl_isHaveJob = FGUI:getController(item,"isHaveJob")
    local ctrl_jobIcon = FGUI:getController(item,"jobIcon")
    local text_attr_name = FGUI:GetChild(item,"text_attr_name")
    local text_attr_value = FGUI:GetChild(item,"text_attr_value")
    local data = self.attrData[idx + 1]
    if data then
        ctrl_isHaveJob.selectedIndex = data.job == 0 and 0 or 1
        if data.job ~= 0 then
            ctrl_jobIcon.selectedIndex = data.job - 1
        end

        local attributeName = SL:GetValue("ATTR_CONFIG_NAME_BY_ID",data.attributeId)
        FGUI:GTextField_setText(text_attr_name,attributeName)
        FGUI:GTextField_setText(text_attr_value,data.attributeValue)
    end
end

function PCCommonTitleTips:InitUI()
    -- print("data=====================")
    -- SL:print_t(self.data)

    local itemEquipData = SL:GetValue("ITEM_DATA",self.data.itemID)
    FGUI:GTextField_setText(self.text_titleName,itemEquipData.Name or "")
    FGUI:GTextField_setText(self.text_getWayDetail,itemEquipData.GetWayInfo or "")
    self.ctrl_Attribute_mode.selectedIndex = itemEquipData.Anicount == 0 and 1 or 0
    local isHaveAttribute = not string.isNullOrEmpty(itemEquipData.Attribute)
    self.ctrl_isHaveAttribute.selectedIndex = isHaveAttribute and 0 or 1
    self.attrData = {}
    if isHaveAttribute then
        local attrs = string.split(itemEquipData.Attribute,"|")
        for k,v in pairs(attrs) do
            if not string.isNullOrEmpty(v) then
                local attrDetails = string.split(v,"#")
                local attrDetailData = {}
                attrDetailData.job = tonumber(attrDetails[1])
                attrDetailData.attributeId = tonumber(attrDetails[2])
                attrDetailData.attributeValue = tonumber(attrDetails[3])
                table.insert(self.attrData,attrDetailData)
            end
        end
    end

    local count = table.nums(self.attrData)
    FGUI:GList_setNumItems(self.list_attrbute,count)
    FGUI:setHeight(self.list_attrbute,count * CELL_HEIGHT)
end

return PCCommonTitleTips