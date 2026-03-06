TopCurrency = {}

local count = 0
local dataList = {}
function TopCurrency.main()
    count = 0
    dataList = {}
end

function TopCurrency.Show(idStr)
    if not idStr or idStr == "" then return end
    table.insert(dataList, idStr)
    count = count + 1
    dataList[count] = idStr
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("TopCurrency_pc", "PCTopCurrencyPanel", idStr, nil, {esc = false, classPath="FGUILayout/TopCurrency/TopCurrencyPanel"})
    else
        FGUI:Open("TopCurrency", "TopCurrencyPanel", idStr)
    end
end

function TopCurrency.Hide()
    if count <= 0 then return end
    dataList[count] = nil
    count = count - 1
    if SL:GetValue("IS_PC_OPER_MODE") then
        if count > 0 then
            FGUI:Open("TopCurrency_pc", "PCTopCurrencyPanel", dataList[count], nil, {esc = false, classPath="FGUILayout/TopCurrency/TopCurrencyPanel"})
        else
            FGUI:Close("TopCurrency_pc", "PCTopCurrencyPanel")
        end
    else
        if count > 0 then
            FGUI:Open("TopCurrency", "TopCurrencyPanel", dataList[count])
        else
            FGUI:Close("TopCurrency", "TopCurrencyPanel")
        end
    end
end