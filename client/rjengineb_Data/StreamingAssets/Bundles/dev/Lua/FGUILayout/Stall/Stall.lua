Stall = {}

function Stall.main()
    -- 打开摆摊店铺
    SL:RegisterLUAEvent( LUA_EVENT_STALL_OPEN_SHOP, "Stall", function (data)
        FGUIFunction:OpenStallProductUI(data)  
    end)
    -- 进入/离开摆摊区域
    SL:RegisterLUAEvent(LUA_EVENT_MAP_STALL_ZONE_CHANGE, "Stall", function (isInStallArea)
        if isInStallArea then
            local from_type = SL:GetValue("AUTO_MOVE_FROM_TYPE")
            if from_type and from_type == SLDefine.AUTO_MOVE_TO_DEST_FROM.STALL then
                if SL:GetValue("IS_PC_OPER_MODE") then
                    FGUI:Open("Stall_pc", "PCStallCreatePanel")              
                else
                    FGUI:Open("Stall", "StallCreatePanel")
                end 
                SL:SetValue("BATTLE_AUTO_MOVE_END")
            end
        end
    end)
    SL:RegisterLUAEvent(LUA_EVENT_STALL_OPEN_SHOP_FAIL, "Stall", function ()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 90010010))
    end)
end