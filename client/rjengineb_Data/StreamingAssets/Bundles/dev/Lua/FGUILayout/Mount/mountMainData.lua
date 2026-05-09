-- 坐骑和灵兽数据管理器
local mountMainData = {}

local Mount = require("game_config/cfgcsv/Mount")
local MountHuanhua = require("game_config/cfgcsv/MountHuanhua")
local Pet = require("game_config/cfgcsv/Pet")
local PetHuanhua = require("game_config/cfgcsv/PetHuanhua")

-- 常量定义
local TAB_TYPE = {
    MOUNT = 0,    -- 坐骑标签
    MOUNT_HH = 1, -- 坐骑幻化标签
    PET = 2,      -- 灵兽标签
    PET_HH = 3    -- 灵兽幻化标签
}

local STATUS = {
    FIGHT = 0, -- 出战状态
    REST = 1   -- 休息状态
}

-- 数据存储结构
local _data = {
    _subscribers = {} -- 事件订阅者
}

local _dataForMount = {
    mountHHid = 0,                                     -- 当前坐骑id
    ischuzhan = 0,                                     -- 是否出战
    isJh = 0,                                          -- 是否已激活
    modelId = (Mount[1] and Mount[1].Model) or 800001, -- 当前坐骑基础模型id
    allJieshu = 0,                                     -- 坐骑总星星数
    hhlistsj = {},                                     -- 坐骑幻化升级对象
    hhSortList = {}                                    -- 坐骑幻化列表排序后的
}

local _dataForPet = {
    petHHid = 0,                                   -- 当前灵兽幻化id
    isPetChuzhan = 0,                              -- 灵兽是否出战
    isPetJh = 0,                                   -- 灵兽是否已激活
    modelId = (Pet[1] and Pet[1].Model) or 800001, -- 当前灵兽基础模型id
    allJieshu = 0,                                 -- 灵兽总星星数
    hhlistsj = {},                                 -- 灵兽幻化升级对象
    hhSortList = {},                               -- 灵兽幻化列表排序后的
    allPetsActive = {},                            -- 当前灵兽激活情况(兼容保留)
    allPetsToModel = {},                           -- 已激活的本体(兼容保留)
    showPetModelId = 0,                            -- 当前显示模型id
    petIndex = 0,                                  -- 当前显示模型下标 0本体 0以上幻化
    allPets = {},                                  -- 灵兽初始化(兼容保留)
    allPetsHH = {},                                -- 灵兽幻化(兼容保留)
    selectPetIndex = 1,                            -- 当前选择索引
    selectViewPetId = 0                            -- 当前出战宠物本体ID
}

-- ================= 工具函数 =================

-- 【通用】根据模型ID获取对应名称
local function GetNameByModel(modelId, configList)
    local id = tonumber(modelId)
    if not id or id == 0 then return "" end
    for i = 1, #configList do
        if configList[i].Model == id then return configList[i].Name end
    end
    return ""
end

-- 【通用】获取排序后的幻化列表 (修复了原版代码直接修改配置表内存的严重Bug)
local function GetSortedHuanhuaList(configList, activeMap, currentModelId)
    local names = {}
    local results = {}
    local currentName = GetNameByModel(currentModelId, configList)

    for i = 1, #configList do
        local hhItem = configList[i]
        if hhItem.grade and tonumber(hhItem.grade) > 0 then
            if not names[hhItem.Name] then
                if activeMap[hhItem.Name] then
                    -- 已激活
                    names[hhItem.Name] = true
                    local obj = {}
                    for k, v in pairs(hhItem) do obj[k] = v end -- 浅拷贝，防止污染只读配置表
                    obj.weizhi = (currentName == hhItem.Name) and 1 or 2
                    table.insert(results, obj)
                elseif hhItem.grade == 1 and SL:GetValue(CONDITION, hhItem.Condition) then
                    -- 未激活但满足条件
                    names[hhItem.Name] = true
                    local obj = {}
                    for k, v in pairs(hhItem) do obj[k] = v end
                    obj.weizhi = 3
                    table.insert(results, obj)
                end
            end
        end
    end

    -- 排序：已幻化(1) > 已激活(2) > 未激活(3) > ID
    table.sort(results, function(a, b)
        if a.weizhi == b.weizhi then
            return a.ID < b.ID
        end
        return a.weizhi < b.weizhi
    end)
    return results
