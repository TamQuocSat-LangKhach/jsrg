local piqi = fk.CreateSkill {
  name = "piqi"
}

Fk:loadTranslationTable{
  ['piqi&'] = '辟奇',
  ['#piqi&'] = '辟奇：你可以将【闪】当【无懈可击】使用',
  [':piqi&'] = '你可以将【闪】当【无懈可击】使用。',
}

piqi:addEffect('viewas', {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#piqi&",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "jink"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = piqi.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

return piqi
