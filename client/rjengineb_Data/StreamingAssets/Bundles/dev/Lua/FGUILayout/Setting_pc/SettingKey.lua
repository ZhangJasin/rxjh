SettingKey = {}
local SettingKey = SettingKey
SettingKey.Type = {
    BAG         = 1,
    CHAT        = 2,
    EQUIP       = 3,
    FRIEND      = 4,
    GUILD       = 5,
    MAP         = 6,
    MAIL        = 7,
    RANK        = 8,
    TEAM        = 9,
    SETTING     = 10,
    QUICK1      = 11,
    QUICK2      = 12,
    QUICK3      = 13,
    QUICK4      = 14,
    QUICK5      = 15,
    QUICK6      = 16,
    QUICK7      = 17,
    QUICK8      = 18,
    QUICK9      = 19,
    QUICK10     = 20,
    SPLIT_ITEM  = 21,
    MOVE_UP     = 22,
    MOVE_DOWN   = 23,
    MOVE_LEFT   = 24,
    MOVE_RIGHT  = 25,
    CLOSE_UI    = 26,
    AUCTION     = 27,
}

local ConfigDefaultKey = requireGameConfig("DefaultKey")
local SettingKeyName = require("FGUILayout/Setting_pc/SettingKeyName")
local SettingKeyFunc = require("FGUILayout/Setting_pc/SettingKeyFunc")
local SaveKey = "SettingKey" .. SL:GetValue("USER_ID")

local DefaultMap = {}   --表默认设置
local CustomMap = {}    --自定义键设置("id":keysStr)
local ShowSettings = {} --可见设置
local KeySettingMap     --最终键设置{id,name,order,enable,keys,keysStr}
local KeyMap = {}
local IsInit = true

--特殊转换处理
local transKeyMap = {
    ["KEY_RIGHT_SHIFT"] = "KEY_SHIFT",
    ["KEY_RIGHT_CTRL"] = "KEY_CTRL",
    ["KEY_RIGHT_ALT"] = "KEY_ALT",
}
--兼容的按键注册
local attachKeyMap = {
    ["KEY_SHIFT"] = "KEY_RIGHT_SHIFT",
    ["KEY_CTRL"] = "KEY_RIGHT_CTRL",
    ["KEY_ALT"] = "KEY_RIGHT_ALT",
}



-- enable = 0:不启用;
--          1:启用,玩家可修改;
--          2:启用,玩家不可修改,玩家可见;
--          3:启用,玩家不可修改,玩家不可见


function SettingKey.main()
    if not SL:GetValue("IS_PC_OPER_MODE") then return end
    table.clear(CustomMap)
    table.clear(ShowSettings)
    table.clear(KeyMap)
    IsInit = true
    SettingKey.InitDefaultData()
    SettingKey.InitSettingData()
    SettingKey.InitKeyboardEvent()
    IsInit = false
end

function SettingKey.InitDefaultData()
    for k, v in pairs(ConfigDefaultKey) do
        local enable = v.Enable
        if enable and enable ~= 0 then
            local keys = SettingKey.GetKeys(v.KeyName)
            local id = v.ID
            local settingData = {
                id      = id,
                name    = v.Name,
                keys    = keys,
                keysStr = v.KeyName,
                enable  = enable,
                order   = v.Order or 9999,
            }
            DefaultMap[id] = settingData
        end
    end
end

function SettingKey.InitSettingData()
    KeySettingMap = SL:CopyData(DefaultMap)
    local len = 0
    for k, v in pairs(KeySettingMap) do
        local keysStr = v.keysStr
        if keysStr ~= "" then
            if KeyMap[keysStr] then
                SL:Print("[SettingKey Error]DefaultKey重复的快捷键设置 id:" .. v.id)
                v.keys = nil
                v.keysStr = ""
            else
                KeyMap[keysStr] = v
            end
        end
        if v.enable == 1 or v.enable == 2 then
            len = len + 1
            ShowSettings[len] = v
        end
    end
    table.sort(ShowSettings, function(a, b) return a.order < b.order end)
    --自定义数据读取
    local customKeyDatas = SettingKey.ReadLocalData()
    if customKeyDatas then
        for idStr, keysStr in pairs(customKeyDatas) do
            local id = tonumber(idStr)
            if id then
                local keys = SettingKey.GetKeys(keysStr)
                SettingKey.SetCustomKey(id, keys, false)
            end
        end
    end
end

function SettingKey.InitKeyboardEvent()
    for k, setting in pairs(KeySettingMap) do
        if setting and setting.keys and #setting.keys > 0 then
            SettingKey.AddKeyboardEvent(setting.id, setting.keys)
        end
    end
end


