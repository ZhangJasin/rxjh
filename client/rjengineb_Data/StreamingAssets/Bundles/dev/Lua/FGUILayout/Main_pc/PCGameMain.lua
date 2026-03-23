PCGameMain = {}
local PCGameMain = PCGameMain

PCGameMain.team = nil

PCGameMain.MAX_QUICK_MAX_PAGE = 3	--快捷栏最大页数
local quickSaveKeys = {}
local quickUseFunc = nil
local quickPage	= 1					--快捷栏当前页
local quickDatas = {}				--快捷栏数据



function PCGameMain.main()
	PCGameMain.InitQuickDatas()

	--初始化主界面
	FGUI:Open("Main_pc", "PCMainPlayer", nil, FGUI_LAYER.BG, {fairyBatching = false})
	FGUI:Open("Main_pc", "PCMainMission", nil, FGUI_LAYER.BG)
	FGUI:Open("Main_pc", "PCMainMiniMap", nil, FGUI_LAYER.BG, {fairyBatching = false})
	FGUI:Open("Main_pc", "PCMainBottom", nil, FGUI_LAYER.BG)
	FGUI:Open("Main_pc", "PCMainChat", nil, FGUI_LAYER.BG)
	FGUI:Open("Main_pc", "PCMainTeam", nil, FGUI_LAYER.BG)
	FGUI:Open("SUI", "MainSUI", nil, FGUI_LAYER.BG)

	-- 快捷使用
	FGUI:Open("QuickUseTips", "QuickUseTips", nil, nil)

	FGUI:Open("Main_pc", "PCMainNode", nil, FGUI_LAYER.NOTICE)
	

	if SL._DEBUG then 
		local function ShowMainRight()
			local isOpen = FGUI:CheckOpen("Main", "MainRight")
			if not isOpen then 
				FGUI:Open("Main", "MainRight", nil, FGUI_LAYER.BG, {fairyBatching = false})
			else 
				FGUI:Close("Main", "MainRight")
			end 
		end
    end
end




function PCGameMain.OnTargetChange(data)
	local targetID = data and data.targetID or nil
	local inView = SL:GetValue("ACTOR_IN_VIEW", targetID)
	if not inView then targetID = nil end
	local isBig
	if targetID then
		if SL:GetValue("ACTOR_IS_PLAYER", targetID) then
			isBig = false
		elseif SL:GetValue("ACTOR_IS_MONSTER", targetID) and not SL:GetValue("ACTOR_IS_DUMMY_EFFECT", targetID) then
			local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", targetID)
	    	local cfg = SL:GetValue("MONSTER_CONFIG", typeIndex)
	    	local hpCount = (cfg and cfg.HpCount) and cfg.HpCount or 0
			isBig = hpCount > 0
		else
			targetID = nil
		end
	end
	if targetID then
		if isBig then
			FGUI:Close("Main", "MainTarget")
	        FGUI:Open("Main", "MainBigTarget", nil, FGUI_LAYER.BG)
		else
			FGUI:Close("Main", "MainBigTarget")
			FGUI:Open("Main", "MainTarget", nil, FGUI_LAYER.BG, {destroyTime = -1})
		end
	else
		FGUI:Close("Main", "MainBigTarget")
		FGUI:Close("Main", "MainTarget")
	end
end


function PCGameMain.RegisterQuickUseFunc(func)
    quickUseFunc = func
end

function PCGameMain.UnRegisterQuickUseFunc()
    quickUseFunc = nil
end

function PCGameMain.DoQuickUse(index)
	if not quickUseFunc then return end
    quickUseFunc(index)
end

local quickSaveTimer
function PCGameMain.InitQuickDatas()
	quickSaveTimer = nil
	quickPage = 1
	table.clear(quickDatas)
	table.clear(quickSaveKeys)
	local max = PCGameMain.MAX_QUICK_MAX_PAGE
	local uid = SL:GetValue("USER_ID")
	for i = 1, max do
		quickSaveKeys[i] = "PCMainQuick" .. i .. "_" .. uid
	end
	for i = 1, max do
        local saveKey = quickSaveKeys[i]
        local saveStr = SL:GetLocalString(saveKey) or ""
        local data = {}
	    if saveStr and saveStr ~= "" then
	    	data = SL:JsonDecode(saveStr)
	    end
        quickDatas[i] = data
    end
end


function PCGameMain.SaveQuickData(page)
	if quickSaveTimer then return end
	quickSaveTimer = SL:ScheduleOnce(function()
		quickSaveTimer = nil
		local saveKey = quickSaveKeys[page]
		if not saveKey then return end
		local data = quickDatas[page]
		if not data then return end
		local str = SL:JsonEncode(data)
		SL:SetLocalString(saveKey, str)
	end, 0.01)
end

function PCGameMain.GetQuickDatas(page)
	return quickDatas[page] or {}
end

-- @return
-- {type = FGUIDefine.PCQuickType.Item, itemIndex = (number), makeIndex = (number)}
-- {type = FGUIDefine.PCQuickType.Skill, id = (number), auto = (bool)}
function PCGameMain.GetQuickData(page, index)
	local pageData = quickDatas[page]
	if not pageData then return end
	return pageData[index]
end

function PCGameMain.SetQuickData(page, index, data)
	local pageData = quickDatas[page]
	if not pageData then return end
	if data then
		--去重
		if data.type == FGUIDefine.PCQuickType.Item then
			for idx, v in pairs(pageData) do
                if idx ~= index and v.makeIndex == data.makeIndex then
                    pageData[idx] = nil
					SL:onLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, page, idx, nil)
                end
            end
		elseif data.type == FGUIDefine.PCQuickType.Skill then
			for idx, v in pairs(pageData) do
                if idx ~= index and v.id == data.id then
                    pageData[idx] = nil
					SL:onLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, page, idx, nil)
                end
            end
		end
	end
	pageData[index] = data
	SL:onLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, page, index, data)
	PCGameMain.SaveQuickData(page)
end

function PCGameMain.GetQuickPage()
	return quickPage
end

function PCGameMain.SetQuickPage(page)
	if page < 1 or page > PCGameMain.MAX_QUICK_MAX_PAGE then return end
	if quickPage == page then return end
	quickPage = page
	SL:onLUAEvent(LUA_EVENT_PC_QUICK_PAGE_CHANGE, page)
end
