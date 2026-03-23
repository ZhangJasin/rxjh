local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainMission = class("MainMission", BaseFGUILayout)


function MainMission:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self._missionDatas = {}

    self._missionMovies = {}

    FGUI:GList_setVirtual(self._ui.List_mission)
    FGUI:GList_itemRenderer(self._ui.List_mission, handler(self, self.OnItemRendererMission))
    FGUI:GList_addOnClickItemEvent(self._ui.List_mission, handler(self, self.OnListMissionItemClick))
end

function MainMission:Enter()
	self:RegisterEvent()

    self:InitMissions()

    FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.MissionGuideFunc, handler(self, self.GetGuideItem))
    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootMission, self._ui.Node_attach)
end

function MainMission:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootMission)
    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.MissionGuideFunc)
	self:RemoveEvent()
end

function MainMission:Destroy()
    self._ui = nil	
end


----------------------------------------------------------------------------

local function SortMissionData(a, b)
    if a.isTop and not b.isTop then return true end
    if b.isTop and not a.isTop then return false end
    return b.order < a.order
end

function MainMission:InitMissions()
    table.clear(self._missionDatas)
    local datas = SL:GetValue("MISSION_ALL_DATA")
    for k, data in pairs(datas) do
        table.insert(self._missionDatas, data)
    end
    table.sort(self._missionDatas, SortMissionData)
    FGUI:GList_setNumItems(self._ui.List_mission, #self._missionDatas)
end

function MainMission:onMissionItemTop(id)
    table.sort(self._missionDatas, SortMissionData)
    FGUI:GList_refreshVirtualList(self._ui.List_mission)
end

function MainMission:OnItemRendererMission(index, item)
    local data = self._missionDatas[index + 1]
    if not data then return end

    -- title
    local richTitle = FGUI:GetChild(item, "RichText_title")
    FGUI:GRichTextField_setText(richTitle, data.head.content)
    FGUI:GRichTextField_setColor(richTitle, SL:GetValue("COLOR_BY_ID", data.head.color))

    -- content
    local richContent = FGUI:GetChild(item, "RichText_content")
    FGUI:GRichTextField_setText(richContent, data.body.content)
    FGUI:GRichTextField_setColor(richContent, SL:GetValue("COLOR_BY_ID", data.body.color))

    -- Effect
    local itemId = FGUI:GetID(item)
    local movieData = self._missionMovies[itemId]
    local isSameMovie = false
    if movieData then
        if movieData.id == data.animID then
            isSameMovie = true
        elseif movieData.movie then
            FGUI:RemoveFromParent(movieData.movie, true)
            table.clear(movieData)
        end
    end
    if data.animID and not isSameMovie then
        local movie = FGUI:GMovieClip_create(item, data.animID)
        FGUI:setPosition(movie, data.offsetX or 0, data.offsetY or 0)
        if not movieData then
            movieData = {}
            self._missionMovies[itemId] = movieData
        end
        movieData.id = data.animID
        movieData.movie = movie
    end
end

function MainMission:OnListMissionItemClick(context)
    local item = context.data
	local index = FGUI:GetChildIndex(self._ui.List_mission, item)
    if not index or index < 0 then return end
    local idx = FGUI:GList_childIndexToItemIndex(self._ui.List_mission, index)
    if not idx or idx < 0 then return end
    local data = self._missionDatas[idx + 1]
    if not data then return end
    SL:RequestSubmitMission(data.type)
end

function MainMission:onMissionItemAdd(data)
    table.insert(self._missionDatas, data)
    table.sort(self._missionDatas, SortMissionData)
    FGUI:GList_setNumItems(self._ui.List_mission, #self._missionDatas)
end

function MainMission:onMissionItemChange(data)
    local id = data.type
    for k, v in pairs(self._missionDatas) do
        if v and v.type == id then
            self._missionDatas[k] = data
            break
        end
    end
    table.sort(self._missionDatas, SortMissionData)
    FGUI:GList_refreshVirtualList(self._ui.List_mission)
end

function MainMission:onMissionItemRemove(data)
    local rmvSucc = false
    for k, v in pairs(self._missionDatas) do
        if v.type == data.type then
            rmvSucc = true
            table.remove(self._missionDatas, k)
            break
        end
    end
    if rmvSucc then
        FGUI:GList_setNumItems(self._ui.List_mission, #self._missionDatas)
    end
end

function MainMission:onMissionShow(data)
    self:ShowMission()
end

function MainMission:UpdateMissionCellData(cell, data)
    -- title
    local richTitle = FGUI:GetChild(cell, "RichText_title")
    FGUI:GRichTextField_setText(richTitle, data.head.content)
    FGUI:GRichTextField_setColor(richTitle, SL:GetValue("COLOR_BY_ID", data.head.color))

    -- content
    local richContent = FGUI:GetChild(cell, "RichText_content")
    FGUI:GRichTextField_setText(richContent, data.body.content)
    FGUI:GRichTextField_setColor(richContent, SL:GetValue("COLOR_BY_ID", data.body.color))
    

    self:UpdateMissionCellOrder(cell, data)
end

-- 获取引导对应的item
function MainMission:GetGuideItem(id)
    local index
    for k, v in pairs(self._missionDatas) do
        if tostring(v.type) == tostring(id) then
            index = k
            break
        end
    end
    if not index then return nil end
    index = index - 1
    FGUI:GList_scrollToView(self._ui.List_mission, index, false, false)
    local cellIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_mission, index)
    local child = FGUI:GetChildAt(self._ui.List_mission, cellIdx)
    return child
end



-----------------------------------注册事件--------------------------------------
function MainMission:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_TOP, "MainMission", handler(self, self.onMissionItemTop))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_ADD, "MainMission", handler(self, self.onMissionItemAdd))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_CHANGE, "MainMission", handler(self, self.onMissionItemChange))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_REMOVE, "MainMission", handler(self, self.onMissionItemRemove))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, "MainMission", handler(self, self.onMissionShow))
end

function MainMission:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_TOP, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_ADD, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_CHANGE, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_REMOVE, "MainMission")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_MISSION_SHOW, "MainMission")
end


return MainMission