local GPluginPath = _G.PluginPath

local FilterItemIconView = nil
local toolMenu = App.menu:GetSubMenu("tool")
toolMenu:AddItem("设置ItemIcon过滤", "FilterItemIcon", function()
    if not FilterItemIconView then
        App.pluginManager:LoadUIPackage(GPluginPath .. '/Package/FilterItemIcon')
        FilterItemIconView = CS.FairyGUI.UIPackage.CreateObject("FilterItemIcon", "View")

        local Input_itemPath = FilterItemIconView:GetChild("TextInput_item")
        local Input_itemEquipPath = FilterItemIconView:GetChild("TextInput_itemEquip")
        local Button_close = FilterItemIconView:GetChild("Button_close")

        Input_itemPath.title = CS.UnityEngine.PlayerPrefs.GetString("Item_Path") or ""
        Input_itemEquipPath.title = CS.UnityEngine.PlayerPrefs.GetString("ItemEquip_Path") or ""

        Button_close.onClick:Set(function()
            CS.UnityEngine.PlayerPrefs.SetString("Item_Path", Input_itemPath.title or "")
            CS.UnityEngine.PlayerPrefs.SetString("ItemEquip_Path", Input_itemEquipPath.title or "")
            FilterItemIconView:RemoveFromParent()
        end)
    end

    local parent = App.groot
    parent:AddChild(FilterItemIconView)
    FilterItemIconView:SetPosition(parent.width / 2, parent.height / 2)
end)

local function Run(package)
    local ItemPath = CS.UnityEngine.PlayerPrefs.GetString("Item_Path")
    ItemPath = string.gsub(ItemPath, "%.%w+$", "")
    local ok, ItemLua = pcall(require, ItemPath)
	if not ok then
        fprint("[996Extend-Warn]未在ItemIcon包下找到Item.lua配置文件")
        return
    end
    local ItemEquipPath = CS.UnityEngine.PlayerPrefs.GetString("ItemEquip_Path")
    ItemEquipPath = string.gsub(ItemEquipPath, "%.%w+$", "")
    local ok, ItemEquipLua = pcall(require, ItemEquipPath)
	if not ok then
        fprint("[996Extend-Warn]未在ItemIcon包下找到ItemEquip.lua配置文件")
        return
    end
    local iconMap = {}
    local ok = pcall(function()
        for k, v in pairs(ItemLua) do
            if v.Looks and v.Looks > 0 then
                if v.Looks > 100000 then
                    iconMap[tostring(v.Looks)] = true
                else
                    iconMap[string.format("%06d", v.Looks)] = true
                end
            end
        end
        for k, v in pairs(ItemEquipLua) do
            if v.Looks and v.Looks > 0 then
                if v.Looks > 100000 then
                    iconMap[tostring(v.Looks)] = true
                else
                    iconMap[string.format("%06d", v.Looks)] = true
                end
            end
        end
    end)
    if not ok then
        fprint("[996Extend-Error]读取配置数据时发生错误")
        return
    else
        -- local ignoreFolder = package:FindItemByName("ignore") or package:FindItemByName("Ignore")
        -- if not ignoreFolder then
        --     ignoreFolder = package:CreateFolder("ignore")
        -- end
        -- if not ignoreFolder then
        --     fprint("[996Extend-Error]创建ItemIcon/Ignore目录失败")
        --     return
        -- end
        local libView = App.libView
        local items = package.items
        local exportedList = {}
        local noExportedList = {}
        for k, item in pairs(items) do
            local id = tonumber(item.name)
            -- 仅纯数字认为是道具icon,其余的忽视
            if id then
                if iconMap[item.name] then
                    item.exported = true
                    table.insert(exportedList, item)
                else
                    item.exported = false
                    table.insert(noExportedList, item)
                end
            end
        end
        libView:SetResourcesExported(exportedList, true)
        libView:SetResourcesExported(noExportedList, false)
        return true
    end
end

local FilterItemIcon = {}

function FilterItemIcon.onPublishStart(packages)
    if not packages then return end
    local len = packages.Length
    for i = 0, len - 1 do
        local package = packages[i]
        if package.name == "ItemIcon" then
            fprint('[996Extend-Info] Publish - Filter ItemIcon Start')
            Run(package)
            fprint('[996Extend-Info] Publish - Filter ItemIcon End')
        end
    end
end


function FilterItemIcon.onDestroy()
    -------do cleanup here-------
    toolMenu:RemoveItem("FilterItemIcon")
    if FilterItemIconView then
        FilterItemIconView:Dispose()
        FilterItemIconView = nil
    end
end

return FilterItemIcon