local yansha = fk.CreateSkill {
  name = "yansha"
}

Fk:loadTranslationTable{
  ['yanshaViewas'] = '宴杀',
}

yansha:addEffect('viewas', {
  pattern = "slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = yansha.name .. "Slash"
    return card
  end,
})

return yansha
