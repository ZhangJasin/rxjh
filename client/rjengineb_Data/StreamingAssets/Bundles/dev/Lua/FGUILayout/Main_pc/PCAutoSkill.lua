PCAutoSkill = {}

local autoSkills = {}
local PCGameMain = PCGameMain
local MAX_KEY_COUNT = 10

function PCAutoSkill.main()
    SL:RegisterLUAEvent(LUA_EVENT_CLOUD_STORAGE_INIT, "PCAutoSkill", function()
		PCAutoSkill.InitData()
    end)

    SL:RegisterLUAEvent(LUA_EVENT_PC_QUICK_DATA_CHANGE, "PCAutoSkill", function(page, index, data)
		if index then 
			if data and data.auto then 
        		PCAutoSkill.SetAutoSkill(index, data.id)
			else   
				PCAutoSkill.ClearAutoSkill(index)
			end 
		end
    end)

    SL:RegisterLUAEvent(LUA_EVENT_PC_QUICK_PAGE_CHANGE, "PCAutoSkill", function(page)
		PCAutoSkill.ChangePage(page)
    end)

    SL:ScheduleOnce(function()
        local switch = SL:GetValue("SETTING_AUTO_SKILL_SHOW")
        SL:onLUAEvent(LUA_EVENT_PC_AUTO_SKILL_SWITCH, switch)
    end, 0.5)
end

function PCAutoSkill.InitData()
	local page = PCGameMain.GetQuickPage()
	PCAutoSkill.ChangePage(page)
end

function PCAutoSkill.ChangePage(page)
	SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT", page-1)
	autoSkills = SL:GetValue("SETTING_FIGHT_JOB_SKILL", page-1)
end

function PCAutoSkill.SetAutoSkill(key, skillID)
    if not key then 
        return 
    end 

    if not skillID then 
        return 
    end 

    local isWuGong = SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", skillID, 1)
    if isWuGong then 
        autoSkills[key] = skillID
        SL:SetValue("SETTING_FIGHT_JOB_SKILL", autoSkills, key)
    end
end

function PCAutoSkill.ClearAutoSkill(key)
    if not key then 
        return 
    end 

    if not key or not (key >= MAX_KEY_COUNT and key <= MAX_KEY_COUNT) then
        return
    end

    autoSkills[key] = -1
    SL:SetValue("SETTING_FIGHT_JOB_SKILL", autoSkills, key)
end