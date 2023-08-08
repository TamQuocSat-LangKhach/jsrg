local extension = Package("continue")
extension.extensionName = "jsrg"

Fk:loadTranslationTable{
  ["continue"] = "江山如故-承包",
}

-- local sunce = General(extension, "js__sunce", "wu", 4)
Fk:loadTranslationTable{
  ["js__sunce"] = "孙策",
  ["duxing"] = "独行",
  [":duxing"] = "出牌阶段限一次，你可以视为使用一张以任意名角色为目标的【决斗】，" ..
    "此牌结算过程中，所有目标的手牌均视为【杀】。",
  ["js__zhiheng"] = "猘横",
  [":js__zhiheng"] = "锁定技，当你使用牌对目标角色造成伤害时，" ..
    "若其于本回合内使用或打出牌响应过你使用的牌，则此伤害+1。",
  ["zhasi"] = "诈死",
  [":zhasi"] = "限定技，当你受到致命伤害时，你可以防止之，失去猘横并获得制衡，" ..
    "然后令你不计入座次和距离计算直到你对其他角色使用牌或当你受到伤害后。",
  ["bashi"] = "霸世",
  [":bashi"] = "主公技，当你需要打出【杀】或【闪】时，你可令其他吴势力角色各选择是否代替你打出。",
}

-- local chendeng = General(extension, "js__chendeng", "qun", 3)
-- local guanyu = General(extension, "js__guanyu", "shu", 5)
-- local zoushi = General(extension, "js__zoushi", "qun", 3, 3, General.Female)
-- local zhenfu = General(extension, "js__zhenfu", "qun", 3, 3, General.Female)
-- local zhangliao = General(extension, "js__zhangliao", "qun", 4)
-- local zhanghe = General(extension, "js__zhanghe", "qun", 4)
-- local xuyou = General(extension, "js__xuyou", "qun", 3)
-- local lvbu = General(extension, "js__lvbu", "qun", 5)

return extension
