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

General:new(extension, "js__weiwenzhugezhi", "wu", 4):addSkills { "js__fuhaiw" }
Fk:loadTranslationTable{
  ["js__weiwenzhugezhi"] = "卫温诸葛直",
  ["#js__weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:js__weiwenzhugezhi"] = "猎枭",
}

return extension
