local TipRoleDiePanlData = {}
local TipRoleDie = require("game_config/cfgcsv/TipRoleDie")

-- 缓存数据（增加安全初始化）
TipRoleDiePanlData.data = {
    time = (TipRoleDie and TipRoleDie[1] and TipRoleDie[1]['realive']) or 0,
    cfgData = TipRoleDie or {},
    subscribers = {}
}

-- 订阅数据更新
function TipRoleDiePanlData:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self.data.subscribers, callback)
    end
end

-- 取消订阅
function TipRoleDiePanlData:Unsubscribe(callback)
    if not self.data or not self.data.subscribers then return end
    
    for i, cb in ipairs(self.data.subscribers) do
        if cb == callback then
            table.remove(self.data.subscribers, i)
            break
        end
    end
end

-- 通知所有订阅者（增加安全检查）
function TipRoleDiePanlData:NotifySubscribers()
    if not self.data then
        -- print("Warning: TipRoleDiePanlData.data is nil")
        return
    end
    
    for _, callback in ipairs(self.data.subscribers) do
        if type(callback) == "function" then
            -- 使用pcall保护回调执行
            local success, err = pcall(callback, self.data)
            if not success then
                -- print("Callback error in TipRoleDiePanlData: " .. tostring(err))
            end
        end
    end
end

-- 获取配置数据
function TipRoleDiePanlData:GetConfigData()
    return (self.data and self.data.cfgData) or {}
end

-- 获取倒计时
function TipRoleDiePanlData:GetTime()
    return (self.data and self.data.time) or 0
end

-- 设置倒计时
function TipRoleDiePanlData:SetTime(time)
    if not self.data then return end
    self.data.time = time
    self:NotifySubscribers()
end

-- 减少倒计时
function TipRoleDiePanlData:DecreaseTime()
    if not self.data then return 0 end
    
    if self.data.time > 0 then
        self.data.time = self.data.time - 1
        self:NotifySubscribers()
    end
    return self.data.time
end

-- 重置倒计时
function TipRoleDiePanlData:ResetTime()
    if not self.data then return end
    
    self.data.time = (TipRoleDie and TipRoleDie[1] and TipRoleDie[1]['realive']) or 0
    self:NotifySubscribers()
end

-- 获取按钮文字（包含参数格式化）
function TipRoleDiePanlData:GetBtnFont(index)
    if not self.data.cfgData[index] then return "" end
    
    local btnfont = self.data.cfgData[index]['btnfont']
    if index == 1 then
        local hfcount = SL:GetValue("U", 101) or 0
        local yfhcount = SL:GetValue("U", 102) or 0
        btnfont = string.format(btnfont, ""..(hfcount-yfhcount))
    elseif self.data.cfgData[index]['exp'] then
        btnfont = string.format(btnfont, ""..self.data.cfgData[index]['exp'])
    end
    
    return btnfont
end

function TipRoleDiePanlData:Open()
    FGUI:Open("A_TipRoleDie", "TipRoleDiePanl", {}, FGUI_LAYER.NORMAL, {destroyTime = 1})
end
function TipRoleDiePanlData:Updata()
    if FGUI:CheckOpen("A_TipRoleDie", "TipRoleDiePanl") then
        FGUI:Close("A_TipRoleDie", "TipRoleDiePanl")
    end
end


return TipRoleDiePanlData