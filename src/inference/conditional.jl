"""
只在Syllogistic Rules Asymmetric Asymmetric 22中用到
{<(&&, S2, S3) ==> P>, <(&&, S1, S3) ==> P>} |-   S2
"""
conditionalabd(cond1, cond2, s1, s2, nar) = false
function conditionalabd(cond1, cond2, s1::Implication, s2::Implication, nar)
    # ! cond1 和 cond2 之间必须有一个Conjunction
    !isa(cond1, Conjunction) && !isa(cond2, Conjunction) && return false
    term1 = reducecomps(cond1, cond2)
    term2 = reducecomps(cond2, cond1)
    if term1 !== nothing
        content1 = isnothing(term2) ? term1 : Implication(term1, term2)
        content2 = isnothing(term2) ? term2 : Implication(term2, term1)
        if nar.forward
            Threads.@spawn derivetask2(Forward(), content1, :inv_abd, nar)
            derivetask2(Forward(), content2 :abduction, nar)
        else
            Threads.@spawn derivetask2(BackwardWeak(), content1, nar)
            derivetask2(BackwardWeak(), content2, nar)
        end
    end

    # 到这里说明 term1 为 nothing
    if term2 !== nothing
        if nar.forward
            derivetask2(Forward(), term2, :abduction, nar)
        else
            derivetask2(BackwardWeak(), term2, nar)
        end
    else
        return false
    end
    return true
end

"""
COMPOUND - COMPOUND_CONDITION
{<(&&, S1, S2) <=> P>, (&&, S1, S2)} |- P
index : 公共词项在条件中的索引
side : 公共词项在premise2中的索引 1: subj, 2: pred, -1: Whole
"""
condana(premise1, premise2, index, side, nar) = false
function condana(conditional::Equivalence, statement, index, side, nar)
    iscondtask = findsubstitute(IVar, statement, nar.belief.term)
    if side == -1
        common = statement
        newcomp = nothing
    else
        @inbounds common = statement[side]
        @inbounds newcomp = statement[3 - side]
    end
    @inbounds oldcond = conditional[1]
    @assert oldcond isa Conjunction
    matched = unify!(DVar, oldcond[index], common, conditional, statement)
    if !matched && typeof(common) == typeof(oldcond) # typeof(common) <: Conjunction
        matched = unify!(DVar, oldcond[index], common[index], conditional, statement)
    end
    !matched && return
    if oldcond == common
        newcond = nothing
    else
        if isnothing(newcomp)
            term = reducecomps(oldcond, oldcond[index])
        else
            # TODO 需要deepcopy么?
            @inbounds oldcond[index] = newcomp
            term = oldcond
        end
        newcond = term
    end
    if isnothing(newcond)
        @inbounds content = conditional[2]
    else
        content = typeof(conditional)(newcond, conditional[2])
    end
    if nar.forward
        truth_func = iscondtask ? :comparision : :analogy
        derivetask2(Forward(), content, truth_func, nar)
    else
        derivetask2(BackwardWeak(), content, nar)
    end
end

"""
(&&, S1, S2) ==> P , <S1 ==> S3>
(&&, S1, S2) ==> P , <S3 ==> S1>
COMPOUND_CONDITION - COMPOUND_STATEMENT
我觉得正常应该是分这两种情况
"""
function conddedind(conditional::Implication, statement, index, side, nar)
    if side == -1
        common = statement
        newcomp = nothing
    else
        @inbounds common = statement[side]
        @inbounds newcomp = statement[3 - side]
    end
    iscondtask = findsubstitute(IVar, statement, nar.belief.term) # TODO 这是啥意思啊
    @inbounds oldcond = conditional[1]
    @assert oldcond isa Conjunction
    if oldcond == common
        newcond = nothing
    else
        if isnothing(newcomp)
            term = reducecomps(oldcond, oldcond[index])
        else
            # TODO 需要deepcopy么
            @inbounds oldcond[index] = newcomp
            term = oldcond
        end
        newcond = term
    end
    if isnothing(newcond)
        @inbounds content = conditional[2] 
    else
        content = typeof(conditional)(newcond, conditional[2])
    end
    isded = side != 1
    if nar.forward
        if isded
            derivetask2(Forward(), content, :deduction, nar)
        elseif iscondtask
            derivetask2(Forward(), content, :inv_ind, nar) 
        else
            derivetask2(Forward(), content, :induction, nar)
        end
    else
        derivetask2(BackwardWeak(), content, nar)
    end
end
