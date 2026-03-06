local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorSkillPracticePanel = class("VisitorSkillPracticePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "通用气功", page = 1},
	[2] = {name = "登封气功", page = 2},
}

function VisitorSkillPracticePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
end 

function VisitorSkillPracticePanel:Enter()
    self:SelectPage( 1)
end

function VisitorSkillPracticePanel:Exit()
    self._selQiGong = nil
end

function VisitorSkillPracticePanel:InitData()
    self._selPage = 1
    self._qigongList = {}
    self._selQiGong = nil
    self._showExtraLv = true
end

function VisitorSkillPracticePanel:InitEvent()
    -- 额外气功等级
    FGUI:setOnClickEvent(self._ui.check_level, handler(self, self.OnClickShowExtraLevel))

    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

    -- list
	FGUI:GList_itemRenderer(self._ui.list_qigong, handler(self, self.OnListItemRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_qigong, handler(self, self.OnClickSkillIcon))
end

function VisitorSkillPracticePanel:ItemRendererPage(idx, item)
    local index = idx + 1
    local data = PAGE_DATA[index]
    if not data then 
        return 
    end 

    local text_normal = FGUI:GetChild(item, "text_normal")
    local text_select = FGUI:GetChild(item, "text_select")
    FGUI:GTextField_setText(text_normal, data.name)
    FGUI:GTextField_setText(text_select, data.name)
end

function VisitorSkillPracticePanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function VisitorSkillPracticePanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	self._selPage = index

    local qigongData = SL:GetValue("VISITOR_SKILL_QIGONG_BY_TYPE", self._selPage)
    qigongData = HashToSortArray(qigongData, function(a, b)
        if not a.Sort or not b.Sort then 
            return a.ID < b.ID 
        end 

        if a.Sort == b.Sort then 
            return a.ID < b.ID 
        end 

        return a.Sort < b.Sort
    end)

    self._qigongList = qigongData
    self:UpdateSkillList()
    self:OnClickSkillIcon()
end

-- 左边 气功列表
function VisitorSkillPracticePanel:UpdateSkillList()
	FGUI:GList_setSelectedIndex(self._ui.list_qigong, -1)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
end

function VisitorSkillPracticePanel:OnListItemRenderer(idx, item)
    local index = idx + 1
    local data = self._qigongList[index] 
    if not data then 
        return 
    end
    --力劈华山 "id": 50001, "lv": 4,    连环飞舞  "id": 50003,"lv": 4,      梵音破镜  "id": 50011,   "lv": 4,
    local ui_icon = FGUI:GetChild(item, "skill_icon")
    local path = SL:GetValue("VISITOR_SKILL_QIGONG_SQUARE_ICON_BY_ID", data.ID)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)  

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, data.Name)

    local ui_lv = FGUI:GetChild(item, "text_needLv")
    local qigongData = SL:GetValue("VISITOR_SKILL_QIGONG_BY_ID", data.ID)

    local ui_mask = FGUI:GetChild(item, "skill_mask")
    if qigongData.LevelEx > 0 or qigongData.EquipLevel > 0 then 
        if self._showExtraLv then 
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012013), qigongData.CurLv, qigongData.LevelEx + qigongData.EquipLevel))
        else 
            local totalLv = qigongData.CurLv + qigongData.LevelEx + qigongData.EquipLevel
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012015), totalLv))
        end
        FGUI:setVisible(ui_mask, false)
    else
        if qigongData.CurLv == 0 then 
            -- 是否可以激活
            FGUI:GRichTextField_setText(ui_lv, GET_STRING(60012026))--未激活
        else 
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012015), qigongData.CurLv))--"<font color='#00FF00'>%s级",
            FGUI:setVisible(ui_mask, false)
        end 
    end 


end

function VisitorSkillPracticePanel:OnClickSkillIcon(context)
    local idx = 0
    if context then
        idx = FGUI:GetChildIndex(self._ui.list_qigong, context.data)
    end
    FGUI:GList_setSelectedIndex(self._ui.list_qigong, idx)
    local index = idx + 1
    local data = self._qigongList[index]
    if not data then
        return
    end

    self._selQiGong = SL:GetValue("VISITOR_SKILL_QIGONG_BY_ID", data.ID)
    self:UpdateSkillDetails()
