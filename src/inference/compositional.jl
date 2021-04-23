"""
```
其实 ⋂(P, S) 可能为空,但是我挺喜欢这样的简洁的代码,因此这个工作我放到了后面
首先在词项结构体上,如果成分不能构成一个有效的词项,那么返回nothing

j1: Task term
j2: Belief term
side: 公共词项的索引位置, 值为 1 或 2
**只有 figure 值为 11 或 22 的时候才能组合**

{< S ==> M>, <P ==> M>} |- 
{<(S|P) ==> M>, <(S&P) ==> M>, <(S-P) ==> M>, <(P-S) ==> M>}
```
"""
function composecompound(j1::T, j2::T, side, nar::Nar) where T <: Union{Inheritance, Implication}
    !isjudgment(nar.tasksentence) && return
    @inbounds M = j1[side]
    @inbounds P = j1[3 - side]
    @inbounds S = j2[3 - side]

    # TODO decompose?
    if containall(P, S)  # P isa AbstractCompound ?
        return decomposecompound(T, P, S, M, side, nar)
    elseif containall(S, P)
        nar.switched = true
        return decomposecompound(T, S, P, M, side, nar)
    end

    compose(T, M, P, S, side, nar)
end

function compose(::Type{Inheritance}, M, P, S, side, nar)
    if isnegative(nar.belief.truth)
        if !isnegative(nar.tasksentence.truth)
            termdiff = side == 1 ? Inheritance(M, ExtDiff(S, P)) : Inheritance(IntDiff(P, S), M)
            derivetask2(CompoundForward(), termdiff, :difference, nar)
        end
    elseif isnegative(nar.tasksentence.truth)
        termdiff = side == 1 ? Inheritance(M, ExtDiff(P, S)) : Inheritance(IntDiff(S, P), M)
        derivetask2(CompoundForward(), termdiff, :inv_difference, nar)
    end

    term1 = side == 1 ? Inheritance(M, ⋂(P, S)) : Inheritance(⋃(P, S), M)
    term2 = side == 1 ? Inheritance(M, ⋃(P, S)) : Inheritance(⋂(P, S), M)
    if invalid(term1)
        term1 = nothing
    end
    if invalid(term2)
        term2 = nothing
    end
    Threads.@spawn derivetask2(CompoundForward(), term1, :intersection, nar)
    derivetask2(CompoundForward(), term2, :union, nar)
    introvarout(P, S, side, nar)
end

function compose(::Type{Implication}, M, T₁, T₂, side, nar)
    if side == 1
        term1 = Implication(M, Disjunction([T₁, T₂])) 
        term2 = Implication(M, Conjunction([T₁, T₂]))
    else
        term1 = Implication(Conjunction([T₁, T₂]), M) 
        term2 = Implication(Disjunction([T₁, T₂]), M) 
    end
    Threads.@spawn derivetask2(CompoundForward(), term1, :union, nar)
    derivetask2(CompoundForward(), term2, :intersection, nar)
end

"""
有两种情况调用该函数:
1. COMPOUND, SELF 或者 SELF, COMPOUND
{(||, S, P), P} |- S
{(&&, S, P), P} |- S
2. COMPOUND_CONDITION, COMPOUND_STATEMENT 或者 颠倒顺序
(&&, <天鹅-->?x>, <麻雀-->动物>)? , <天鹅-->鸟>.
这种情况无法被localmatch中的unify消除变量,但是到这里已经被unify好了

compound : Implication中需要被析构的复合词项
component : 需要被移除的词项
"""
function decomposestatement(compound::Union{Conjunction, Disjunction}, component, nar)
    content = reducecomps(compound, component)
    isnothing(content) && return # 其实这应该不会发生
    if nar.forward
        if nar.switched
            truth_func = compound isa Conjunction ? :inv_reduceconj : inv_reducedisj
        else
            truth_func = compound isa Conjunction ? :reduceconj : :reducedisj
        end
        derivetask2(CompoundForward(), content, truth_func, nar)
    else
        Threads.@spawn derivetask2(CompoundBackward(), content, nar)
        # ! 特别处理一下带 询问变量 的连接词
        if has(QVar, nar.tasksentence.term)
            # ! 如果有的话,那么一定在component里
            contentcpt = peek(nar.mem, content)
            isnothing(contentcpt) && return # 当前没找到
            cntbelief = choosebelief(contentcpt.beliefs, nar.tasksentence)
            isnothing(cntbelief) && return
            token = Token(hash(content), deepcopy(bgt(nar.task)))
            task = NaTask(token, cntbelief, nothing, nothing, nothing)
            nar.task = task
            nar.tasksentence = task.sentence
            answer = Conjunction(component, content)
            truth = intersection(cntbelief.truth, nar.belief.truth)
            derivetask!(CompoundForward, answer, truht, nar)
        end
    end
end

"""
<(S|P) ==> M> , <P ==> M> |- <S ==> M>
<M ==> (S|P)> , <M ==> P> |- <M ==> P>
"""
decomposecompound(::Type{T}, P::Union{Statement, Image}, S, M, side, nar::Nar) where T = nothing
function decomposecompound(::Type{Inheritance}, P::Compound, S, M, side, nar::Nar)
    others = reducecomps(P, S)
    isnothing(others) && return
    term = side == 1 ? Inheritance(M, others) : Inheritance(others, M)
    truth_func = _decompose_truthfunc(P, S, nar)
    derivetask2(CompoundForward(), term, truth_func, nar)
end

function decomposecompound(::Type{Implication}, P::Union{Conjunction, Disjunction}, S, M, side, nar::Nar)
    others = reducecomps(P, S)
    isnothing(others) && return
    term = side == 1 ? Implication(M, others) : Implication(others, M)
    truth_func = P isa Conjunction ? :reduceconj : :reducedisj
    derivetask2(CompoundForward(), term, truth_func, nar)
end

_decompose_truthfunc(P::Union{ExtIntersection, IntSet}, S, nar) = nar.switched ? :inv_reduceconj : :reduceconj
_decompose_truthfunc(P::Union{IntIntersection, ExtSet}, S, nar) = nar.switched ? :inv_reducedisj : :reducedisj
function _decompose_truthfunc(P::IntDiff, S, nar)
    if P[2] == S
        return nar.switched ? :reducedisj : :inv_reducedisj
    else
        return nar.switched ? :inv_reduceconj_neg : :reduceconj_neg
    end
end
function _decompose_truthfunc(P::ExtDiff, S, nar)
    if P[1] == S
        return nar.switched ? :reducedisj : :inv_reducedisj
    else
        return nar.switched ? :inv_reduceconj_neg : :reduceconj_neg
    end
end