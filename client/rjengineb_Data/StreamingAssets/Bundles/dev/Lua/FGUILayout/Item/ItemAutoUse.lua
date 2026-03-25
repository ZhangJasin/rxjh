-- 自动使用

ItemAutoUse = {}

function ItemAutoUse.main()
    -- 箭矢自动安装设置队列里的箭矢
    SL:RegisterLUAEvent(LUA_EVENT_ARROW_OVER, "ItemAutoUse", function(isNeedTip)
        -- 职业过滤
        if SL:GetValue("JOB") ~= global.MMO.ACTOR_PLAYER_JOB_1 then
            return
        end

        -- 装备位置检测
        if SL:GetValue("EQUIP_DATA_BY_POS", 11) then
            return
        end

        local isArrowEquipSuc = false
        if SL:GetValue("SETTING_AUTO_ASSEMBLE_ARROW_ENABLE") then
            -- 获取设置页面装配的箭矢优先级
            local arrowIDs = SL:GetValue("SETTING_AUTO_ASSEMBLE_ARROW_VALUE")
            if arrowIDs and next(arrowIDs) then
                for index = 1, table.count(arrowIDs), 1 do
                    local item = SL:GetValue("BAG_DATA_BY_INDEX", arrowIDs[index])
                    if item and SL:CheckItemUseNeed(item) then
                        SL:RequestUseItem(item)
                        isArrowEquipSuc = true
                        break
                    end
                end
            end
        end

        if not isArrowEquipSuc and isNeedTip then
            local data = {}
            data.str = GET_STRING(30000100)
            data.btnDesc = { GET_STRING(1001), GET_STRING(1000) }
            SL:OpenCommonDialog(data)
        end
    end)

    -- 玩家升级 quickuse 检测
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "ItemAutoUse", function(data)
        -- SL:dump(data, "背包物品增加")
        if data then
            FGUIFunction:CheckBagQuickUse(data)    
        end
    end)
 
end
