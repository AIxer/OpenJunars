"""
变量重命名 renamevar! 返回true或者false都无所谓
"""
renamevar!(term) = renamevar!(term, Dict())
renamevar!(t::Atom, map) = false
renamevar!(t::PlaceHolder, map) = false
renamevar!(t::Nothing, map) = false

function renamevar!(t::Variable, map)
    subs = get(map, name(t), nothing)
    if subs === nothing
        literal = string(length(map) + 1) 
        map[name(t)] = literal
        t.literal = literal
        return false
    end
    t.literal = deepcopy(subs) # TODO deepcopy?
    return true
end

function renamevar!(t::AbstractCompound, map)
    for comp in t
        renamevar!(comp, map)
    end
    return true
end

renamevar!(t::Negation, map) = renamevar!(t.ϕ, map)
