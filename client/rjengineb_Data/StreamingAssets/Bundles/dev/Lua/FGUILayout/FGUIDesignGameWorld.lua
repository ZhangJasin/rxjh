-- 游戏世界一些初始化
FGUIDesignGameWorld = {}

function FGUIDesignGameWorld.main()
    -- HUD锁定小，不跟随相机缩放
    SL:SetValue("SETTING_CAMERA_DISTANCE_HUD_LOCK", true)
end