local sformat = string.format

local GET_COLOR_ID = 255
local COST_COLOR_ID = 249

Notice = {}

function Notice.main()
    if SL:GetValue("IS_PC_OPER_MODE") then
        Notice.RegisterPC()
    else
        Notice.RegisterMobile()
    end
end

function Notice.RegisterMobile()
    -- 背包/货币 获得&消耗提示
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ADD_ITEM_TIPS, "Notice", function(itemIndex, name, count, itemData)
        local itemConfig = SL:GetValue("ITEM_DATA", itemIndex)
        if not itemConfig then return end
        local nameColor = SL:GetColorByStyleId(itemConfig.Color or 255)
        local str = sformat(GET_STRING(60001003), nameColor, name, count)
        local icon = SL:GetValue("ITEM_ICON_PATH_BY_ITEM_ID", itemIndex)
        local grade = itemConfig.Grade or 0
        local isLock = SL:GetMetaValue("ITEM_IS_BIND", itemData)
        SL:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, str, icon, grade, isLock, true)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_BAG_DEL_ITEM_TIPS, "Notice", function(itemIndex, name, count, itemData)
        local itemConfig = SL:GetValue("ITEM_DATA", itemIndex)
        if not itemConfig then return end
        local nameColor = SL:GetColorByStyleId(itemConfig.Color or 255)
        local str = sformat(GET_STRING(60001004), nameColor, name, count)
        local icon = SL:GetValue("ITEM_ICON_PATH_BY_ITEM_ID", itemIndex)
        local grade = itemConfig.Grade or 0
        local isLock = SL:GetMetaValue("ITEM_IS_BIND", itemData)
        SL:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, str, icon, grade, isLock, false)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_ADD_TIPS, "Notice", function(itemIndex, name, count)
        local itemConfig = SL:GetValue("ITEM_DATA", itemIndex)
        if not itemConfig then return end
        local nameColor = SL:GetColorByStyleId(itemConfig.Color or 255)
        local str = sformat(GET_STRING(60001003), nameColor, name, count)
        local icon = SL:GetValue("ITEM_ICON_PATH_BY_ITEM_ID", itemIndex)
        local grade = itemConfig.Grade or 0
        local isLock = SL:GetMetaValue("ITEM_IS_BIND", itemConfig)
        SL:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, str, icon, grade, isLock, true)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_DEL_TIPS, "Notice", function(itemIndex, name, count)
        local itemConfig = SL:GetValue("ITEM_DATA", itemIndex)
        if not itemConfig then return end
        local nameColor = SL:GetColorByStyleId(itemConfig.Color or 255)
        local str = sformat(GET_STRING(60001004), nameColor, name, count)
        local icon = SL:GetValue("ITEM_ICON_PATH_BY_ITEM_ID", itemIndex)
        local grade = itemConfig.Grade or 0
        local isLock = SL:GetMetaValue("ITEM_IS_BIND", itemConfig)
        SL:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, str, icon, grade, isLock, false)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_EXP_CHANGE_VALUE, "Notice", function(value)
        local str = sformat(GET_STRING(value > 0 and 60001005 or 60001006), value)
        local isGet = value > 0
        local icon = "ui://ItemIcon/002155"
        SL:onLUAEvent(LUA_EVENT_NOTICE_ITEM_TIPS, str, icon, 0, false, isGet)
    end)
end

function Notice.RegisterPC()
    -- 背包/货币 获得&消耗提示
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ADD_ITEM_TIPS, "Notice", function(itemIndex, name, count)
        local nameColor = SL:GetValue("ITEM_NAME_COLOR", itemIndex)
        local str = sformat(GET_STRING(60001003), nameColor, name, count)
        SL:ShowSystemChat(str, GET_COLOR_ID)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_BAG_DEL_ITEM_TIPS, "Notice", function(itemIndex, name, count)
        local nameColor = SL:GetValue("ITEM_NAME_COLOR", itemIndex)
        local str = sformat(GET_STRING(60001004), nameColor, name, count)
        SL:ShowSystemChat(str, COST_COLOR_ID)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_ADD_TIPS, "Notice", function(itemIndex, name, count)
        local str = sformat(GET_STRING(60001001), name, count)
        SL:ShowSystemChat(str, GET_COLOR_ID)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_MONEY_DEL_TIPS, "Notice", function(itemIndex, name, count)
        local str = sformat(GET_STRING(60001002), name, count)
        SL:ShowSystemChat(str, GET_COLOR_ID)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_EXP_CHANGE_VALUE, "Notice", function(value)
        local str
        if value > 0 then
            str = sformat(GET_STRING(60001005), value)
        else
            str = sformat(GET_STRING(60001006), -value)
        end
        SL:ShowSystemChat(str, GET_COLOR_ID)
    end)
end