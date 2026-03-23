TitleCheck = {}

function TitleCheck.main()
	-- u值更新
	SL:RegisterLUAEvent(LUA_EVENT_SERVER_U_VALUE_UPDATE, "TitleCheck", function()
        print("LUA_EVENT_SERVER_U_VALUE_UPDATE")
        SL:SetValue("TITLE_CHECK_AND_MERAGE",true)
    end)

    -- T值更新
    SL:RegisterLUAEvent(LUA_EVENT_SERVER_T_VALUE_UPDATE, "TitleCheck", function()
        print("LUA_EVENT_SERVER_T_VALUE_UPDATE")
        SL:SetValue("TITLE_CHECK_AND_MERAGE",true)
    end)

	-- 更新
    SL:RegisterLUAEvent(LUA_EVENT_SERVER_HUMAN_VALUE_INIT, "TitleCheck", function()
        print("LUA_EVENT_SERVER_HUMAN_VALUE_INIT")
        SL:SetValue("TITLE_CHECK_AND_MERAGE",true)
    end)
end

function TitleCheck.CheckTitleIDIsInCanShowTitleList(titleID,showTitleList)
    for key,v in pairs(showTitleList) do
        if v.cfg.ID == titleID then
            return key
        end
    end

    return nil
end

-- 只操作IsTitleDisplay=2的称号
-- needChecklist:需要检测的titleList(IsTitleDisplay=2的称号列表,元素结构如下)
-- [[
    -- data.cfg 对应成称号TitleIcon的配置
    -- data.isActive 
    -- data.isUsed
    -- data.endTime
    -- data.itemID
--]]
-- showTitleList:展示的称号列表(未排序)和元变量TITLE_UPDATE_PIN_DATA同源
-- pinDataList:置顶信息列表
function TitleCheck.CheckAndMergeConditionTitleList(needChecklist,showTitleList,pinDataList)
    for k,v in pairs(needChecklist) do
        local key = TitleCheck.CheckTitleIDIsInCanShowTitleList(v.cfg.ID,showTitleList)
        if not key then
             if SL:GetValue("CONDITION",tonumber(v.cfg.ConditionId)) then
                table.insert(showTitleList,v)
             end
        else
            if not SL:GetValue("CONDITION",tonumber(v.cfg.ConditionId)) then
                table.remove(showTitleList,key)
                if pinDataList and pinDataList[v.cfg.ID]  then
                    table.remove(pinDataList,v.cfg.ID)
                end
            end
        end
    end
end