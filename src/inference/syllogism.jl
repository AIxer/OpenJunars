"""
Asymmetric - Asymmetric:
Inheritance , Inheritance
Implication , Implication

Asymmetric - Symmetric:
Inheritance , Similarity
Similarity , Inheritance
Implication , Equivalence
Equivalence , Implication

Symmetric - Symmetric:
Similarity , Similarity
Equivalence , Equivalence

unify_detach()
"""
# fallback 
syllogisim(j1, j2, nar) = nothing

function syllogisim(j1::T, j2::T, nar::Nar) where T <: Union{Inheritance, Implication}
    figure = 10 * nar.tasklink.pos[1] + nar.termlink.pos[1]
    syllogisim_aa(j1, j2, figure, nar)
end

function syllogisim(j1::T, j2::T, nar) where T <: Union{Similarity, Equivalence}
    figure = 10 * nar.termlink.pos[1] + nar.tasklink.pos[1]
    syllogisim_ss(j1, j2, figure, nar)
end

"""
Analogy
<S ==> P> , <M <=> P> |- <S ==> P>
<S --> P> , <M <-> P> |- <S --> P>
"""
function syllogisim(j1::Inheritance, j2::Similarity, nar::Nar)
    figure = 10 * nar.tasklink.pos[1] + nar.termlink.pos[1]
    syllogisim_as(j1, j2, figure, nar)
end

function syllogisim(j1::Similarity, j2::Inheritance, nar::Nar)
    figure = 10 * nar.termlink.pos[1] + nar.tasklink.pos[1]
    syllogisim_as(j2, j1, figure, nar)
end

function syllogisim(j1::Implication, j2::Equivalence, nar::Nar)
    figure = 10 * nar.tasklink.pos[1] + nar.termlink.pos[1]
    syllogisim_as(j1, j2, figure, nar)
end

function syllogisim(j1::Equivalence, j2::Implication, nar::Nar)
    figure = 10 * nar.termlink.pos[1] + nar.tasklink.pos[1]
    syllogisim_as(j2, j1, figure, nar)
end

"""
<<M --> P> ==> <M --> S>> <M --> D>
<<M --> P> <=> <M --> S>> <M --> D>
j1: Implication 或者 Equivalence
j2: j1 的主语或者谓语
index: j2 在 j1 中的位置
"""
function syllogisim(j1::Inheritance, j2::Union{Implication, Equivalence}, nar)
    unify_detach(j2, j1, nar.termlink.pos[1], nar)
end

function syllogisim(j1::Union{Implication, Equivalence}, j2::Inheritance, nar::Nar)
    unify_detach(j1, j2, nar.tasklink.pos[1], nar)
end

"""
Asymmetric Asymmetric
"""
function syllogisim_aa(j1::T, j2::T, figure, nar) where T
    @match figure begin
        11 => begin # induction
            if unify!(IVar, j1[1], j2[1], j1, j2)
                j1 == j2 && return
                Threads.@spawn composecompound(j1, j2, 1, nar)
                abdindcom(T, j2[2], j1[2], nar)
            end
        end
        12 => begin # deduction
            if unify!(IVar, j1[1], j2[2], j1, j2)
                j1 == j2 && return
                if unify!(QVar, j2[1], j1[2], j1, j2)
                    matchreverse(j1, j2, nar)
                else
                    dedexe(T, j2[1], j1[2], nar)
                end
            end
        end
        21 => begin # exemplification
            if unify!(IVar, j1[2], j2[1], j1, j2)
                j1 == j2 && return
                if unify!(QVar, j1[1], j2[2], j1, j2)
                    matchreverse(j1, j2, nar)
                else
                    dedexe(T, j1[1], j2[2], nar)
                end
            end
        end
        22 => begin # abduction
            if unify!(IVar, j1[2], j2[2], j1, j2)
                j1 == j2 && return
                # 就这里一处用到了conditionalAbd 只是为了判断一下是不是Conditional
                if !(conditionalabd(j1[1], j2[1], j1, j2, nar))
                    Threads.@spawn composecompound(j1, j2, 2, nar)
                    abdindcom(T, j1[1], j2[1], nar)
                end
            end
        end
    end
end

