Message = {}

local dispatch_handler = {}

function Message.sendmsg(actor, msgID, arg1, arg2, arg3, data)
    local str = data and tbl2json(data) or nil
    sendmymsg(actor, msgID, arg1, arg2, arg3, str)
end

function Message.sendmsgEx(actor, moduleName,methodName,data)
    local rspData = {}
    rspData.moduleName = moduleName
    rspData.methodName = methodName
    rspData.msgData = data or {}
    local str = rspData and tbl2json(rspData) or nil
    sendmymsg(actor, ssrNetMsgCfg.USER_MESSAGE_ID, 0, 0, 0, str)
end


function Message.dispatch(actor, msgID, arg1, arg2, arg3, str)
    local module, method
    if msgID == ssrNetMsgCfg.USER_MESSAGE_ID then
        local data = (str and str ~= "") and json2tbl(str) or {}
        module, method = data.moduleName,data.methodName
        if module and method then
            local target = dispatch_handler[module]
            if target and target[method] then
                --print(tostring(target[method]))
                    target[method](actor,data.msgData or {})
            end
        end
    else
        local msgName = ssrNetMsgCfgEx[msgID]
        
        if not msgName then return end
        module, method = msgName[1], msgName[2]
        local target = dispatch_handler[module]
        if not target or not target[method] then return end
        --如果是条件开启模块，并且模块还未开启，不处理网络消息
        --派发
        local data = (str and str ~= "") and json2tbl(str) or nil
        target[method](actor, arg1, arg2, arg3, data)
    end
end

function Message.RegisterNetMsg(msgType, target)
    if dispatch_handler[msgType] then
        LOGPrint("网络消息类【"..msgType.."】已被注册")
        return
    end
    dispatch_handler[msgType] = target
end

--获取自定消息消息体
function Message.getMsgDataEx(moduleName,methodName,msgData)
    local retData = {}
    retData.moduleName = moduleName
    retData.methodName = methodName
    retData.msgData = msgData
    return retData
end

function Message.getUserMsgBody(moduleName,methodName,msgData)
    local bodyData = {ssrNetMsgCfg.USER_MESSAGE_ID,0,0,0,{}}
    bodyData[5] = Message.getMsgDataEx(moduleName,methodName,msgData)
    return bodyData
end
-- 
