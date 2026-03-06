CustomConst = {}

-- 事件类型
CustomConst.EventMask = {
    STATIC = 0,     -- 静态加成(加成后持续跟随角色)
    ATTACK_BF = 1,  -- 攻击前
    ATTACK = 2,     -- 攻击后
    HIT = 3,        -- 被击中
    HEAL = 4,       -- 治疗
    BUFF = 5,       -- BUFF
    BUFF_END = 6,   -- BUFF结束
    DODGE = 7,      -- 闪避
    MISS = 8,       -- 未命中
    FRAGE = 9,      -- 满怒
    SKILL = 10,     -- 释放技能
    HEAL_BF = 11,   -- 治疗前
}

-- 事件对象
CustomConst.EventObject = {
    PLAYER = 1,     --玩家对象
    MONSTER = 2,    --怪物对象
    ALL = 3         --全部
}

-- 战斗公式日志开关
CustomConst.Log = {
  BATTLE = 0,    -- 战斗模块相关打印 0关闭 1开启 2详细
  MANAGER = 0,   -- 功能模块日志打印 0关闭 1开启
}

-- 战斗公式步骤中要打印数据的数据 
CustomConst.WatchAttrs = {
  { "A", 50 },
  { "A", 50 },
  { "A", 50 },
}

-- 攻击飘字 红字白字蓝字等
CustomConst.AttackPiaoZi = {
  BASIC = 1,
  HEAL = 2,
  XINSHEN = 10,   -- 2×
  BISHA   = 11,   -- 1.5×
  DODGE = 10020,   -- 闪避
  MISS = 10022,   -- 未命中
}

-- 需要监听触发的buff
CustomConst.LisAddBuffs = {
  [106] = true,
}

-- 需要监听触发删除的buff
CustomConst.LisEndBuffs = {
    [100] = true,
    [101] = true,
    [301] = true,
    [401] = true,

    -- 增加刺客超必杀几率
    [126101] = true,
    [126102] = true,
    [126103] = true,
    [126104] = true,
    [126105] = true,
    [126106] = true,
    [126107] = true,
    [126301] = true,
    [126302] = true,
    [126303] = true,
    [126304] = true,
    [126305] = true,
    [126306] = true,
    [126307] = true,
}

-- 需要监听动态属性控制buff
CustomConst.LisAbilAutoBuffs = {
    [1030] = true,
    [1031] = true,
    [1032] = true,
    [1033] = true,
    [1034] = true,

    [126201] = true,
    [126202] = true,
    [126203] = true,
    [126204] = true,
    [126205] = true,
    [126206] = true,
    [126207] = true,
}

-- BUFF
CustomConst.BuffId = {
    RAGE = 100,     -- 怒气id(怒气会有定时清理玩法，所以怒气值使用buff增减)
    STATIC = 11,     -- 被动静态增加属性使用统一加在此BuffId下，不需要在buff中先配置
}

-- 被动静态属性
CustomConst.BuffIdStatic = {
  RAGE = 100,
}

-- 玩家字符串变量
CustomConst.HumVarStr = {
    QGSTATE   = "S$气功状态"      -- 记录气功状态 气功等级改变时卸载旧数据
}

return CustomConst