-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package("jsrg_cards", Package.CardPack)
extension.extensionName = "jsrg"

require "packages/utility/utility"

Fk:loadTranslationTable{
  ["jsrg_cards"] = "江山如故卡牌",
}

local peaceSpellSkill = fk.CreateTriggerSkill{
  name = "#js__peace_spell_skill",
  attached_equip = "js__peace_spell",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,
}
local js__peace_spell_maxcards = fk.CreateMaxCardsSkill{
  name = "#js__peace_spell_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("#js__peace_spell_skill") then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    else
      return 0
    end
  end,
}
peaceSpellSkill:addRelatedSkill(js__peace_spell_maxcards)
Fk:addSkill(peaceSpellSkill)
local js__peace_spell = fk.CreateArmor{
  name = "&js__peace_spell",
  suit = Card.Heart,
  number = 3,
  equip_skill = peaceSpellSkill,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    if not player.dead and self.equip_skill:isEffectable(player) then
      --room:broadcastPlaySound("./packages/maneuvering/audio/card/silver_lion")
      --room:setEmotion(player, "./packages/maneuvering/image/anim/silver_lion")
      player:drawCards(2, self.name)
      if player.hp > 1 then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
extension:addCard(js__peace_spell)
Fk:loadTranslationTable{
  ["js__peace_spell"] = "太平要术",
  [":js__peace_spell"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，防止你受到的属性伤害；你的手牌上限+X（X为存活势力数-1）；"..
  "当你失去装备区里的【太平要术】后，你摸两张牌，然后若你的体力值大于1，则你失去1点体力。",
}

local shadeSkill = fk.CreateActiveSkill{
  name = "shade_skill",
  can_use = Util.FalseFunc,
}
local shade = fk.CreateBasicCard{
  name = "&shade",
  suit = Card.Spade,
  number = 1,
  skill = shadeSkill,
}
extension:addCard(shade)
Fk:loadTranslationTable{
  ["shade"] = "影",
	[":shade"] = "基本牌<br/><b>效果</b>：没有效果，不能被使用。<br/>当【影】进入弃牌堆后移出游戏。<br/>当一名角色获得【影】时，均为从游戏外获得♠A的【影】。",
}

local demobilizedSkill = fk.CreateActiveSkill{
  name = "demobilized_skill",
  prompt = "#demobilized_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card)
    local player = Fk:currentRoom():getPlayerById(to_select)
    return #player:getCardIds("e") > 0
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    local equips = to:getCardIds("e")
    if #equips > 0 then
      room:moveCardTo(equips, Card.PlayerHand, to, fk.ReasonPrey, "demobilized", nil, true, to.id)
    end
  end
}
local demobilized = fk.CreateTrickCard{
  name = "&demobilized",
  suit = Card.Spade,
  number = 3,
  skill = demobilizedSkill,
}
extension:addCard(demobilized)
Fk:loadTranslationTable{
  ["demobilized"] = "解甲归田",
  [":demobilized"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名装备区内有牌的角色。<br /><b>效果</b>：目标获得其装备区内的所有牌。",
  ["demobilized_skill"] = "解甲归田",
  ["#demobilized_skill"] = "选择一名装备区内有牌的角色，目标角色获得其装备区内的所有牌",
}
return extension
