local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local npcDialog = class("npcDialog", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local NpcList = require("game_config/NpcList")
local Language_cfg = require("game_config/cfgcsv/Language")
function npcDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.btnList =  FGUI:ui_delegate(self._ui.btnlist)
    self.btnList2 =  FGUI:ui_delegate(self._ui.btnlist2)
    FGUI:SetCloseUIWhenClickOutside(self)
end
function npcDialog:Enter(initData)
    local npcid = initData.id
    if self._taskModel then
        FGUI:UIModel_Unbind(self._taskModel)
    end
    self._taskModel = FGUI:UIModel_Bind(self._ui.graph_role)
    self._modelIndex = FGUI:UIModel_addLegoModel(self._taskModel, NpcList[npcid]['Appr'], nil, nil,Vector3.one * 1.4)
    FGUI:GTextField_setText(self._ui['npcname'], NpcList[npcid]['Name'])
    local LanguageIndex = NpcList[npcid]['NpcTalk'] or 0
    local context = Language_cfg[LanguageIndex] and Language_cfg[LanguageIndex]['Dec'] or ""
    FGUI:GRichTextField_setText(self._ui['content'], context)
    local btnindexs = NpcList[npcid]['Function_Button']
    local shopid = NpcList[npcid]['Npc_Store']
    if #btnindexs > 4 then
        FGUI:GList_setDefaultItem(self._ui.btnlist2,"ui://7p89srj7t4fp6")
        FGUI:GList_itemRenderer(self._ui.btnlist2,
            function (idx,item)
                local itemTitle = FGUI:GetChild(item,"title")
                local openBag = ""
                local openFun = ""
                if btnindexs[idx+1] == 1 then
                    FGUI:GRichTextField_setText(itemTitle, "强化")
                    openBag = "A_EquipDuanZao"
                    openFun = "EquipDuanZao"
                end
                if btnindexs[idx+1] == 3 then
                    FGUI:GRichTextField_setText(itemTitle, "仓库")
                    openBag = "Bag"
                    openFun = "StoragePanel"
                end
                if btnindexs[idx+1] == 4 then
                    FGUI:GRichTextField_setText(itemTitle, "结束对话")
                end
                if btnindexs[idx+1] == 5 then
                    FGUI:GRichTextField_setText(itemTitle, "打开商店")
                end
                FGUI:setOnClickEvent(item, function()
                    if btnindexs[idx+1] > 4 then
                        ssrMessage:sendmsgEx("npcDialog", "toOpenShop", shopid)
                    else
                        FGUI:Open(openBag, openFun,{},FGUI_LAYER.NORMAL,{fullScreen = false,destroyTime = 1})
                    end 
                    FGUI:Close("NpcDialog","npcDialog")
                end)
            end)
        FGUI:GList_setVirtual(self._ui.btnlist2)
        FGUI:GList_setNumItems(self._ui.btnlist2, #btnindexs)
        FGUI:setVisible(self._ui.btnlist2,true) 
        FGUI:setVisible(self._ui.btnlist,false) 
    else
         FGUI:GList_setDefaultItem(self._ui.btnlist,"ui://7p89srj7t4fp6")
        FGUI:GList_itemRenderer(self._ui.btnlist,
            function (idx,item)
                local itemTitle = FGUI:GetChild(item,"title")
                local openBag = ""
                local openFun = ""
                if btnindexs[idx+1] == 1 then
                    FGUI:GRichTextField_setText(itemTitle, "强化")
                    openBag = "A_EquipDuanZao"
                    openFun = "EquipDuanZao"
                end
                if btnindexs[idx+1] == 3 then
                    FGUI:GRichTextField_setText(itemTitle, "仓库")
                    openBag = "Bag"
                    openFun = "StoragePanel"
                end
                if btnindexs[idx+1] == 4 then
                    FGUI:GRichTextField_setText(itemTitle, "结束对话")
                end
                if btnindexs[idx+1] == 5 then
                    FGUI:GRichTextField_setText(itemTitle, "打开商店")
                end
                FGUI:setOnClickEvent(item, function()
                    if btnindexs[idx+1] > 4 then
                        ssrMessage:sendmsgEx("npcDialog", "toOpenShop", shopid)
                    else
                        FGUI:Open(openBag, openFun,{},FGUI_LAYER.NORMAL,{fullScreen = false,destroyTime = 1})
                    end 
                    FGUI:Close("NpcDialog","npcDialog")
                end)
            end)
        FGUI:GList_setNumItems(self._ui.btnlist, #btnindexs)
        FGUI:setVisible(self._ui.btnlist2,false) 
        FGUI:setVisible(self._ui.btnlist,true) 
    end
end


function npcDialog:update(data)
    print('update',data)
    FGUI:Open("NpcDialog", "npcDialog",{id = data},FGUI_LAYER.NORMAL,{fullScreen = false,destroyTime = 1})
end



return npcDialog