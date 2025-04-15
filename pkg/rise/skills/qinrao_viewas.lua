local qinrao_viewas = fk.CreateSkill {
  name = "qinrao_viewas"
}

Fk:loadTranslationTable{
  ["qinrao_viewas"] = "侵扰",
}

qinrao_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card.skillName = "qinrao"
    card:addSubcard(cards[1])
    return card
  end,
})

return qinrao_viewas
