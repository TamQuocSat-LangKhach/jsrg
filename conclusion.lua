local extension = Package("conclusion")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["conclusion"] = "江山如故·合",
}

--local zhugeliang = General(extension, "js__zhugeliang", "shu", 3)
Fk:loadTranslationTable{
  ["js__zhugeliang"] = "诸葛亮",
}

 --local jiangwei = General(extension, "js__jiangwei", "wu", 4)
Fk:loadTranslationTable{
  ["js__jiangwei"] = "姜维",
}

 --local liuyong = General(extension, "js__liuyong", "shu", 3)
Fk:loadTranslationTable{
  ["js__liuyong"] = "刘永",
  ["js__danxin"] = "丹心",
  [":js__danxin"] = "你可以将一张牌当做【推心置腹】使用，你须展示获得和给出的牌，以此法得到♥️牌的角色回复1点体力，此牌结算后，本回合内你计算与此牌目标的距离+1。",
  ["js__fengxiang"] = "封乡",
  [":js__fengxiang"] = "锁定技，当你受到伤害后，你须与一名其他角色交换装备区内的所有牌，若你装备区内的牌数因此而减少，你摸等同于减少数的牌。",
}

 --local guoxun = General(extension, "js__guoxun", "shu", 4)
Fk:loadTranslationTable{
  ["js__guoxun"] = "郭循",
  ["eqian"] = "遏前",
  [":eqian"] = "结束阶段，你可以【蓄谋】任意次;当你使用【杀】或【蓄谋】牌指定其他角色为唯一目标后，"..
  "你可以令此牌不计入次数限制且获得目标一张牌，然后目标可以令你本回合计算与其的距离+2。",
  ["fusha"] = "伏杀",
  [":fusha"] = "限定技，出牌阶段，若你的攻击范围内仅有一名角色，你可以对其造成X点伤害(X为你的攻击范围且至多为游戏人数)。",
}

 --local gaoxiang = General(extension, "js__gaoxiang", "shu", 4)
Fk:loadTranslationTable{
  ["js__gaoxiang"] = "高翔",
  ["js__chiying"] = "驰应",
  [":js__chiying"] = "出牌阶段限一次，你可以选择一名体力值小于等于你的角色，令其攻击范围内的其他角色各弃置一张牌。若你选择的是其他角色，则其获得其中的基本牌。",
}

--local zhaoyun = General(extension, "js__zhaoyun", "shu", 5)
Fk:loadTranslationTable{
  ["js__zhaoyun"] = "赵云",
}

--local caofang = General(extension, "js__caofang", "wei", 3)
Fk:loadTranslationTable{
  ["js__caofang"] = "曹芳",
}

--local guozhao = General(extension, "js__guozhao", "wei", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__guozhao"] = "郭照",
  ["js__pianchon"] = "偏宠",
  [":js__pianchon"] = "每名角色的结束阶段，若你于此回合内失去过牌，你可以进行一次判定，若判定结果为:黑色/红色，你摸此回合进入弃牌的红色/黑色牌数量的牌",
  ["js__zunwei"] = "尊位",
  [":js__zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一个选择，然后移除该选项: 1，将手牌补至与其手牌数量相同(至多摸五张)。2，将其装备牌移至你的装备区内，直到你装备区内的牌不少于其。3，将体力值回复至与其相同。",
}

--local wenqin = General(extension, "js__wenqin", "wei", 4)
Fk:loadTranslationTable{
  ["js__wenqin"] = "文钦",
  ["js__guangao"] = "广傲",
  [":js__guangao"] = "你使用【杀】可以多指定一个目标，其他角色使用【杀】可以多指定你为目标，若你的手牌数为偶数，你可以摸一张牌，并令此【杀】对其中任意目标无效。",
  ["js__huiqi"] = "慧企",
  [":js__huiqi"] = "觉醒技，每回合结束后，若本回合内有且仅有包含你在内的三名角色成为过牌的目标，你回复一点体力，并获得“楷举”。",
  ["js__kaiju"] = "楷举",
  [":js__kaiju"] = "出牌阶段限一次，你可以令任意名本回合内成为过牌的目标的角色可以将一张黑色牌当做【杀】使用。",
}

--local luxun = General(extension, "js__luxun", "wu", 3)
Fk:loadTranslationTable{
  ["js__luxun"] = "陆逊",
}

--local sunjun = General(extension, "js__sunjun", "wu", 4)
Fk:loadTranslationTable{
  ["js__sunjun"] = "孙峻",
}

--local weiwenzhugezhi = General(extension, "weiwenzhugezhi", "wu", 4)
Fk:loadTranslationTable{
  ["js__weiwenzhugezhi"] = "卫温&诸葛直",
  ["js__fuhai"] = "浮海",
  [":js__fuhai"] = "出牌阶段限一次，你可以令所有其他角色同时展示一张手牌(没有则跳过)，然后你选择一个方向(顺时针或者逆时针)，并摸X张牌(X为从你开始，该方向上的角色展示的牌点数严格递增或严格递减的牌数，且至少为1)。",
}

--local zhangxuan = General(extension, "js__zhangxuan", "wu", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__zhangxuan"] = "张璇",
  ["js__tongli"] = "同礼",
  [":js__tongli"] = "出牌阶段，当你使用基本牌或普通锦囊牌指定目标后，若你手牌中的花色数等于你此阶段使用牌的张数，你可以展示所有手牌，令此牌效果额外结算一次。",
  ["js__shezang"] = "奢葬",
  [":js__shezang"] = "每轮限一次，当你进入濒死状态时或其他角色于你的回合内进入濒死状态时，你可以可以亮出牌堆顶的四张牌，并获得其中任意张花色各不相同的牌。",
}

--local sunlubansunluyu = General(extension, "js__sunlubansunluyu", "wu", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__sunlubansunluyu"] = "孙鲁班&孙鲁育",
  ["daimou"] = "殆谋",
  [":daimou"] = "每回合各限一次，当一名角色使用【杀】指定其他角色/你为目标时，你可以用牌堆顶的牌【蓄谋】/你须弃置你区域里的一张【蓄谋】牌。"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。",
  ["fangjie"] = "芳潔",
  [":fangjie"] = "准备阶段，若你没有【蓄谋】牌，你回复一点体力并摸一张牌，否则你可以弃置任意张你区域里的【蓄谋】牌并失去此技能。",
}

return extension