--修改快捷键
function SettingKey.SetCustomKey(id, keys, tip)
    local setting = KeySettingMap[id]
    if not setting then return false end
    if setting.enable == 2 or setting.enable == 3 then return false end
    if keys then
        for i = 1, #keys do
            local key = keys[i]
            keys[i] = transKeyMap[key] or key
        end
    end
    local keysStr = SettingKey.GetKeysStr(keys)
    if keysStr == setting.keysStr then return end
    local curKeyData = KeyMap[keysStr]
    if curKeyData and curKeyData.id ~= setting.id then
        if curKeyData.enable == 1 then
            SettingKey.SetCustomKey(curKeyData.id, nil, false)
        else
            if not IsInit and tip then
                SL:ShowSystemTips(GET_STRING(40060001))
            end
            return false
        end
    end
    local oldKeyStr = setting.keysStr
    if oldKeyStr ~= "" then
        KeyMap[keysStr] = nil
        if not IsInit then
            SettingKey.RemoveKeyboardEvent(id, setting.keys)
        end
    end
    setting.keys = keys
    setting.keysStr = keysStr
    if keysStr ~= "" then
        KeyMap[keysStr] = setting
    end
    local defaultData = DefaultMap[id]
    if defaultData and defaultData.keysStr == keysStr then
        CustomMap[tostring(id)] = nil
    else
        CustomMap[tostring(id)] = keysStr or ""
    end
    if not IsInit then
        if keys and #keys > 0 then
            local pressFunc = SettingKeyFunc.PressFunc[id]
            local releaseFunc = SettingKeyFunc.ReleaseFunc[id]
            if pressFunc or releaseFunc then
                SettingKey.AddKeyboardEvent(id, setting.keys)
            end
            if tip then
                SL:ShowSystemTips(GET_STRING(40060002))
            end
        end
        SL:onLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, id)
        SettingKey.SaveLocalData()
    end
    return true
end

local allKeys = {}
-- 获取所有兼容注册的按键
function SettingKey.GetAllAttachKeys(keys)
    table.clear(allKeys)
    if not keys then return allKeys end
    table.insert(allKeys, keys)
    for i = 1, #keys do
        local key = keys[i]
        local attackKey = attachKeyMap[key]
        if attackKey then
            for j = 1, #allKeys do
                local newKeys = SL:CopyData(allKeys[j])
                newKeys[i] = attackKey
                table.insert(allKeys, newKeys)
            end
        end
    end
    return allKeys
end

function SettingKey.AddKeyboardEvent(id, keys)
    if not keys or #keys <= 0 then return end
    local pressFunc = SettingKeyFunc.PressFunc[id]
    local releaseFunc = SettingKeyFunc.ReleaseFunc[id]
    if not pressFunc and not releaseFunc then return end
    local tag = "SettingKey" .. id
    keys = SL:CopyData(keys)
    keys.sequence = true
    local allKeys = SettingKey.GetAllAttachKeys(keys)
    for i = 1, #allKeys do
        local keys = allKeys[i]
        keys.sequence = true
        SL:AddKeyboardEvent(keys, tag, pressFunc, releaseFunc)
    end
end

function SettingKey.RemoveKeyboardEvent(id, keys)
    if not keys or #keys <= 0 then return end
    local pressFunc = SettingKeyFunc.PressFunc[id]
    local releaseFunc = SettingKeyFunc.ReleaseFunc[id]
    if not pressFunc and not releaseFunc then return end
    local tag = "SettingKey" .. id
    local allKeys = SettingKey.GetAllAttachKeys(keys)
    for i = 1, #allKeys do
        local keys = allKeys[i]
        SL:RemoveKeyboardEvent(keys, tag)
    end
end

function SettingKey.GetKeys(keysStr)
    local keyNames = string.split(keysStr, "+")
    local keys = {}
    for idx, simpleName in pairs(keyNames) do
        --键名转标准键名
        table.insert(keys, SettingKey.GetFullKeyName(simpleName) or simpleName)
    end
    return keys
end

local keyNameTemp = {}
function SettingKey.GetKeysStr(keys)
    if not keys or #keys <= 0 then return "" end
    table.clear(keyNameTemp)
    for k, v in ipairs(keys) do
        table.insert(keyNameTemp, SettingKey.GetSimpleKeyName(v) or v)
    end
    return table.concat(keyNameTemp, "+")
end

function SettingKey.GetFullKeyName(simpleName)
    return SettingKeyName.GetFullKeyName(simpleName)
end

function SettingKey.GetSimpleKeyName(fullName)
    return SettingKeyName.GetSimpleKeyName(fullName)
end

function SettingKey.ReadLocalData()
    local keyDataStr = SL:GetLocalString(SaveKey)
    if keyDataStr and keyDataStr ~= "" then
        return SL:JsonDecode(keyDataStr)
    end
    return nil
end

local timer
function SettingKey.SaveLocalData()
    if timer then return end
    timer = SL:ScheduleOnce(function()
        timer = nil
        local keyDataStr = SL:JsonEncode(CustomMap)
        SL:SetLocalString(SaveKey, keyDataStr)
    end, 0.1)
end


-- 获取可见的设置数组
function SettingKey.GetShowSettings()
    return ShowSettings
end

-- 获取按键设置数据
function SettingKey.GetSetting(id)
    return KeySettingMap[id]
end

function SettingKey.Reset()
    for k, v in pairs(DefaultMap) do
        if v.enable ~= 3 then
            SettingKey.SetCustomKey(v.id, v.keys, false)
        end
    end
end