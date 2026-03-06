local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local RechargeQRCodePanel = class("RechargeQRCodePanel", BaseFGUILayout)

RechargeQRCodePanel.PAY_TYPE = {
    ALIPAY = 1,
    HUABEI = 2,
    WEIXIN = 3
}

local PAY_TYPE = RechargeQRCodePanel.PAY_TYPE
RechargeQRCodePanel._rechargeTips =
{
    [PAY_TYPE.ALIPAY] = "请使用手机 <font color='#00ff00'>支付宝</font> 扫描二维码支付",
    [PAY_TYPE.HUABEI] = "请使用手机 <font color='#00ff00'>支付宝</font> 扫描二维码支付",
    [PAY_TYPE.WEIXIN] = "请使用手机 <font color='#00ff00'>微信</font> 扫描二维码支付",
}

function RechargeQRCodePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)

    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.OnClose))
end

function RechargeQRCodePanel:OnClose()
	self.super.Close(self)
end

function RechargeQRCodePanel:Enter(data)
    -- 
    self:RegisterEvent()
    self:ShowQRCode(data)
end

function RechargeQRCodePanel:Exit()
    FGUI:stopAllActions(self._ui.text_time)
    self:UnRegisterEvent()
end

function RechargeQRCodePanel:ShowQRCode(data)
    -- qrcode
    local texture = data.texture
    if texture then
        FGUI:GLoader_setTexture(self._ui.image_qrcode, texture, true)
    end

    -- qrcode tips
    local channel     = data.channel
    local setTips     = SL:GetValue("RECHARGE_TIP") or self._rechargeTips[channel]
    FGUI:GRichTextField_setText(self._ui.text_qrcode_tips, setTips)

    local rightTime = 40 -- 倒计时40秒
    local function showRightTime()
        FGUI:GTextField_setText(self._ui.text_time, string.format("剩余时间：%s秒", rightTime))
        if rightTime <= 0 then
            FGUI:stopAllActions(self._ui.text_time)
            --  image_qrcode  ShaderShadow
            FGUI:GTextField_setText(self._ui.text_time, "二维码已过期")
            SL:ShowSystemTips("二维码已过期")
        end
        rightTime = math.max(0, rightTime - 1)
    end
    showRightTime()
    SL:schedule(self._ui.text_time, showRightTime, 1)
end

function RechargeQRCodePanel:OnRechargeReceived()
    self:OnClose()
end

function RechargeQRCodePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_RECHARGE_SUCCESS, "RechargeQRCodePanel", handler(self, self.OnRechargeReceived))
end

function RechargeQRCodePanel:UnRegisterEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_RECHARGE_SUCCESS, "RechargeQRCodePanel")
end

return RechargeQRCodePanel