local xuanfeng = fk.CreateSkill {
  name = "js__xuanfeng"
}

Fk:loadTranslationTable{
  ['js__xuanfeng'] = '选锋',
  ['#js__xuanfeng-viewas'] = '选锋：你可将一张【影】当无距离次数限制的刺【杀】使用',
  [':js__xuanfeng'] = '蜀势力技，你可以将一张【影】当无距离次数限制的刺【杀】使用。',
}

xuanfeng:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "stab__slash",
  prompt = "#js__xuanfeng-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).name == "shade"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("stab__slash")
    card:addSubcard(cards[1])
    card.skillName = skill.name
    return card
  end,
})

xuanfeng:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.name == "stab__slash" and table.contains(card.skillNames, "js__xuanfeng")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card.name == "stab__slash" and table.contains(card.skillNames, "js__xuanfeng")
  end,
})

return xuanfeng
