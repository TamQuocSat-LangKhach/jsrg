local jiemeng = fk.CreateSkill {
  name = "jiemeng$"
}

Fk:loadTranslationTable{ }

jiemeng:addEffect('distance', {
  correct_func = function(self, from, to)
    if table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(jiemeng.name) end) and from.kingdom == "qun" then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "qun" then
          n = n + 1
        end
      end
      return -n
    end
    return 0
  end,
})

return jiemeng
