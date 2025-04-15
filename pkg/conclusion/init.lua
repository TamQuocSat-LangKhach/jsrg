local extension = Package:new("conclusion")
extension.extensionName = "jsrg"

extension:loadSkillSkelsByPath("./packages/jsrg/pkg/conclusion/skills")

Fk:loadTranslationTable{
  ["conclusion"] = "江山如故·合",
}


General:new(extension, "js__zhaoyun", "shu", 4):addSkills { "longlin", "zhendan" }
Fk:loadTranslationTable{
  ["js__zhaoyun"] = "赵云",
  ["#js__zhaoyun"] = "北伐之柱",
  ["illustrator:js__zhaoyun"] = "鬼画府",

  ["~js__zhaoyun"] = "北伐！北伐…北伐……",
}

--General:new(extension, "js__luxun", "wu", 3):addSkills { "js__youjin", "js__dailao" }
Fk:loadTranslationTable{
  ["js__luxun"] = "陆逊",
  ["#js__luxun"] = "却敌安疆",
  ["illustrator:js__luxun"] = "鬼画府",
}

--General:new(extension, "sunjun", "wu", 4):addSkills { "yaoyan", "bazheng" }
Fk:loadTranslationTable{
  ["sunjun"] = "孙峻",
  ["#sunjun"] = "朋党执虎",
  ["illustrator:sunjun"] = "鬼画府",
}

--General:new(extension, extension, "js__sunlubansunluyu", "wu", 3, 3, General.Female):addSkills { "daimou", "fangjie" }
Fk:loadTranslationTable{
  ["js__sunlubansunluyu"] = "孙鲁班孙鲁育",
  ["#js__sunlubansunluyu"] = "恶紫夺朱",
  ["illustrator:js__sunlubansunluyu"] = "鬼画府",

  ["daimou"] = "殆谋",
  [":daimou"] = "每回合各限一次，当一名角色使用【杀】指定其他角色/你为目标时，你可以用牌堆顶的牌“蓄谋”/你须弃置你区域里的一张“蓄谋”牌。"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。"..
  "<br/><font color='grey'>#\"<b>蓄谋</b>\"：将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，"..
  "然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",
  ["fangjie"] = "芳洁",
  [":fangjie"] = "准备阶段，若你没有“蓄谋”牌，你回复1点体力并摸一张牌，否则你可以弃置任意张你区域里的“蓄谋”牌并失去此技能。",
}

General:new(extension, "js__weiwenzhugezhi", "wu", 4):addSkills { "js__fuhaiw" }
Fk:loadTranslationTable{
  ["js__weiwenzhugezhi"] = "卫温诸葛直",
  ["#js__weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:js__weiwenzhugezhi"] = "猎枭",
}

return extension
