--[[
Copyright 2021 Dannyj1

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ModUtil.LoadOnce( function()
    for biome, enemySet in pairs(EnemySets) do
        if not isBiomeBlacklisted(biome) then
            for i, enemy in ipairs(enemySet) do
                if string.match(string.lower(biome), "miniboss") then
                    table.insert(HadesRando.data.minibosses, enemy)
                else
                    table.insert(HadesRando.data.enemies, enemy)
                end
            end
        end
    end

    assert(#HadesRando.data.enemies > 10)
    assert(#HadesRando.data.minibosses > 5)
end)
