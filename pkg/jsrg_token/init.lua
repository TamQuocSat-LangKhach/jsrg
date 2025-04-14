-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("jsrg_token", Package.CardPack)
extension.extensionName = "jsrg"

extension:loadSkillSkelsByPath("./packages/jsrg/pkg/jsrg_token/skills")

Fk:loadTranslationTable{
  ["jsrg_token"] = "江山如故卡牌",
}

local shade = fk.CreateCard{
  name = "&shade",
  type = Card.TypeBasic,
  skill = "shade_skill",
  is_passive = true,
}
extension:addCardSpec("shade", Card.Spade, 1)
Fk:loadTranslationTable{
  ["shade"] = "影",
  [":shade"] = "基本牌<br/>"..
  "<b>效果</b>：没有效果，不能被使用。<br/>当【影】进入弃牌堆后移出游戏。<br/>当一名角色获得【影】时，均为从游戏外获得♠A的【影】。",
}

local demobilized = fk.CreateCard{
  name = "&demobilized",
  type = Card.TypeTrick,
  skill = "demobilized_skill",
}
extension:addCardSpec("demobilized", Card.Spade, 3)
Fk:loadTranslationTable{
  ["demobilized"] = "解甲归田",
  [":demobilized"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名装备区内有牌的角色<br/>"..
  "<b>效果</b>：目标获得其装备区内的所有牌。",

  ["demobilized_skill"] = "解甲归田",
  ["#demobilized_skill"] = "选择一名角色，目标角色获得其装备区内的所有牌",
}

local js__peace_spell = fk.CreateCard{
  name = "&js__peace_spell",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#js__peace_spell_skill",
}
extension:addCardSpec("js__peace_spell", Card.Heart, 3)
Fk:loadTranslationTable{
  ["js__peace_spell"] = "太平要术",
  [":js__peace_spell"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，防止你受到的属性伤害；你的手牌上限+X（X为存活势力数-1）；当你失去装备区里的【太平要术】后，你摸两张牌，"..
  "然后若你的体力值大于1，则你失去1点体力。",
}

extension:loadCardSkels {
  shade,

  demobilized,

  js__peace_spell,
}

return extension