function syllogisim_as(j1, j2, figure, nar)
    @match figure begin
        11 => begin # induction
            if unify!(IVar, j1[1], j2[1], j1, j2)
                t1 = j1[2]
                t2 = j2[2]
                if unify!(QVar, t1, t2, j1, j2)
                    matchsyllo_as(j1, j2, figure, nar)
                else
                    analogy(typeof(j1), t2, t1, nar)
                end
            end
        end
        12 => begin # deduction
            if unify!(IVar, j1[1], j2[2], j1, j2)
                t1 = j1[2]
                t2 = j2[1]
                if unify!(QVar, t1, t2, j1, j2)
                    matchsyllo_as(j1, j2, figure, nar)
                else
                    analogy(typeof(j1), t2, t1, nar)
                end
            end
        end
        21 => begin # exemplification
            if unify!(IVar, j1[2], j2[1], j1, j2)
                t1 = j1[1]
                t2 = j2[2]
                if unify!(QVar, t1, t2, j1, j2)
                    matchsyllo_as(j1, j2, figure, nar)
                else
                    analogy(typeof(j1), t1, t2, nar)
                end
            end
        end
        22 => begin # abduction
            if unify!(IVar, j1[2], j2[2], j1, j2)
                if unify!(QVar, j1[1], j2[1], j1, j2)
                    matchsyllo_as(j1, j2, figure, nar)
                else
                    analogy(typeof(j1), j1[1], j2[1], nar)
                end
            end
        end
    end
end

function syllogisim_ss(j1, j2, figure, nar)
    @match figure begin
        11 => begin # induction
            if unify!(IVar, j1[1], j2[1], j1, j2)
                resemblance(j1[2], j2[2], nar)
            end
        end
        12 => begin # deduction
            if unify!(IVar, j1[1], j2[2], j1, j2)
                resemblance(j1[2], j2[1], nar)
            end
        end
        21 => begin # exemplification
            if unify!(IVar, j1[2], j2[1], j1, j2)
                resemblance(j1[1], j2[2], nar)
            end
        end
        22 => begin # abduction
            if unify!(IVar, j1[2], j2[2], j1, j2)
                resemblance(j1[1], j2[1], nar)
            end
        end
    end
end

"""
<A --> B> , <B --> A> |- <A <-> B>
==> 也一样
"""
function matchreverse(j1::T, j2::T, nar) where T <: Union{Inheritance, Implication}
    if nar.forward
        term = bro(T)(j1[1], j1[2])
        derivetask2(Forward(), term, :intersection, nar)
    else
        truth = conversion(nar.belief.truth)
        convertjudgment(truth, nar)
    end
end

"""
<S --> P> , <P <-> S> |- <P --> S>
"""
function matchsyllo_as(asym, sym, figure, nar)
    if nar.forward
        # <S --> P> , <P <-> S> |- <P --> S>
        term = typeof(asym)(asym[2], asym[1])
        truth_func = nar.switched ? :reduceconj : :inv_reduceconj
        derivetask2(Forward(), term, truth_func, nar)
    else
        # {<S --> P>} |- <S <-> P> 
        # {<S <-> P>} |- <S --> P>
        if iscommutative(nar.tasksentence.term)
            truth = abduction(nar.belief.truth, 1.0)
        else
            truth = deduction(nar.belief.truth, 1.0)
        end
        convertjudgment(truth, nar)
    end
end

function convertjudgment(truth, nar)
    content = nar.tasksentence.term
    @inbounds subjT = nar.tasksentence.term[1]
    @inbounds predT = nar.tasksentence.term[2]
    @inbounds subjB = nar.belief.term[1]
    @inbounds predB = nar.belief.term[2]
    if has(QVar, subjT)
        other = predT == subjB ? predB : subjB
        content = typeof(content)(other, predT)
    end
    if has(QVar, predT)
        other = subjT == subjB ? predB : subjB
        content = typeof(content)(subjT, other)
    end
    # ! only Forward inference
    derivetask!(Forward, content, truth, nar)
end

