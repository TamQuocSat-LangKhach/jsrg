local chengxian = fk.CreateSkill {
  name = "chengxian"
}

Fk:loadTranslationTable{
  ['chengxian'] = '称贤',
  ['#chengxian-active'] = '称贤：将一张手牌当普通锦囊牌使用（两者必须合法目标数相同）',
  [':chengxian'] = '出牌阶段限两次，你可以将一张手牌当任意普通锦囊牌使用（每回合每种牌名各限一次，且以此法转化后的牌须与转化前的牌的合法目标角色数相等）。',
  ['$chengxian1'] = '所愿广求淑媛，以丰继嗣。',
  ['$chengxian2'] = '贤妻夫祸少，夫宽妻多福。',
}

chengxian:addEffect('viewas', {
  prompt = "#chengxian-active",
  interaction = function()
    local mark = Self:getTableMark("chengxian-turn")
    local all_names = U.getAllCardNames("t")
    local handcards = Self:getCardIds(Player.Hand)
    local names = table.filter(all_names, function(name)
      return not table.contains(mark, Fk:cloneCard(name).trueName) and table.find(handcards, function (id)
        local to_use = Fk:cloneCard(name)
        to_use:addSubcard(id)
        to_use.skillName = chengxian.name
        local x = getTargetsNum(Self, to_use)
        return x > 0 and x == getTargetsNum(Self, Fk:getCardById(id))
      end)
    end)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  times = function(self)
    if Self.phase == Player.Play then
      return 2 + Self:getMark("chengxian_extratimes-phase") - Self:usedSkillTimes(chengxian.name, Player.HistoryPhase)
    end
    return -1
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(chengxian.name, Player.HistoryPhase) < 2 + player:getMark("chengxian_extratimes-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == nil or #selected > 0 or Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use:addSubcard(to_select)
    to_use.skillName = chengxian.name
    return getTargetsNum(player, to_use) == getTargetsNum(player, Fk:getCardById(to_select))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = chengxian.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "chengxian-turn", use.card.trueName)
  end,
})

return chengxian
