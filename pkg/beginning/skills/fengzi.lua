local fengzi = fk.CreateSkill {
  name = "fengzi"
}

Fk:loadTranslationTable{
  ['fengzi'] = '丰姿',
  ['#fengzi-invoke'] = '丰姿：你可以弃置一张%arg，令%arg2额外结算一次',
  [':fengzi'] = '每阶段限一次，当你于出牌阶段内使用基本牌或普通锦囊牌时，你可以弃置一张类型相同的手牌令此牌额外结算一次。',
  ['$fengzi1'] = '丰姿秀丽，礼法不失。',
  ['$fengzi2'] = '倩影姿态，悄然入心。',
}

fengzi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data.tos and
      player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local type = data.card:getTypeString()
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fengzi.name,
      cancelable = true,
      pattern = ".|.|.|.|.|" .. type,
      prompt = "#fengzi-invoke:::" .. type .. ":" .. data.card:toLogString(),
      skip = true
    })
    if #card > 0 then
      event:setCostData(skill, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(skill).cards, skill.name, player, player)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return fengzi
