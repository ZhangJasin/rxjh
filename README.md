# RXJH - 热血江湖网络游戏项目

## 项目简介

本项目是一个基于热血江湖引擎开发的完整MMORPG网络游戏，采用Unity3D + Lua架构，支持服务器端和客户端热更新。

## 技术栈

### 前端
- **渲染引擎**: Unity3D
- **脚本语言**: Lua (509个Lua文件)
- **UI框架**: FairyGUI (FGUI)
- **热更新**: 支持

### 后端
- **服务器语言**: Lua (126个Lua文件)
- **数据库**: MySQL
- **架构**: 分布式服务器架构

## 项目结构

```
rxjianghu1/
├── Mirserver/              # 服务端目录
│   ├── DBServer/          # 数据库服务器
│   ├── LoginGate/         # 登录网关
│   ├── RunGate/           # 游戏网关
│   ├── Mir200/            # 游戏服务器核心
│   │   ├── Envir/         # 游戏环境配置
│   │   ├── QuestDiary/    # 任务系统
│   │   └── SkillFormula/  # 技能公式
│   ├── Config.Json        # 服务器配置文件
│   └── 开始更新程序.bat   # 服务端启动脚本
├── client/                # 客户端目录
│   ├── rjengineb_Data/    # Unity资源数据
│   ├── 热血江湖工具/      # 开发工具集
│   ├── env.json           # 客户端配置
│   ├── version.txt        # 客户端版本 (1.0.0.4)
│   └── _update.zip        # 热更新包
└── 9963d_rxjh_fgui_project/  # UI项目
    ├── assets/            # UI资源 (529张图片)
    ├── settings/          # FGUI配置
    └── .objs/             # 编译输出
```

## 核心功能系统

### 玩家系统
- 职业系统
- 角色创建与成长
- 等级与经验值

### 战斗系统
- 技能系统 (主动技能、被动技能)
- 奇功系统
- 战斗管理器
- 伤害计算

### 装备系统
- 装备强化
- 装备锻造
- 时装系统
- 装备品质与套装

### 经济系统
- 背包系统
- 商店系统
- 拍卖行
- 物品回收

### 社交系统
- 师徒系统
- 公会系统
- 聊天系统
- 好友关系

### 任务系统
- 主线任务
- 支线任务
- 日常任务
- 任务奖励机制

### 其他系统
- 坐骑系统
- 武勋系统
- GM工具箱
- 系统公告

## 环境要求

### 服务端
- Windows Server操作系统
- MySQL 5.6+ 数据库
- 内存: 4GB+
- 硬盘: 10GB+

### 客户端
- Windows 7/8/10/11
- 内存: 2GB+
- 显卡: 支持DirectX 9.0c
- 硬盘: 5GB+

## 安装部署

### 第一步：环境准备
1. 安装MySQL数据库
2. 创建数据库 `RXJH`
3. 导入数据库初始化脚本

### 第二步：服务器配置
编辑 `Mirserver/Config.Json`：
```json
{
    "SQLServer": {
        "M2DBUser": "root",
        "M2DBName": "RXJH",
        "M2DBPsw": "你的密码",
        "M2DBIpaddr": "127.0.0.1",
        "M2DBPort": 3306
    }
}
```

### 第三步：启动服务器
```bash
# 进入服务端目录
cd Mirserver

# 运行启动脚本
开始更新程序.bat
```

### 第四步：启动客户端
运行 `client/rjengineb.exe` 启动游戏客户端

## 服务器端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| 登录服务 | 7000 | 玩家登录验证 |
| 网关服务 | 7100 | 游戏数据传输 |
| 数据库服务 | 7200 | 数据库访问 |
| H5登录 | 7301 | H5端登录支持 |
| 日志服务 | 10000 | 日志记录 |

## 开发文档

详细的开发文档请参考：
- [引擎说明文档](http://engine-doc.hzzaien.com/web/#/132/67493)
- [TXT说明书](http://engine-doc.hzzaien.com/web/#/130/65578)
- [LUA服务端说明书](http://engine-doc.hzzaien.com/web/#/128/65159)
- [LUA前端说明书](http://engine-doc.hzzaien.com/web/#/131/66000)

## 版本信息

- 服务端版本: 8.9
- 客户端版本: 1.0.0.4

## 常见问题

### 1. 数据库连接失败
检查 `Config.Json` 中的数据库配置是否正确，确保MySQL服务已启动。

### 2. 客户端无法连接服务器
检查防火墙设置，确保服务器端口已开放。

### 3. Lua脚本修改不生效
需要重启对应的服务器进程或等待服务器热更新。

## 贡献指南

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

本项目仅供学习交流使用，请勿用于商业用途。

## 联系方式

如有问题，请提交Issue或联系项目维护者。