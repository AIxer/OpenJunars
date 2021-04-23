abstract type CVar <: AbstractVariable end
name(v::Variable{CVar}) = "%$(v.literal)"

const NonVarTerm= Union{Word, PlaceHolder, AbstractStatement}
const CommutativeTerm = Union{TermSet, Similarity, Equivalence} # 仅在NAL1-6中适用

"""
```
<\$sth ==> <a --> b>>. %1.0;0.0%
<<\$x --> bird> ==> <\$x --> animal>>.
                    <tiger --> animal>.
        \$x ==> tiger
map:
    Dict{String, Term}
```
"""
function unify!(::Type{T}, t1::Term, t2::Term, p1::Term, p2::Term) where T <: AbstractVariable # TODO ? Union{IVar, DVar, QVar} ?
    map1 = Dict{String, Term}()
    map2 = Dict{String, Term}()
    hasubs = findsubstitute(T, t1, t2, map1, map2)
    if hasubs
        if length(map1) != 0
            applysubs!(p1, map1)
            renamevar!(p1, Dict())
        end
        if length(map2) != 0
            applysubs!(p2, map2)
            renamevar!(p2, Dict())
        end
    end
    return hasubs
end

function unify!(::Type{T}, t1::Term, t2::Term) where T <: AbstractVariable
    unify!(T, t1, t2, t1, t2)    
end

raw"""
递归寻找可替换子项,不改变原词项内容
$1 -- Term
Term -- $1
$1 -- $2
"""
findsubstitute(::Type{T}, t1::Term, t2::Term) where T <: AbstractVariable = findsubstitute(T, t1, t2, Dict{String, Term}(), Dict{String, Term}())
findsubstitute(::Type{T}, t1::Term, t2::Term, map1, map2) where T <: AbstractVariable = false
findsubstitute(::Type{T}, t1::Atom, t2::Atom, map1, map2) where T <: AbstractVariable = t1 == t2

raw"""
unification
$x $y
"""
function findsubstitute(::Type{T}, t1::Variable{T}, t2::Variable{T}, map1, map2) where T <: AbstractVariable
    cvar = Variable{CVar}(name(t1) * name(t2) * "%") # 需要中转一下
    map1[name(t1)] = cvar
    map2[name(t2)] = cvar 
    return true
end

"""
<>
"""
function findsubstitute(::Type{T}, t1::Variable{T}, t2::NonVarTerm, map1, map2) where T <: AbstractVariable
    sub1 = get(map1, name(t1), nothing)
    if isnothing(sub1)     # not mapped yet
        map1[name(t1)] = t2  # 变量消除
        if eltype(t1) <: CVar # Common变量,说明map2里也有
            map2[name(t1)] = t2 # 同样消除
        end
        return true
    end
    findsubstitute(T, sub1, t2, map1, map2)
end

function findsubstitute(::Type{T}, t1::NonVarTerm, t2::Variable{T}, map1, map2) where T <: AbstractVariable
    sub2 = get(map2, name(t2), nothing)    
    if isnothing(sub2)
        map2[name(t2)] = t1
        if eltype(t2) <: CVar
            map1[name(t2)] = t1
        end
        return true
    end
    findsubstitute(T, t1, sub2, map1, map2)
end

raw"""
(&, $1, b) --> (&, a, b)
(/, $1, _, b) --> (/, a, _, b)
<天鹅 --> 鸟>
<$1 --> 鸟>
"""
function findsubstitute(::Type{T}, t1::T1, t2::T1, map1, map2) where {T <: AbstractVariable, T1 <: AbstractCompound}
    length(t1) != length(t2) && return false
    if T1 <: Image
        t1.relaidx != t2.relaidx && return false
    end

    # TODO 使用 iscommutative(t1) for NAL-7 ？
    if T1 <: CommutativeTerm
        t1 = shuffle(t1) # 打乱顺序
    end

    for (comp1, comp2) in zip(t1, t2)
        findsubstitute(T, comp1, comp2, map1, map2) || return false
    end
    return true
end

function applysubs!(t::AbstractCompound, map)
    for (pos, comp) in enumerate(t)
        sub = getsub(comp, map)
        if !isnothing(sub)
            if eltype(sub) <: CVar
                @inbounds if sub.literal[1] == '$'
                    sub = Variable{IVar}(sub.literal)
                elseif sub.literal[1] == '#'
                    sub = Variable{DVar}(sub.literal)
                else
                    sub = Variable{QVar}(sub.literal)
                end
            end
            @inbounds t[pos] = deepcopy(sub) # ! 必须deepcopy !!! 
        elseif comp isa AbstractCompound
            applysubs!(comp, map)
        end
    end
end

"""
找出最深层的可替换子项
"""
function getsub(t::Term, map)
    sub = get(map, name(t), nothing)
    isnothing(sub) && return
    while haskey(map, name(sub))
        sub = map[name(sub)]
    end
    return sub
end
