name = "冰箱过期食物提醒"
description = "当冰箱中的食物即将过期时，通过服务器公告提醒所有玩家。"
author = "凌（Va6gn）"
version = "1.0.0"

-- 兼容性
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- 客户端和服务器都需要安装
client_only_mod = false
all_clients_require_mod = true

-- 图标
icon_atlas = "modicon.xml"
icon = "modicon.tex"

--服务器标签
server_filter_tags = {
    "冰箱过期食物提醒",
    "Va6gn",
    "凌"
}


-- 配置选项
configuration_options = {
    {
        name = "check_interval",
        label = "检查间隔",
        hover = "检查冰箱中食物的时间间隔",
        options = {
            {description = "30秒", data = 30},
            {description = "1分钟", data = 60},
            {description = "2分钟", data = 120},
            {description = "5分钟", data = 300}
        },
        default = 120
    },
    {
        name = "expiry_threshold",
        label = "过期阈值",
        hover = "当食物保鲜度低于此值时发出警告",
        options = {
            {description = "10%", data = 0.1},
            {description = "20%", data = 0.2},
            {description = "30%", data = 0.3},
            {description = "50%", data = 0.5}
        },
        default = 0.2
    },
    {
        name = "show_expiry_time",
        label = "显示过期时间",
        hover = "在提醒中显示食物还有多久过期",
        options = {
            {description = "开启", data = true},
            {description = "关闭", data = false}
        },
        default = true
    }
}
