local qiongtu = fk.CreateSkill {
  name = "qiongtu"
}

Fk:loadTranslationTable{
  ['qiongtu'] = '穷途',
  ['#qiongtu'] = '穷途：将一张非基本牌置于武将牌上，视为使用【无懈可击】',
  [':qiongtu'] = '群势力技，每回合限一次，你可以将一张非基本牌置于武将牌上视为使用一张【无懈可击】，若该【无懈可击】生效，你摸一张牌，否则你变更势力至魏并获得武将牌上的所有牌。',
}

qiongtu:addEffect('viewas', {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#qiongtu",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = qiongtu.name
    event:setCostData(skill, cards)
    return card
  end,
  before_use = function(self, player, use)
    player:addToPile(qiongtu.name, event:getCostData(skill), true, qiongtu.name)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(qiongtu.name, Player.HistoryTurn) == 0 and not player:isNude()
  end,
})

qiongtu:addEffect({fk.CardEffectCancelledOut, fk.CardUseFinished}, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "qiongtu")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffectCancelledOut then
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        use.qiongtu = true
      end
    else
      if data.qiongtu then
        room:changeKingdom(player, "wei", true)
        if #player:getPile("qiongtu") > 0 then
          room:obtainCard(player, player:getPile("qiongtu"), true, fk.ReasonJustMove)
        end
      else
        player:drawCards(1, qiongtu.name)
      end
    end
  end,
})

return qiongtu