raw"""
用于引入变量
index: j2 在 j1 中的位置
<<a-->b> ==> <c-->d>> , <c-->e>
<(--, <a-->b>) ==> <c-->d>> , <c-->d> or (--, <a-->b>) ...

<<$x --> key> ==> <{lock1} --> (/,open,$x,_)>>.
<{lock1} --> lock>.
...
"""
function unify_detach(main::Union{Equivalence, Implication}, sub, index, nar)
    maincomp = deepcopy(main[index])
    !isa(maincomp, Union{Inheritance, Negation}) && return
    if isconstant(maincomp)
        return syllogisim_detach(main, sub, index, nar)
    elseif unify!(IVar, maincomp, sub, main, sub)
        return syllogisim_detach(main, sub, index, nar)
    end
    @inbounds main_pred = main[2]
    !isa(main_pred, Statement) && return
    !(isa(nar.tasksentence, Sentence{Judgement})) && return
    if main isa Implication && main_pred[1] == sub[1]
        maincopy = deepcopy(main)
        subcopy = deepcopy(sub)
        Threads.@spawn introvarinner(maincopy, subcopy, maincopy[2], nar)
    end
    introvarsamesubjorpred(main, sub, maincomp, index, nar)
end

introvarsamesubjorpred(main, sub, comp, index, nar) = nothing
function introvarsamesubjorpred(main, sub::T, maincomp::T, index, nar) where T <: Union{Inheritance, Similarity}
    maincomp == sub && return
    var = Variable{DVar}("dvar1")
    @inbounds if maincomp[1] == sub[1] && !isa(maincomp[1], Variable)
        maincomp[1] = deepcopy(var)
        sub[1] = deepcopy(var)
    elseif maincomp[2] == sub[2] && !isa(maincomp[2], Variable)
        maincomp[2] = deepcopy(var)
        sub[2] = deepcopy(var)
    else
        return #! 保险
    end
    # maincomp == sub && return  # ? redundant?
    main[index] = Conjunction(maincomp, sub)
    derivetask2(CompoundForward(), main, :induction, nar)
end

"""
{<< M --> S> ==> < M --> P>>, < M --> S>} |- < M --> P>
{<< M --> S> ==> < M --> P>>, < M --> P>} |- < M --> S>
{<< M --> S> <=> < M --> P>>, < M --> S>} |- < M --> P>
{<< M --> S> <=> < M --> P>>, < M --> P>} |- < M --> S>
"""
syllogisim_detach(main, sub, side, nar) = nothing
function syllogisim_detach(main::Implication, sub, side, nar)
    @inbounds term = main[3 - side]
    invalid(term) && return
    if nar.forward
        truth_func = side == 1 ? :deduction : :inv_abd
        derivetask2(Forward(), term, truth_func, nar)
    else
        inferType = side == 1 ? BackwardWeak : Backward
        derivetask2(inferType(), term, nar)
    end
end

function syllogisim_detach(main::Equivalence, sub, side, nar)
    @inbounds term = main[3 - side]
    term isa Statement && invalid(term) && return
    if nar.forward
        derivetask2(Forward(), term, :inv_ana, nar)
    else
        derivetask2(Backward(), term, nar)
    end
end

raw"""
(&&, <#1 --> bird>, <#1 --> animal>) , <swan --> bird>
已经进行过unify了
"""
function elimidvar(compound, component, nar)
    content = reducecomps(compound, component)
    invalid(content) && return
    if nar.forward
        truth_func = nar.switched ? :inv_anonymous_ana : :anonymous_analogy
        derivetask2(CompoundForward(), content, truth_func, nar)
    else
        inferType = nar.switched ? BackwardWeak : Backward
        derivetask2(inferType(), content, nar)
    end
end

"""
{<M --> S>, <C ==> <M --> P>>} |- <(&&, <#x --> S>, C) ==> <#x --> P>>
{<M --> S>, (&&, C, <M --> P>)} |- (&&, C, <<#x --> S> ==> <#x --> P>>
j1: <C ==> <M --> P>>
j2: <M --> S>
j1_pred: <M --> P>
"""
function introvarinner(j1, j2::T, j1_pred::T, nar) where T <: AbstractStatement
    isjudgment(nar.tasksentence) || return
    j2 in j1 && return
    @inbounds if j1_pred[1] == j2[1] # unify_detach() 函数进来的话那一定为真
        commonterm1 = j2[1]
        commonterm2 = imagecommon(j1_pred[2], j2[2])
    elseif j1_pred[2] == j2[2]
        commonterm1 = j2[2]
        commonterm2 = imagecommon(j1_pred[1], j2[1])
    else
        return
    end

    substitute = Dict{String, Variable}()
    substitute[name(commonterm1)] = Variable{DVar}("DVAR2")
    content = Conjunction(j2, j1)
    applysubs!(content, substitute)
    Threads.@spawn derivetask2(Forward(), content, :intersection, nar)
    substitute[name(commonterm1)] = Variable{IVar}("IVAR1")
    if !isnothing(commonterm2)
        substitute[name(commonterm2)] = Variable{IVar}("IVAR2")
    end
    content = Implication(j2, j1)
    isnothing(content) && return
    applysubs!(content, substitute)
    truth_func = j2 == nar.tasksentence.term ? :inv_ind : :induction
    derivetask2(Forward(), content, truth_func, nar)
