local skill = fk.CreateSkill {
  name = "demobilized_skill",
}

skill:addEffect("cardskill", {
  prompt = "#demobilized_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return #to_select:getCardIds("e") > 0
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local target = effect.to
    if target.dead then return end
    local equips = target:getCardIds("e")
    if #equips > 0 then
      room:moveCardTo(equips, Card.PlayerHand, target, fk.ReasonJustMove, skill.name, nil, true, target)
    end
  end,
})

return skill