end

function VisitorSkillPracticePanel:CleanSkillDetails()
    FGUI:GTextField_setText(self._ui.text_skillName, "")
    FGUI:GRichTextField_setText(self._ui.rich_details, "")
    FGUI:GRichTextField_setText(self._ui.rich_details2, "")
end

function VisitorSkillPracticePanel:UpdateSkillDetails()
    if not self._selQiGong then
        return
    end
    local qigongID  = self._selQiGong.ID
    local qigongMax = self._selQiGong.Lv
    local curLevel  = self._selQiGong.CurLv or 0       -- 气功等级
    local scriptLv  = self._selQiGong.LevelEx or 0     -- 脚本等级
    local equipLv   = self._selQiGong.EquipLevel or 0  -- 装备等级
    local realLevel = curLevel + scriptLv + equipLv
    local nextLevel = curLevel+1 > qigongMax and qigongMax or curLevel+1
    local realNextLevel = nextLevel + scriptLv + equipLv

    -- cur
    local curData = SL:GetValue("VISITOR_SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realLevel)
    if not curData then
        self:CleanSkillDetails(false)
        return
    end
    FGUI:GTextField_setText(self._ui.text_skillName, curData and curData.Name or "")

    -- desc 
    FGUI:GRichTextField_setText(self._ui.rich_desc, curData and curData.Desc or "")

    -- cur desc
    local tDescList = {}
    local tDesc1 = string.split(curData.DescShow, "|")
    if tDesc1 then
        for i = 1, #tDesc1 do 
            local cellDesc = string.split(tDesc1[i], "#")
            tDescList[i] = {}
            tDescList[i].name = cellDesc[1]
            tDescList[i].value1 = cellDesc[2]
        end
    end

    -- icon
    local ui_icon = FGUI:GetChild(self._ui.icon_select, "skill_icon")
    local path = SL:GetValue("VISITOR_SKILL_QIGONG_SQUARE_ICON_BY_ID", qigongID)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)

    local ui_mask = FGUI:GetChild(self._ui.icon_select, "skill_mask2")
    FGUI:setVisible(ui_mask, false)


    local ui_name = FGUI:GetChild(self._ui.icon_select, "text_name")
    FGUI:GTextField_setText(ui_name, curData.Name)

    -- next
    local nextData = SL:GetValue("VISITOR_SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realNextLevel)
    if realLevel+1 > qigongMax then
        FGUI:GRichTextField_setText(self._ui.text_max, GET_STRING(60012014))
        self:SetCostInfoVisible(false)
        return
    else
        -- next desc
        local tDesc2 = string.split(nextData.DescShow, "|")
        if tDesc2 then 
            for i = 1, #tDesc2 do 
                local cellDesc = string.split(tDesc2[i], "#")
                if tDescList[i] and next(tDescList) then
                    tDescList[i].value2 = cellDesc[2]
                end
            end 
        end 
        FGUI:GRichTextField_setText(self._ui.text_max, "")
        self:SetCostInfoVisible(true)
    end 

    -- showDesc 
	FGUI:GList_itemRenderer(self._ui.list_desc, function(idx, item)
        local index = idx + 1
        local data = tDescList[index]
        if not data then 
            return 
        end 

        local rich_name = FGUI:GetChild(item, "rich_name")
        local rich_cur = FGUI:GetChild(item, "rich_cur")
        local rich_next = FGUI:GetChild(item, "rich_next") 
        FGUI:GRichTextField_setText(rich_name, data.name..":")
        FGUI:GRichTextField_setText(rich_cur, data.value1)
        FGUI:GRichTextField_setText(rich_next, data.value2)
    end)
    FGUI:GList_setNumItems(self._ui.list_desc, #tDescList)
end

-- 显示额外气功等级
function VisitorSkillPracticePanel:OnClickShowExtraLevel(context)
    self._showExtraLv = FGUI:GButton_getSelected(context.sender)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
end

function VisitorSkillPracticePanel:SetCostInfoVisible(isShow)
    FGUI:setVisible(self._ui.list_desc, isShow)
end

return VisitorSkillPracticePanel