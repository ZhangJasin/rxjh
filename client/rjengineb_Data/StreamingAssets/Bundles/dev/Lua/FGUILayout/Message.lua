local ssrMessage = {}

local dispatch_handler = {}
-- 示例：假设 ssrMessage.lua 在 network 目录下
local function _dispatchex(msgID, arg1, arg2, arg3, msgData)
    --print("110")
    -- print("收到消息：msgID="..msgID, "arg1="..tostring(arg1), "arg2="..tostring(arg2), "arg3="..tostring(arg3), "msgData="..tostring(msgData))
    local module, method
    if msgID == ssrNetMsgCfg.USER_MESSAGE_ID then
        module, method = msgData.moduleName,msgData.methodName
        assert(module or method,"error message module or method")
        local targetTab = dispatch_handler[module]
        -- SL:dump(targetTab,"消息组"..method.."的注册对象")
        if targetTab then
            for k,target in ipairs(targetTab) do
                if target[method] then
                    -- print("调用自定义消息：module="..module.." method="..method)
                    target[method](target,msgData.msgData or {})
                end
            end
        end
        --SL:onLUAEvent(ssrEventCfg.NetMsgEvent, {module=msgData.moduleName,method=msgData.methodName,eventData=msgData.msgData or {}})
    else
        local msgName = ssrNetMsgCfgEx[msgID]
        if not msgName then
            ssrPrint("error： msgID:"..msgID.." not register!")
            return 
        end
        module, method = msgName[1], msgName[2]
        assert(module or method,"error message module or method")
        local targetTab = dispatch_handler[module]
        if targetTab then
            for k,target in ipairs(targetTab) do
                if target[method] then
                    -- print("调用消息：module="..module.." method="..method)
                    target[method](target, arg1, arg2, arg3, msgData)
                end
            end
        end
        local eventData = {}
        eventData.arg1 = arg1
        eventData.arg2 = arg2
        eventData.arg3 = arg3
        eventData.msgData = msgData
        --SL:onLUAEvent(ssrEventCfg.NetMsgEvent, {module=module,method=method,eventData=eventData})
    end
end

local function _dispatch(msgID, arg1, arg2, arg3, jsonstr)
    local msgData = jsonstr ~= "" and SL:JsonDecode(jsonstr) or nil
    if ssrNetMsgCfg.sync == msgID then                  --一次性同步登录数据
        for _,v in ipairs(msgData or {}) do
            --print("333")
            local id,arg1,arg2,arg3,data = v[1], v[2] or 0, v[3] or 0, v[4] or 0, v[5] or {}
            local jsonstr = SL:JsonEncode(data)
            local result, errinfo = pcall(_dispatchex, id, arg1, arg2, arg3, data)
            if not result then
                local msgName = ssrNetMsgCfg[id]
                print("LUA ERROR: msgID="..id .."|msgName="..msgName, errinfo, debug.traceback())
            end
        end
    else
        -- print("msgID="..msgID, "arg1="..tostring(arg1), "arg2="..tostring(arg2), "arg3="..tostring(arg3), "jsonstr="..tostring(jsonstr))
        _dispatchex(msgID, arg1, arg2, arg3, msgData)
    end
end

function ssrMessage:sendmsg(msgID, arg1, arg2, arg3, msgData)
    assert(msgID, "ssr sendmsg msgID is nil!")
    if msgData then msgData = SL:JsonEncode(msgData) end
    SL:SendNetMsg(msgID, arg1, arg2, arg3, msgData)
end

--自定义消息体格式
function ssrMessage:sendmsgEx(moduleName,methodName,msgData)
    local reqData = {}
    reqData.msgData = msgData
    reqData.moduleName = moduleName
    reqData.methodName = methodName
    ssrMessage:sendmsg(ssrNetMsgCfg.USER_MESSAGE_ID,0,0,0,reqData)
end

function ssrMessage:haveRegisterMsg(msgType, target)
    if dispatch_handler[msgType] then
        for _,v in ipairs(dispatch_handler[msgType]) do
            if target == v then
                ssrPrint("网络消息类【"..msgType.."】".."重复注册")
                return true
            end
        end
    end
    return false
end

function ssrMessage:RegisterNetMsg(msgType, target)
    -- print("target="..tostring(target))
    if self:haveRegisterMsg(msgType, target) then
        -- print("重复1")
        return
    else
        if not dispatch_handler[msgType] then
            dispatch_handler[msgType] = {}
        end
        table.insert(dispatch_handler[msgType],target)
    end
end

function ssrMessage:Register()
    dispatch_handler = {}
    for msgID,msgName in pairs(ssrNetMsgCfg) do
        if tonumber(msgID) ~= nil and (not string.find(msgName, "Request")) then
            SL:RegisterNetMsg(msgID, _dispatch)
        end
    end
    
    --自定义消息格式
    SL:RegisterNetMsg(ssrNetMsgCfg.USER_MESSAGE_ID, _dispatch)
    return ssrMessage
end

return ssrMessage
