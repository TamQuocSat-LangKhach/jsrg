local cuifeng = fk.CreateSkill {
  name = "cuifeng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["cuifeng"] = "摧锋",
  [":cuifeng"] = "限定技，出牌阶段，你可以视为使用一张唯一目标的伤害类牌（无距离限制），若此牌未造成伤害或造成的伤害数大于1，此回合结束时重置〖摧锋〗。",

  ["#cuifeng"] = "摧锋：视为使用一种伤害牌！若没造成伤害或造成伤害大于1则回合结束时重置！",
}

local U = require "packages/utility/utility"

cuifeng:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#cuifeng",
  interaction = function(self, player)
    if player:getMark(cuifeng.name) == 0 then
      local names = table.filter(Fk:getAllCardNames("t"), function (name)
        local card = Fk:cloneCard(name)
        return card.is_damage_card and card.skill.target_num == 1
      end)
      player:setMark(cuifeng.name, names)
    end
    local all_names = player:getMark(cuifeng.name)
    local names = player:getViewAsCardNames(cuifeng.name, all_names, nil, nil, {bypass_distances = true})
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = cuifeng.name
    return card
  end,
  after_use = function (self, player, use)
    if player.dead then return end
    local yes = use.damageDealt == nil
    if not yes then
      local n = 0
      for _, p in ipairs(player.room.players) do
        if use.damageDealt[p] then
          n = n + use.damageDealt[p]
        end
      end
      yes = n > 1
    end
    if yes then
      player.room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        player:setSkillUseHistory(cuifeng.name, 0, Player.HistoryGame)
      end)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(cuifeng.name, Player.HistoryGame) == 0
  end,
})

cuifeng:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, cuifeng.name)
  end,
})

return cuifeng
