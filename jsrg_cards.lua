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
  can_use = function()
    return false
  end,
}
local shade = fk.CreateBasicCard{
  name = "&shade",
  suit = Card.Spade,
  number = 1,
  skill = shadeSkill,
}
extension:addCard(shade)
local shade_destruct = fk.CreateTriggerSkill{
  name = "#shade_destruct",
  global = true,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive then  --指定一个触发者防止技能空转
      for _, move in ipairs(data) do
        return move.toArea == Card.DiscardPile
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).trueName == "shade" then
            table.insert(ids, id)
          end
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#destructDerivedCards",
        card = ids,
      }
      local cards = table.map(ids, function(id) return Fk:getCardById(id) end)
      player.room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
Fk:addSkill(shade_destruct)
Fk:loadTranslationTable{
  ["shade"] = "影",
	[":shade"] = "基本牌<br/><b>效果</b>：没有效果，不能被使用。<br/>当【影】进入弃牌堆后移出游戏。<br/>当一名角色获得【影】时，均为从游戏外获得♠A的【影】。",
}

local qingFengSkill = fk.CreateTriggerSkill{
  name = "#qingfeng_sword_skill",
  attached_equip = "qingfeng_sword",
  frequency = Skill.Compulsory,
  events = { fk.TargetSpecified },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    room:addPlayerMark(room:getPlayerById(data.to), "qingfengMark")
    data.extra_data = data.extra_data or {}
    data.extra_data.qingfengNullified = data.extra_data.qingfengNullified or {}
    data.extra_data.qingfengNullified[tostring(data.to)] = (data.extra_data.qingfengNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qingfengNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.qingfengNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
      if p:getMark("qingfengMark") > 0 then
        room:removePlayerMark(p, "qingfengMark", num)
      end
    end
    data.qingfengNullified = nil
  end,
}
local qingfeng_prohibit = fk.CreateProhibitSkill{
  name = "#qingfeng_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("qingfengMark") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds(Player.Hand), id) end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("qingfengMark") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds(Player.Hand), id) end)
    end
  end,
}
qingFengSkill:addRelatedSkill(qingfeng_prohibit)
Fk:addSkill(qingFengSkill)
local qingFeng = fk.CreateWeapon{
  name = "&qingfeng_sword",
  suit = Card.Spade,
  number = 6,
  attack_range = 2,
  equip_skill = qingFengSkill,
}
extension:addCard(qingFeng)
Fk:loadTranslationTable{
  ["qingfeng_sword"] = "赤血青锋",
  [":qingfeng_sword"] = "装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：锁定技，你使用【杀】指定目标后，此【杀】无视目标角色的防具且"..
  "目标不能使用或打出手牌，直至此【杀】结算完毕。",
}

return extension
