--[[
我在选角界面开始加载
一些需要提前加载的配置可以放这里
]]

function OnGameStateRole()
    FGUI:SetDefaultFont("SimHei")
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Notice_pc", "PCNoticePanel", nil, FGUI_LAYER.NOTICE, {classPath = "FGUILayout/Notice/NoticePanel"})
    else
        FGUI:Open("Notice", "NoticePanel", nil, FGUI_LAYER.NOTICE)
    end
end