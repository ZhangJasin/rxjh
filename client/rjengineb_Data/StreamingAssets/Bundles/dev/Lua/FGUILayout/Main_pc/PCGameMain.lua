PCGameMain = {}

PCGameMain.team = nil

function PCGameMain.main()
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

	FGUI:Open("Main", "MainNode", nil, FGUI_LAYER.NOTICE)
	
	-- 物品拾取 飞入背包 UI
	-- FGUI:Open("PickItem", "PickItemUIParent", nil, FGUI_LAYER.BG)

	if SL._DEBUG then 
		local function ShowMainRight()
			local isOpen = FGUI:CheckOpen("Main", "MainRight")
			if not isOpen then 
				FGUI:Open("Main", "MainRight", nil, FGUI_LAYER.BG, {fairyBatching = false})
			else 
				FGUI:Close("Main", "MainRight")
			end 
		end
        -- SL:AddKeyboardEvent("KEY_F12", "PCGameMain", ShowMainRight) 
    end 

	-- SL:RegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "PCGameMain", PCGameMain.OnTargetChange)
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

PCGameMain.quickUseFunc = nil
function PCGameMain.RegisterQuickUseFunc(func)
    PCGameMain.quickUseFunc = func
end

function PCGameMain.UnRegisterQuickUseFunc()
    PCGameMain.quickUseFunc = nil
end

function PCGameMain.DoQuickUse(index)
	if not PCGameMain.quickUseFunc then return end
    PCGameMain.quickUseFunc(index)
end