end

-- ================= 核心管理器逻辑 =================

-- 初始化数据管理器
function mountMainData:Init()
    -- 坐骑相关数据
    _dataForMount.mountHHid = SL:GetValue("U", 36)
    _dataForMount.modelId = SL:GetValue("U", 37) > 0 and SL:GetValue("U", 37) or (Mount[1] and Mount[1].Model) or 800001
    _dataForMount.ischuzhan = SL:GetValue("U", 39)
    _dataForMount.isJh = SL:GetValue("U", 40)
    _dataForMount.allJieshu = SL:GetValue("U", 35)

    local t7 = SL:GetValue("T", 7)
    _dataForMount.hhlistsj = (t7 and t7 ~= "") and SL:JsonDecode(t7) or {}
    _dataForMount.hhSortList = GetSortedHuanhuaList(MountHuanhua, _dataForMount.hhlistsj, _dataForMount.mountHHid)

    -- 灵兽相关数据
    _dataForPet.petHHid = SL:GetValue("U", 107)
    _dataForPet.modelId = SL:GetValue("U", 108) > 0 and SL:GetValue("U", 108) or (Pet[1] and Pet[1].Model) or 800001
    _dataForPet.isPetChuzhan = SL:GetValue("U", 110) or 0
    _dataForPet.isPetJh = SL:GetValue("U", 106) > 0 and 1 or 0
    _dataForPet.allJieshu = SL:GetValue("U", 106)

    local t119 = SL:GetValue("T", 119)
    _dataForPet.hhlistsj = (t119 and t119 ~= "") and SL:JsonDecode(t119) or {}

    local petISHH = tonumber(SL:GetValue("U", 109))
    if petISHH == 1 and _dataForPet.petHHid and tonumber(_dataForPet.petHHid) > 0 then
        _dataForPet.showPetModelId = tonumber(_dataForPet.petHHid)
    else
        _dataForPet.showPetModelId = SL:GetValue("U", 108)
    end
    _dataForPet.selectViewPetId = SL:GetValue("U", 108)

    -- 兼容旧字段
    _dataForPet.allPetsActive = _dataForPet.hhlistsj
    _dataForPet.allPetsToModel = _dataForPet.hhlistsj
    _dataForPet.hhSortList = GetSortedHuanhuaList(PetHuanhua, _dataForPet.hhlistsj, _dataForPet.petHHid)
end

function mountMainData.Get() return mountMainData end

function mountMainData:GetDataForMount()
    return {
        mountHHid = _dataForMount.mountHHid,
        ischuzhan = _dataForMount.ischuzhan,
        modelId = _dataForMount.modelId,
        isJh = _dataForMount.isJh,
        allJieshu = _dataForMount.allJieshu,
        hhlistsj = _dataForMount.hhlistsj,
        hhSortList = _dataForMount.hhSortList
    }
end

function mountMainData:GetDataForPet()
    return {
        petHHid = _dataForPet.petHHid,
        isPetChuzhan = _dataForPet.isPetChuzhan,
        modelId = _dataForPet.modelId,
        isPetJh = _dataForPet.isPetJh,
        allJieshu = _dataForPet.allJieshu,
        hhlistsj = _dataForPet.hhlistsj,
        hhSortList = _dataForPet.hhSortList,
        allPetsActive = _dataForPet.allPetsActive,
        allPetsToModel = _dataForPet.allPetsToModel,
        showPetModelId = _dataForPet.showPetModelId,
        selectViewPetId = _dataForPet.selectViewPetId,
        petIndex = _dataForPet.petIndex,
        allPets = _dataForPet.allPets,
        allPetsHH = _dataForPet.allPetsHH,
        selectPetIndex = _dataForPet.selectPetIndex
    }
end

-- ================= 事件发布订阅 =================

function mountMainData:Subscribe(event, callback)
    if not _data._subscribers[event] then _data._subscribers[event] = {} end
    local token = #_data._subscribers[event] + 1
    _data._subscribers[event][token] = callback
    return { event = event, token = token }
end

