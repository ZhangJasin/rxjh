ModuleCfg = {
    "Global",                   --全局控制模块
}

ModuleID = {

}
local temp_t = {}
for id,name in pairs(ModuleID) do
    temp_t[name] = id
end
for name,id in pairs(temp_t) do
    ModuleID[name] = id
end