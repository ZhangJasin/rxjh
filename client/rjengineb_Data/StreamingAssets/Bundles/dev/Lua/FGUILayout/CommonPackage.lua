CommonPackage = {"component", 'public',"ItemIcon","ImageBG","SkillIcon","SkillIconSquare","MonsterIcon","Loading", "SUI","PlayerIcon"}
if SL:GetValue("PLATFORM_WEB") then 
    table.insert(CommonPackage, "Net")
end
Font = {
    ["FZBWKSK"] = "Font/FZBWKSK.ttf",
}

CommonPackage_PC = {"component", 'public_pc', 'public', "ItemIcon","ImageBG","SkillIcon", "SkillIconSquare","MonsterIcon", "Loading", "SUI","PlayerIcon"}
Font_pc = {
    ["FZBWKSK"] = "Font/FZBWKSK.ttf",
    ["SIMSUN"] = "Font/SIMSUN.ttf"
}

-- 代理开发模式每次都读最新的资源
-- 设置为false可以检查UI的合批结果，打开的话由于每次都加载最新资源，导致资源冗余加载，合批失败
global.QuickDevModel = true