end

"""
{S --> M, M --> P}
"""
function dedexe(::Type{T}, P, S, nar::Nar) where T <: Union{Inheritance, Implication}
    invalidstatement(P, S) && return
    term1 = T(P, S)
    term2 = T(S, P)
    if nar.forward
        Threads.@spawn derivetask2(Forward(), term1, :deduction, nar)
        derivetask2(Forward(), term2, :exemplification, nar)
    else
        Threads.@spawn derivetask2(BackwardWeak(), term1, nar)
        derivetask2(BackwardWeak(), term2, nar)
    end
end


function abdindcom(::Type{T}, P, S, nar::Nar) where T
    (invalidstatement(P, S) || invalidpair(P, S)) && return
    BT = bro(T)
    term1 = T(P, S)
    term2 = T(S, P)
    term3 = BT(P, S)
    if nar.forward
        Threads.@spawn derivetask2(Forward(), term1, :abduction, nar)
        Threads.@spawn derivetask2(Forward(), term2, :inv_abd, nar)
        derivetask2(Forward(), term3 :comparision, nar)
    else
        Threads.@spawn derivetask2(Backward(), term1, nar)
        Threads.@spawn derivetask2(Backward(), term3, nar)
        derivetask2(BackwardWeak(), term2, nar)
    end
end

"""
{< S ==> M>, < M <=> P>} |- < S ==> P>
Asymmetric - Symmetric
"""
function Gene.analogy(::Type{T}, P, S, nar::Nar) where T <: Statement
    invalidstatement(P, S) && return
    term = T(P, S)
    if nar.forward
        derivetask2(Forward(), term, :analogy, nar)
    else
        # TODO
        if iscommutative(nar.tasksentence.term)
            derivetask!(BackwardWeak, term, nar.tasksentence.truth, nar)
        else
            derivetask!(Backward, term, nar.belief.truth, nar)
        end
    end
end

"""
{< S <=> M>, < M <=> P>} |- < S <=> P>
"""
function resemblance(term1, term2, nar)
    invalidstatement(term1, term2) && return
    term = typeof(nar.belief)(term1, term2)
    if nar.forward
        derivetask2(Forward(), term, :resemblance, nar)
    else
        derivetask2(Backward(), term, nar)
    end
end

"""
Only Inheritance
P --> M , S --> M
M --> P , M --> S
"""
function introvarout(P, S, side, nar::Nar)
    # TODO 需要这个判断么？
    # isjudgment(nar.tasksentence) || return
    ivar1 = Variable{IVar}("M1")
    ivar2 = Variable{IVar}("M2")
    subs = Dict()
    # comT = imagecommon(P, S)
    # if comT !== nothing
    #     subs[name(comT)] = ivar2
    #     applysubs!(P, subs)
    #     applysubs!(S, subs)
    # end
    s1 = side == 1 ? Inheritance(ivar1, P) : Inheritance(P, ivar1)
    s2 = side == 1 ? Inheritance(ivar1, S) : Inheritance(S, ivar1)
    # TODO 只需要 P in S ?
    term1 = P in S ? nothing : Implication(s1, s2)
    term2 = S in P ? nothing : Implication(s2, s1)
    term3 = Equivalence(s1, s2)
    Threads.@spawn derivetask2(CompoundForward(), term1, :induction, nar)
    Threads.@spawn derivetask2(CompoundForward(), term2, :inv_ind, nar)
    Threads.@spawn derivetask2(CompoundForward(), term3, :comparision, nar)

    dvar = Variable{DVar}("#1")
    d1 = side == 1 ? Inheritance(dvar, P) : Inheritance(P, dvar)
    d2 = side == 1 ? Inheritance(dvar, S) : Inheritance(S, dvar)
    term4 = Conjunction([d1, d2])
    renamevar!(term4, Dict())
    derivetask2(CompoundForward(), term4, :intersection, nar)
end