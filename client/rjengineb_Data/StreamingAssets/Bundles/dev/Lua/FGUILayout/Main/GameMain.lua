GameMain = {}

function GameMain.main()
	--初始化主界面
	FGUI:Open("Main", "MainJoystick", nil, FGUI_LAYER.BG)
	FGUI:Open("Main", "MainBottom", nil, FGUI_LAYER.BG)
	FGUI:Open("Main", "MainRight", nil, FGUI_LAYER.BG, {fairyBatching = false})
	FGUI:Open("Main", "MainAssist", nil, FGUI_LAYER.BG)
	FGUI:Open("Main", "MainPlayer", nil, FGUI_LAYER.BG, {fairyBatching = false})
	FGUI:Open("Main", "MainMiniMap", nil, FGUI_LAYER.BG, {fairyBatching = false})
	
	FGUI:Open("SUI", "MainSUI", nil, FGUI_LAYER.BG)

	-- 快捷使用
	FGUI:Open("QuickUseTips", "QuickUseTips", nil, nil)
	
	SL:RegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "GameMain", GameMain.OnTargetChange)
end

function GameMain.OnTargetChange(data)
	local targetID = data.targetID
	local selectType = data.selectType
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
		if selectType == SLDefine.SELECT_TARGET.ACTOR_DIE then
			--针对怪物死亡后继续显示掉血动画,不直接Close
			SL:onLUAEvent(LUA_EVENT_SELECT_TARGET_DIE)
		else
			FGUI:Close("Main", "MainTarget")
			FGUI:Close("Main", "MainBigTarget")
		end
	end
end
