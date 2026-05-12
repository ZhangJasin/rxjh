FuncDock = {}
FuncDock.openData = {}
function FuncDock.main()
    -- handle_MSG_SC_QUERYPLAYDEFINFO消息查询玩家信息成功
    SL:RegisterLUAEvent(LUA_EVENT_QUERY_PLAYER, "FuncDock", function(param, playerInfoJsonData)
        if param == -1 then
            ShowSystemTips(GET_STRING(30000501))
            return
        end

        if not playerInfoJsonData or not next(playerInfoJsonData) then
            ShowSystemTips(GET_STRING(30000501))
            return
        end

        FGUIFunction:LookRankPlayerInfo(FuncDock.openData)
    end)

    SL:RegisterLUAEvent(LUA_EVENT_RESPONSE_LOOK_PLAYER_INFO, "FuncDock", function(operateType)
        -- operateType 为 666 时是师徒发布界面在获取自身模型信息，不打开面板
        if operateType == 666 then
            return
        end

        if not SL:GetValue("IS_PC_OPER_MODE") then
            --查看 0:单装备面板 1:装备+属性面板
            local value = SL:GetValue("GAME_DATA", "lookPlayerMode")
            if not value then
                FGUI:Open("Bag", "LookPlayerPanel", 1)
            else
                if value == 1 then
                    FGUI:Open("Bag", "LookPlayerPanel", 1)
                else
                    FGUI:Open("Bag", "LookPlayerSingleEquipPanel")
                end
            end
        else
            FGUI:Open("Bag_pc", "PCLookPlayerPanel", 0)
        end
    end)
end

function FuncDock.setOpenData(data)
    FuncDock.openData = data
end