function mountMainData:Unsubscribe(subscription)
    if subscription and subscription.event and subscription.token then
        if _data._subscribers[subscription.event] then
            _data._subscribers[subscription.event][subscription.token] = nil
        end
    end
end

function mountMainData:Publish(event, data)
    if _data._subscribers[event] then
        for _, callback in pairs(_data._subscribers[event]) do
            if callback then callback(data) end
        end
    end
end

-- ================= 供 UI 调用的封装方法 =================

-- 获取坐骑幻化排序列表
function mountMainData:setHHListSort()
    return GetSortedHuanhuaList(MountHuanhua, _dataForMount.hhlistsj, _dataForMount.mountHHid)
end

-- 获取灵兽幻化排序列表
function mountMainData:setPetHHListSort()
    return GetSortedHuanhuaList(PetHuanhua, _dataForPet.hhlistsj, _dataForPet.petHHid)
end

-- 根据模型获取名称 (向下兼容)
function mountMainData:getNameByModel(model)
    return GetNameByModel(model, MountHuanhua)
end

function mountMainData:getPetNameByModel(model)
    return GetNameByModel(model, PetHuanhua)
end

-- ================= 网络消息发送 =================

function mountMainData:lsjihuo(data) ssrMessage:sendmsgEx("mountMain", "lsjihuo", data) end

function mountMainData:levelUp(data) ssrMessage:sendmsgEx("mountMain", "levelUp", data) end

function mountMainData:updatePetModel(data) ssrMessage:sendmsgEx("mountMain", "updatePetModel", data) end

function mountMainData:petTodoHHlist(data) ssrMessage:sendmsgEx("mountMain", "petHuanhuajihuo", data) end

function mountMainData:recallpet(data) ssrMessage:sendmsgEx("mountMain", "recallpet", data) end

function mountMainData:unrecallpet() ssrMessage:sendmsgEx("mountMain", "unrecallpet", { isNeedBack = 1 }) end

function mountMainData:petChuzhan() ssrMessage:sendmsgEx("mountMain", "petChuzhan") end

function mountMainData:setModel(data) ssrMessage:sendmsgEx("mountMain", "setModel", data) end

function mountMainData:setPetModel(data) ssrMessage:sendmsgEx("mountMain", "setPetModel", data) end

function mountMainData:todoHHlist(data) ssrMessage:sendmsgEx("mountMain", "huanhuajihuo", data) end

function mountMainData:shengji() ssrMessage:sendmsgEx("mountMain", "shengji") end

function mountMainData:chuzhan() ssrMessage:sendmsgEx("mountMain", "chuzhan") end

-- ================= 网络消息接收与处理 =================

-- 单灵兽系统：激活灵兽
function mountMainData:updateLSView(data)
    _dataForPet.isPetJh = data.lv > 0 and 1 or 0
    _dataForPet.allJieshu = data.lv
    self:Publish("ls_list_update", { _dataForPet = self:GetDataForPet(), selectPetIndex = 1 })
end

function mountMainData:level(data)
    _dataForPet.allJieshu = data.lv
    self:Publish("ls_level_result", self:GetDataForPet())
end

function mountMainData:updatePetModelResult(data)
    _dataForPet.allPetsToModel = data.allPetsHHData
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.petHHid = data.petHHid or 0
    _dataForPet.hhSortList = self:setPetHHListSort()
    self:Publish("ls_update_model", self:GetDataForPet())
    self:Publish("updatePetModelResult", data)
end

function mountMainData:recallpetResult(data)
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.selectViewPetId = data.selectViewPetId
    _dataForPet.isPetChuzhan = data.isPetChuzhan ~= nil and data.isPetChuzhan or 1
    self:Publish("ls_update_model", self:GetDataForPet())
    self:Publish("petUpdateBtn", self:GetDataForPet())
end

function mountMainData:unrecallpetResult(data)
    _dataForPet.showPetModelId = 0
    _dataForPet.selectViewPetId = 0
    _dataForPet.isPetChuzhan = (data and data.isPetChuzhan ~= nil) and data.isPetChuzhan or 0
    self:Publish("ls_unrecallpet", self:GetDataForPet())
    self:Publish("petUpdateBtn", self:GetDataForPet())
end

