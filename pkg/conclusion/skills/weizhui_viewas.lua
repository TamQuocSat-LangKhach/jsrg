local weizhui_viewas = fk.CreateSkill{
  name = "weizhui_viewas",
}

Fk:loadTranslationTable{
  ["weizhui_viewas"] = "危坠",
}

weizhui_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("dismantlement")
    c.skillName = "weizhui"
    c:addSubcard(cards[1])
    return c
  end,
})

return weizhui_viewas
