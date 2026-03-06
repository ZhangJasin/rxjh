local tradeDialogID = "SendTrade"
Trade = {}

function Trade.main()
    -- 面对面交易
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_START, "Trade", function ()
        SL:CloseCommonDialog(tradeDialogID)
        FGUIFunction:OpenSimpleBagUI("Trade", "TradeMain")
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("Trade_pc", "PCTradeMain")
        else
            FGUI:Open("Trade", "TradeMain")
        end
        
    end)

    SL:RegisterLUAEvent(LUA_EVENT_TRADE_SEND_TRADE_INFO, "Trade", function (result, traderData)
        --[[        
            负数为错误码
            -1;   //交易条件不满足
            -2;   //距离太远不能交易
            -3;   //战斗状态不允许交易
            -4;   //离线不能交易
            -5;  //死亡不能交易
            -6;   //玩家在黑名单不能交易
        ]]

        if result == 0 then   
            -- 打开等待响应遮挡界面      
            local data = {}
            data.id = tradeDialogID
            data.str = GET_STRING(90180029)
            data.btnDesc = {GET_STRING(1000)}
            data.maskClose = false
            data.callback = function ()
                SL:CancelRequestTrade()
            end
            SL:OpenCommonDialog(data)
            return
        end

        if result ~= 1 then
            local tipsStr = nil
            if result == -1 then
                tipsStr = 90180005
            elseif result == -2 then
                tipsStr = 90180006
            elseif result == -3 then
                tipsStr = 90180007
            elseif result == -4 then
                tipsStr = 90180008
            elseif result == -5 then
                tipsStr = 90180009
            elseif result == -6 then
                tipsStr = 90180010
            end
            if tipsStr then
                ShowSystemTips(GET_STRING(tipsStr))
                return
            end
        end

        if not traderData or not next(traderData) then
            return
        end


        if result == 1 then
            local callBack = function (tag)
                if tag == 1 then
                    -- 同意
                    SL:RequestAgreeTradeInvite(traderData.UserID)
                elseif tag == 2 then
                    --拒绝
                    SL:RequestRefuseTradeInvite(traderData.UserID)
                end

            end
            local data = {}
            data.title = GET_STRING(1003)
            data.str = string.format(GET_STRING(90180023), traderData.Name)
            data.btnDesc = {GET_STRING(1093), GET_STRING(1092)}
            data.callback = callBack
            data.maskClose = false
            SL:OpenCommonDialog(data)
        end
    end)
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_SEND_TRADE_RESULT, "Trade", function (errorType, send_uid)
        local isAutoMove = false
        local errorStr = GET_STRING(60010001)
        if errorType == -1 then
            errorStr = GET_STRING(90180002)
        elseif errorType == -2 then
            errorStr = GET_STRING(90180011)
        elseif errorType == -3 then
            errorStr = GET_STRING(90180005)
        elseif errorType == -4 then
            errorStr = GET_STRING(90180010)
        elseif errorType == -5 then
            errorStr = GET_STRING(90180001)
        elseif errorType == -6 then
            errorStr = GET_STRING(90180003)
        elseif errorType == -7 then
            errorStr = GET_STRING(90180012)
        elseif errorType == -8 then
            isAutoMove = true
        elseif errorType == -9 then
            errorStr = GET_STRING(90180013)
        elseif errorType == -10 then
            errorStr = GET_STRING(90180014)
        elseif errorType == -11 then
            errorStr = GET_STRING(90180015)
        elseif errorType == -12 then
            errorStr = GET_STRING(90180016)
        elseif errorType == -13 then
            errorStr = GET_STRING(90180017)
        elseif errorType == -14 then
            errorStr = GET_STRING(40020003)
        elseif errorType == -15 then
            errorStr = GET_STRING(90180018)
        elseif errorType == -16 then
            errorStr = GET_STRING(90180030)
        end
        SL:CloseCommonDialog(tradeDialogID)
        if isAutoMove then
            local dialogData = {}
            dialogData.str =  GET_STRING(90180004)
            dialogData.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
            dialogData.callback = function (tag)
                if tag == 1 and send_uid then
                    SL:onLUAEvent(LUA_EVENT_TRADE_AUTO_MOVE_TO_TARGET, send_uid)
                end
            end
            SL:OpenCommonDialog(dialogData)
        else
            ShowSystemTips(errorStr)
        end
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Trade_pc", "PCTradeMain")
        else
            FGUI:Close("Trade", "TradeMain")
        end 
    end)

    SL:RegisterLUAEvent(LUA_EVENT_CANCEL_SEND_TRADE_SUCCESS, "Trade",function() 
        SL:CloseCommonDialog(tradeDialogID)
    end)

    SL:RegisterLUAEvent(LUA_EVENT_TRADE_END, "Trade",function() 
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Trade_pc", "PCTradeMain")
        else
            FGUI:Close("Trade", "TradeMain")
        end
    end)
end