function mountMainData:UpdateHHBtnName(data)
    _dataForMount.mountHHid = data.mountHHid
    _dataForMount.hhSortList = self:setHHListSort()
    local selectHHIndex = 1
    if tonumber(data.isCancel) ~= 0 then
        for i = 1, #_dataForMount.hhSortList do
            if _dataForMount.hhSortList[i].Name == self:getNameByModel(data.oldModelId) then
                selectHHIndex = i; break
            end
        end
    end
    self:Publish("updateHHResult", { _dataForMount = self:GetDataForMount(), selectHHIndex = selectHHIndex })
end

function mountMainData:updateHHmodel(data)
    _dataForMount.hhlistsj = data.ycList
    _dataForMount.mountHHid = data.mountHHid
    _dataForMount.hhSortList = self:setHHListSort()
    local selectHHIndex = 0
    for i = 1, #_dataForMount.hhSortList do
        if _dataForMount.hhSortList[i].Name == data.name then
            selectHHIndex = i; break
        end
    end
    self:Publish("updateHHResult", { _dataForMount = self:GetDataForMount(), selectHHIndex = selectHHIndex })
end

function mountMainData:updateZQ(data)
    if data.lv == 1 then
        _dataForMount.isJh = 1
        if not _dataForMount.hhlistsj or next(_dataForMount.hhlistsj) == nil then _dataForMount.hhlistsj = {} end
    end
    _dataForMount.allJieshu = tonumber(data.lv)
    self:Publish("mountLevelUp", self:GetDataForMount())
end

function mountMainData:updateBtnName(data)
    _dataForMount.ischuzhan = data.status
    self:Publish("mountUpdateBtn", self:GetDataForMount())
end

function mountMainData:updatePetHHmodel(data)
    _dataForPet.hhlistsj = data.ycList
    _dataForPet.petHHid = data.petHHid
    if data.petHHid and data.petHHid > 0 then
        _dataForPet.showPetModelId = tonumber(data.petHHid)
    end
    _dataForPet.hhSortList = self:setPetHHListSort()
    local selectHHIndex = 0
    for i = 1, #_dataForPet.hhSortList do
        if _dataForPet.hhSortList[i].Name == data.name then
            selectHHIndex = i; break
        end
    end
    self:Publish("petUpdateHHResult", { _dataForPet = self:GetDataForPet(), selectHHIndex = selectHHIndex })
end

function mountMainData:UpdatePetHHBtnName(data)
    _dataForPet.petHHid = data.petHHid
    _dataForPet.hhSortList = self:setPetHHListSort()
    local selectHHIndex = 1
    if tonumber(data.isCancel) ~= 0 then
        for i = 1, #_dataForPet.hhSortList do
            if _dataForPet.hhSortList[i].Name == self:getPetNameByModel(data.oldModelId) then
                selectHHIndex = i; break
            end
        end
    end
    self:Publish("petUpdateHHResult", { _dataForPet = self:GetDataForPet(), selectHHIndex = selectHHIndex })
end

function mountMainData:updatePetZQ(data)
    if data.lv == 1 then
        _dataForPet.isPetJh = 1
        if not _dataForPet.hhlistsj or next(_dataForPet.hhlistsj) == nil then _dataForPet.hhlistsj = {} end
        _dataForPet.isPetChuzhan = 1
        self:Publish("petUpdateBtn", self:GetDataForPet())
    end
    _dataForPet.allJieshu = tonumber(data.lv)
    if data.showPetModelId and data.showPetModelId > 0 then
        _dataForPet.modelId = tonumber(data.showPetModelId)
        _dataForPet.showPetModelId = tonumber(data.showPetModelId)
    else
        _dataForPet.modelId = tonumber(data.petBaseId)
    end
    self:Publish("petLevelUp", self:GetDataForPet())
end

function mountMainData:petUpdateBtn(data)
    if data.isPetChuzhan ~= nil then _dataForPet.isPetChuzhan = data.isPetChuzhan end
    if data.isPetJh ~= nil then _dataForPet.isPetJh = data.isPetJh end
    if data.allJieshu ~= nil then _dataForPet.allJieshu = data.allJieshu end
    self:Publish("petUpdateBtn", self:GetDataForPet())
end

return mountMainData
