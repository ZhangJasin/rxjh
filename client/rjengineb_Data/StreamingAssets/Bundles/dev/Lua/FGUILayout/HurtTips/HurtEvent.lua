HurtEvent = {}
HurtEvent._isShow = false

local function CheckHpShow()
	if not SL:GetValue("SETTING_LOW_HP_WARNING_EN") then 
		return 
	end 
	local curHP = SL:GetValue("HP") or 0
	local maxHP = SL:GetValue("MAXHP") or 1
	local percent = curHP / maxHP
	if percent < 0.3 and percent > 0 then
		HurtEvent.Show()
	end
end

function HurtEvent.main()
	HurtEvent._isShow = false
	
	--玩家属性初始化
	SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "HurtEvent", function(actorID, damageID, damageNum)
		CheckHpShow()
	end)

	-- 血量变化
	SL:RegisterLUAEvent(LUA_EVENT_HP_CHANGE, "HurtEvent", function(...)
		local curHP = SL:GetValue("HP") or 0
		local maxHP = SL:GetValue("MAXHP") or 1
		local percent = curHP / maxHP
		if percent >= 0.3 then
			HurtEvent.Hide()
		else
			if not SL:GetValue("SETTING_LOW_HP_WARNING_EN") then 
				return 
			end 
			HurtEvent.Show()
		end
	end)

	--设置变化
	SL:RegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE, "HurtEvent", function(id, value)
		if SLDefine.SETTINGID.SETTING_IDX_LOW_HP_WARNING_EN == id then 
			local setOn = SL:GetValue("SETTING_LOW_HP_WARNING_EN")
			if setOn then 
				local curHP = SL:GetValue("HP") or 0
				local maxHP = SL:GetValue("MAXHP") or 1
				local percent = curHP / maxHP
				if percent < 0.3 and percent > 0 then
					HurtEvent.Show()
				end
			else
				HurtEvent.Hide()
			end
		end
	end)
end

function HurtEvent.Show()
	if HurtEvent._isShow then
        return
    end
	HurtEvent._isShow = true
	FGUI:Open("HurtTips", "HurtTips")
end

function HurtEvent.Hide()
	if not HurtEvent._isShow then
        return
    end
    HurtEvent._isShow = false
    FGUI:Close("HurtTips", "HurtTips")
end