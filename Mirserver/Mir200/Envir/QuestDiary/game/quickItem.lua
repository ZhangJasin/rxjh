quickItem = {}
local filname = "quickItem"


-- 判断是否可以使用红蓝药
function quickItem.useItem(actor,itemID,makeIndex,useNumber,curdura,maxdura)               
    local HP_Item_Limit = gethumvar(actor,VarCfg.N_HP_Item_Limit) or 0
    local MP_Item_Limit = gethumvar(actor,VarCfg.N_MP_Item_Limit) or 0
    local SubType = Item_cfg[itemID] and Item_cfg[itemID]['SubType'] or 0
    -- print("HP_Item_Limit",HP_Item_Limit,"MP_Item_Limit",MP_Item_Limit,"SubType",SubType)
    if HP_Item_Limit == 1 and SubType == 1 then
        if bagitemcount(actor, 123) > 0 then
            sendmsg(actor, 9, "你正在使用精炼九转丹，无法使用红药")
            return false
        else
            sethumvar(actor,VarCfg.N_HP_Item_Limit,0)  
        end
    end
    if MP_Item_Limit == 1 and SubType == 2  then
        if bagitemcount(actor, 117) > 0 then
            sendmsg(actor, 9, "你正在使用精炼千年雪参，无法使用蓝药")
            return false
        else
            sethumvar(actor,VarCfg.N_MP_Item_Limit,0)  
        end
    end
    return true
end
-- 部分装备在快捷栏的道具有属性
function quickItem.AttrData(actor,data)
    -- dump(data)
    sethumvar(actor,VarCfg.N_HP_Item_Limit,0)  
    sethumvar(actor,VarCfg.N_MP_Item_Limit,0)  
    delattlist(actor, VarCfg.Attr_QuickEquipItem)
    local attrTab = {}
    local itemTab = {}  -- 已加属性道具列表  防止重复加属性
    for i=1,4 do
        local itemID = data[i]
        if Item_cfg[itemID] and Item_cfg[itemID]['Attribute'] and not itemTab[itemID] then
            local attrList = string.split(Item_cfg[itemID]['Attribute'], "#")
            attrTab[tonumber(attrList[2])] = (attrTab[tonumber(attrList[2])] or 0) + tonumber(attrList[3])
            local stdMode = Item_cfg[itemID]['StdMode']
            if itemID == 123 then         -- 佩戴精练九转丹    禁止使用红药
                sethumvar(actor,VarCfg.N_HP_Item_Limit,1)  
            elseif itemID == 117 then     -- 佩戴精练千年雪参  禁止使用蓝药
                sethumvar(actor,VarCfg.N_MP_Item_Limit,1)  
            end
            itemTab[itemID] = true
        end
    end
    local attrStr = ""
    for k,v in pairs(attrTab) do
        attrStr = (attrStr ~= "" and attrStr.."&" or attrStr)..k.."#"..v
    end
    -- 快捷栏道具增加属性
    addattlist(actor, VarCfg.Attr_QuickEquipItem, "=", attrStr)
end


-------------------------------↓↓↓ 事件 ↓↓↓---------------------------------------

Message.RegisterNetMsg(ssrNetMsgCfg.quickItem, quickItem)
return quickItem



