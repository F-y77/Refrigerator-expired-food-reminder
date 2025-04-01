-- 冰箱过期食物提醒模组
-- 从配置中获取参数

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local FOOD_CHECK_INTERVAL = GetModConfigData("check_interval")
local EXPIRY_THRESHOLD = GetModConfigData("expiry_threshold")
local SHOW_EXPIRY_TIME = GetModConfigData("show_expiry_time")
local REMINDER_MESSAGE = GetModConfigData("reminder_message")
local SHOW_DEBUG_LOG = GetModConfigData("show_debug_log")

-- 调试日志函数
local function PrintLog(...)
    if SHOW_DEBUG_LOG then
        print(...)
    end
end

-- 获取食物名称的本地化字符串
local function GetLocalizedFoodName(prefab)
    local translation = STRINGS.NAMES[string.upper(prefab)] or prefab
    return translation
end

-- 计算食物还有多久过期
local function GetExpiryTimeString(item)
    if not item.components.perishable then
        return ""
    end
    
    local perishTime = item.components.perishable.perishtime or 0
    local curTime = item.components.perishable.perishremainingtime or 0
    
    -- 如果已经腐烂或没有剩余时间
    if curTime <= 0 then
        return "已腐烂"
    end
    
    -- 使用饥荒的固定时间值（单位：秒）
    local TOTAL_DAY_TIME = 480  -- 一天的总时间
    local SEGMENT_TIME = 30     -- 一个时间段的长度
    
    local days = math.floor(curTime / TOTAL_DAY_TIME)
    local hours = math.floor((curTime % TOTAL_DAY_TIME) / (SEGMENT_TIME * 2))
    local minutes = math.floor((curTime % (SEGMENT_TIME * 2)) / (SEGMENT_TIME / 6))
    
    local timeString = ""
    if days > 0 then
        timeString = days .. "天"
    end
    
    if hours > 0 or days > 0 then
        timeString = timeString .. hours .. "小时"
    end
    
    timeString = timeString .. minutes .. "分钟"
    
    return timeString
end

-- 检查冰箱中的食物
local function CheckIceboxFood()
    if not TheWorld.ismastersim then
        return
    end
    
    -- 获取所有冰箱
    local iceboxes = {}
    for _, v in pairs(Ents) do
        if v:HasTag("fridge") then
            table.insert(iceboxes, v)
        end
    end
    
    -- 检查每个冰箱中的食物
    local expiring_foods = {}
    local expiry_times = {}
    local total_checked = 0
    
    for _, icebox in ipairs(iceboxes) do
        if icebox.components.container then
            for slot = 1, icebox.components.container:GetNumSlots() do
                local item = icebox.components.container:GetItemInSlot(slot)
                
                if item and item.components.perishable then
                    total_checked = total_checked + 1
                    local percent = item.components.perishable:GetPercent()
                    
                    -- 调试信息
                    PrintLog("检查食物: " .. item.prefab .. ", 保鲜度: " .. tostring(percent * 100) .. "%, 阈值: " .. tostring(EXPIRY_THRESHOLD * 100) .. "%, 是否腐烂: " .. tostring(item:HasTag("spoiled")))
                    
                    if percent <= EXPIRY_THRESHOLD then
                        local prefab_name = item.prefab
                        
                        if not expiring_foods[prefab_name] then
                            expiring_foods[prefab_name] = 0
                            if SHOW_EXPIRY_TIME then
                                expiry_times[prefab_name] = GetExpiryTimeString(item)
                            end
                        end
                        
                        expiring_foods[prefab_name] = expiring_foods[prefab_name] + (item.components.stackable and item.components.stackable:StackSize() or 1)
                    end
                end
            end
        end
    end
    
    -- 调试信息
    PrintLog("检查了 " .. total_checked .. " 个食物项目")
    
    -- 如果有即将过期的食物，发送公告
    local has_expiring_food = false
    local message = "警告：冰箱中有食物即将过期："
    
    for food, count in pairs(expiring_foods) do
        if count > 0 then
            has_expiring_food = true
            local food_message = "\n" .. GetLocalizedFoodName(food) .. " x" .. count
            
            -- 如果开启了显示过期时间，添加过期时间信息
            if SHOW_EXPIRY_TIME and expiry_times[food] then
                food_message = food_message .. " (还有" .. expiry_times[food] .. "过期)"
            end
            
            message = message .. food_message
            
            -- 调试信息
            PrintLog("即将过期: " .. food .. " x" .. count)
        end
    end
    
    if has_expiring_food then
        -- 只有当提示消息不为空时才添加
        if REMINDER_MESSAGE ~= "" then
            message = message .. "\n" .. REMINDER_MESSAGE
        end
        PrintLog("发送公告: " .. message)
        TheNet:Announce(message)
    else
        PrintLog("没有找到即将过期的食物")
    end
end

-- 添加定时检查
local function AddPeriodicFoodCheck()
    if TheWorld.ismastersim then
        PrintLog("启动定期检查，间隔: " .. FOOD_CHECK_INTERVAL .. " 秒")
        -- 立即执行一次检查
        CheckIceboxFood()
        -- 然后设置定期检查
        TheWorld:DoPeriodicTask(FOOD_CHECK_INTERVAL, CheckIceboxFood)
    end
end

-- 模组加载
AddPrefabPostInit("world", function(inst)
    inst:DoTaskInTime(5, AddPeriodicFoodCheck)
end)