ConstCfg = {

    binding                 = 1858,              --绑定物品规则
    daysec                  = 86400,            --一天的秒数
    attrtime                = 123456789,        --附加属性时间

    --条件
    ConditionType    = {
        NULL         = 0,
        PLAYER_LEVEL = 1,    --等级
        OPEN_DAY     = 2,    --开服时间
        DAY_TIME     = 3,    --某天具体时间点
        WEEK_DAY     = 4,    --每周几
        DATA_TIME    = 5,    --具体时间点
        TASK_ID      = 6,    --任务
        OPEN_DAY_END = 7,   --开服天数，代表第几天结束
        FIRST_RECHARGE     = 8,   --完成首充
        TOTAL_RECHARGE     = 9, -- 累计充值
        ONCE_RECHARGE      = 10, -- 单次充值

    },



}

return ConstCfg