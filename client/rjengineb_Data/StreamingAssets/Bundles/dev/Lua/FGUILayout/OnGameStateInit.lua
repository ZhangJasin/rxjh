--[[
我在选角界面开始加载
一些需要提前加载的配置可以放这里
]]

function OnGameStateInit()
    SL:Print("Hello World, This is OnGameStateInit!")

    -- 设置字体与文字相关设置
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:SetFontTextureScale(1)
    else
        FGUI:SetFontTextureScale(2)
    end

    -- 设置鼠标经过提示
    FGUI:SetToolTipsWin("ui://public/ToolTips")

    -- 设置按钮默认点击音效
    FGUI:SetDefaultButtonSound("ui://public/Sound_click")

    -- 初始化对象池
    SL:RequireFile("FGUILayout/Pool")

    -- 设置ItemShow池
    local packageName = SL:GetValue("IS_PC_OPER_MODE") and "public_pc" or "public"
    Pool.RegisterClass(packageName, "CommonEquip", "FGUILayout/Item/ItemEquipShow")
    Pool.RegisterClass(packageName, "CommonItem", "FGUILayout/Item/ItemShow")

    
    ssrGameEvent      = SL:RequireFile("FGUILayout/GameEvent")
    
    -- 网络
    ssrNetMsgCfg      = SL:RequireFile("FGUILayout/NetMsgCfg")
    ssrMessage = SL:RequireFile("FGUILayout/Message"):Register()
end
OnGameStateInit()