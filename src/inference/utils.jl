function Base.contains(t1::AbstractCompound, t2::AbstractCompound)
    for comp ∈ t2
        comp ∈ t1 || return false
    end
    return true
end

# TODO Variable?
Base.contains(t1::AbstractCompound, t2::Atom) = t2 ∈ t1
Base.contains(t1::Atom, t2::Term) = false

"""
Wonder 为什么一定要是这种？
(/, R, _, a)
(/, R, a, _)
返回不是 关系 的那个
"""
function othercomp(t::Image)
    length(t) != 3 && return
    @inbounds t[2] isa PlaceHolder ? t[3] : t[2]
end

"""
我也不清楚这个干嘛的,如函数名吧
"""
imagecommon(P, S) = nothing
function imagecommon(P::T, S::T) where T <: Image
    comT = othercomp(P)
    if comT === nothing || comT ∉ S
        comT = othercomp(S)
        if comT === nothing || comT ∉ P
            comT = nothing
        end
    end
    return comT
end


"""
reduce compound
"""
function reducecomps(compound::AbstractCompound, comp::Term)
    # TODO setdiff(compound, [comp]) ?
    others = filter(x -> x != comp, compound.comps)
    length(others) == 0 && return nothing
    length(others) == 1 && @inbounds return others[1]
    return typeof(compound)(others)
end

function reducecomps(compound::T, comp::T) where T <: AbstractCompound
    others = filter(x -> x ∉ comp, compound.comps)
    length(others) == 0 && return nothing
    length(others) == 1 && @inbounds return others[1]
    return typeof(compound)(others)
end

reducecomps(compound, comp) = nothing

function containall(t1::T, t2::T) where T <: AbstractCompound
    for t in t2
        t ∉ t1 && return false
    end
    return true
end
containall(t1::Term, t2::Term) = t2 ∈ t1

# BUG # ! 多余的,Control模块中有相同函数,现在是偷个懒...
function choosebelief(beliefs, sentence)
    isnothing(beliefs) && return
    for belief in beliefs
        overlapped(belief.stamp, sentence.stamp) && continue
        return belief
    end
end