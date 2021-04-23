"""
(&&, A, B), A |- A
"""
function structrualcompound(compound::Union{Conjunction, Disjunction}, component, nar)
    component isa Statement && has(DVar, component) && return
    # ? 上面还是下面all这种呢？
    # all(comp -> has(DVar, comp), compound) && return
    isconstant(component) || return
    # ⊼ : not xor  \barwedge
    ⊼ = !⊻
    content = nar.switched ? compound : component
    if nar.forward
        if isjudgment(nar.tasksentence) ⊼ (!nar.switched ⊼ (compound isa Conjunction))
            derivetask1(Forward(), content, :deduction, nar, Analy())
        else
            truth = negation(nar.tasksentence.truth)
            truth = deduction(truth, RELIANCE)
            truth = negation(truth)
            derivetask!(Forward, content, truth, nar)
        end
    else
        derivetask1(CompoundBackward(), content, nar)
    end
end

structuraldecompose1(compound, statement, index, side, nar) = nothing

"""
<(S&T) --> P> , (S&T)  cpt.term = S
"""
function structuraldecompose1(compound::IntIntersection, statement, index, side, nar)
    @inbounds component = compound[index]
    side == 2 && return
    term = typeof(statement)(component, statement[2])
    derivetask1(CompoundForward(), term, :deduction, nar, Analy())
end

function structuraldecompose1(compound::ExtIntersection, statement, index, side, nar)
    side == 1 && return
    term = typeof(statement)(statement[1], compound[index])
    derivetask1(CompoundForward(), :deduction, term, nar, Analy())
end

function structuraldecompose1(compound::IntSet, statement, index, side, nar)
    side == 1 && return
    length(compound) < 2 && return
    term = typeof(statement)(statement[1], IntSet(compound[index]))
    derivetask1(CompoundForward(), term, :deduction, nar, Analy())
end

function structuraldecompose1(compound::ExtSet, statement, index, side, nar)
    side == 2 && return
    length(compound) < 2 && return
    term = typeof(statement)(ExtSet(compound[index]), statement[2])
    truth = deduction(nar.tasksentence.truth, RELIANCE)
    derivetask!(CompoundForward, term, truth, nar)
end

function structuraldecompose1(compound::IntDiff, statement, index, side, nar)
    side == 2 && return
    @inbounds component = compound[index]
    term = typeof(statement)(component, statement[2])
    truth = deduction(nar.tasksentence.truth, RELIANCE)
    if index == 1
        derivetask!(CompoundForward, term, truth, nar)
    else
        derivetask!(CompoundForward, term, negation(truth), nar)
    end
end

function structuraldecompose1(compound::ExtDiff, statement, index, side, nar)
    side == 1 && return
    @inbounds component = compound[index]
    term = typeof(statement)(statement[1], component)
    truth = deduction(nar.tasksentence.truth, RELIANCE)
    if index == 1
        derivetask!(CompoundForward, term, truth, nar)
    else
        derivetask!(CompoundForward, term, negation(truth), nar)
    end
end

structuraldecompose2(statement, index, nar) = nothing
function structuraldecompose2(statement::Union{Inheritance, Similarity}, index, nar) 
    structuraldecompose2(typeof(statement), statement[1], statement[2], index, nar)
end

"""
{<(S&T) --> (P&T)>, S@(S&T)} |- <S --> P>
"""
structuraldecompose2(::Type, subj, pred, index, nar) = nothing
structuraldecompose2(::Type{ST}, subj::T, pred::T, index, nar) where {ST, T <: Union{Product, NALSet}} = nothing
function structuraldecompose2(::Type{ST}, subj::T, pred::T, index, nar) where {ST <: Statement, T <: Compound}
    length(subj) != length(pred) && return

    # 这么取的话t1 t2 可能相同
    # BUG
    @inbounds t1 = subj[index]
    @inbounds t2 = pred[index]

    term = switchorder(subj, index) ? ST(t2, t1) : ST(t1, t2)
    if eltype(nar.tasksentence) <: Question
        derivetask1(CompoundBackward(), term, nar)
    else
        sentence = nar.task.sentence
        derivetask!(CompoundForward, term, sentence.truth, nar)
    end
end

"""
compose1 这个1代表只在一边进行组合替换
<S --> P> , (S&T) (S|T) (S-T) (S~T) --> P
"""
function structuralcompose1(compound::ExtIntersection, statement, index, side, nar)
    !nar.forward && return
    @inbounds pred = statement[2]
    cpdcopy = deepcopy(compound)
    @inbounds cpdcopy[index] == pred && return
    term = typeof(statement)(cpdcopy, pred)
    derivetask1(CompoundForward(), term, :deduction, nar, Analy())
end

function structuralcompose1(compound::IntIntersection, statement, index, side, nar)
    !nar.forward && return
    @inbounds subj = statement[1]
    cpdcopy = deepcopy(compound) # compose1 之后还可能有compose2
    @inbounds cpdcopy[index] == subj && return
    term = typeof(statement)(subj, cpdcopy)
    derivetask1(CompoundForward(), term, :deduction, nar, Analy())
end

function structuralcompose1(compound::ExtDiff, statement, index, side, nar)
    !nar.forward && return # TODO Need this?
    truth = deduction(nar.tasksentence.truth, RELIANCE)
    @inbounds component = compound[index]
    @inbounds subj = statement[1]
    @inbounds pred = statement[2]
    if component == subj && index == 1
        term = typeof(statement)(compound, pred)
        derivetask!(CompoundForward, term, truth, nar)
    elseif component == pred && index == 2
        term = typeof(statement)(subj, compound)
        truth = negation(truth)
        derivetask!(CompoundForward, term, truth, nar)
    end
end

function structuralcompose1(compound::IntDiff, statement, index, side, nar)
    !nar.forward && return
    truth = deduction(nar.tasksentence.truth, RELIANCE)
    @inbounds component = compound[index]
    @inbounds subj = statement[1]
    @inbounds pred = statement[2]
    if component == subj
        index == 1 && return
        term = typeof(statement)(compound, pred)
        truth = negation(truth)
        derivetask!(CompoundForward, term, truth, nar)
    elseif component == pred && index == 1
        term = typeof(statement)(subj, compound)
        derivetask!(CompoundForward, term, truth, nar)
    end
end

# fallback
structuralcompose1(compound, statement, index, side, nar) = nothing

"""
compose2 代表两边都要替换
<a --> b> , (&, a, c) |- <(&,a,c) --> (&,b,c)>
# ! 这里的compound不可能是 Conjunction 之类吧
"""
function structuralcompose2(compound::Compound, statement, index, side, nar)
    @inbounds statement[side] == compound && return
    # TODO 多余 和 pred in compound / subj in compound 检查重复了
    # @inbounds another = side == 1 ? statement[2] : statement[1]
    # another in compound && return  #  <S --> P> , (S&P)

    subj = @inbounds statement[1]
    pred = @inbounds statement[2]
    # 尽量不改变参数
    cpdcopy = deepcopy(compound)

    if side == 1 # <S --> P>, (S&T)
        # <(&,S,T) --> (&,P,T)>
        pred in compound && return # < S --> P> , (S & P)
        subj in compound || return # TODO 感觉这也是多余的, 因为这是必然的
        @inbounds cpdcopy[index] = pred
    else
        # <S --> P> , (P&T) |- <(S&T) --> (P&T)>
        subj in compound && return
        pred in compound || return
        @inbounds cpdcopy[index] = subj
    end

    # TODO 所以如何选择？
    # sp = side == 1 ? pred : subj
    # @inbounds sp[index] = another
    # 假如是compound是NALDifference, (S-T) 和 (T-S) 进行组合是有区别的
     
    if switchorder(compound, index)
        term = typeof(statement)(cpdcopy, compound)
    else
        term = typeof(statement)(compound, cpdcopy)
    end

    if nar.forward
        derivetask1(CompoundForward(), term, :deduction, nar, Analy())
    else
        derivetask1(CompoundBackwardWeak(), term, nar)
    end
end

############################ Negation 相关规则 ##############################
"""
{<(--, A) ==> B>, A@(--, A)} |- <(--, B) ==> (--, A)>
sentence 用于提取真值
contraposition只管把两边否定掉
"""
function Gene.contraposition(statement::Statement, sentence, nar)
    term = typeof(statement)(Negation(statement[1]), Negation(statement[2]))
    truth = sentence.truth
    if nar.forward
        BudgetStyle = term isa Implication ? compoundBackwardWeak : compoundBackward
        derivetask1(BudgetStyle(), term, nar)
    else
        truth = ifelse(term isa Implication, contraposition(truth), truth)
        derivetask!(CompoundForward(), term, truth, nar)
    end
end

"""
{(--, A) , A} |- (--, A)
实际上这里只是处理一下真值，因为该规则就一步，在调用该函数时已经处理了
"""
function transformneg(content, nar)
    # TODO content 或需要 deepcopy
    truth = nar.tasksentence.truth
    if nar.forward
        truth = negation(truth)
        derivetask!(CompoundForward, content, truth, nar)
    else
        derivetask!(CompoundBackward, content, truth, nar)
    end
end

# Compound非NALSet的情况不推理
transformset(statement, compound, side, nar) = nothing
"""
<S --> {P}> |- <S <-> {P}>
"""
function transformset(statement::Inheritance, compound::ExtSet, side, nar)
    side == 1 && return
    _transformset_inheritance(compound, statement, nar)
end

"""
<[P] --> S> |- <[P] <-> S>
"""
function transformset(statement::Inheritance, compound::IntSet, side, nar)
    side == 2 && return
    _transformset_inheritance(compound, statement, nar)
end

function _transformset_inheritance(compound, statement, nar)
    length(compound) > 1 && return 
    @inbounds term = Similarity(statement[1], statement[2])
    if nar.forward
        derivetask!(CompoundForward, term, nar.tasksentence.truth, nar)
    else
        derivetask1(CompoundBackward(), term, nar)
    end
end

"""
对于非Inheritance 且是单元素的情况
"""
function transformset(statement::Statement, compound::IntSet, side, nar)
    length(compound) > 1 && return
    term = side == 2 ? Inheritance(statement[2], statement[1]) : Inheritance(statement[1], statement[2])
    if nar.forward
        derivetask!(CompoundForward, term, nar.tasksentence.truth, nar)
    else
        derivetask1(CompoundBackward(), term, nar)
    end
end

function transformset(statement::Statement, compound::ExtSet, side, nar)
    length(compound) > 1 && return
    term = side == 1 ? Inheritance(statement[2], statement[1]) : Inheritance(statement[1], statement[2])
    if nar.forward
        derivetask!(CompoundForward, term, nar.tasksentence.truth, nar)
    else
        derivetask1(CompoundBackward(), term, nar)
    end
end

# 就行变换
_transformrela(rela::Inheritance, nar) = transform_rela(rela[1], rela[2], nar)
# 相同类型不变换
transform_rela(p1::ExtImage, p2::ExtImage, nar) = nothing
transform_rela(p1::IntImage, p2::IntImage, nar) = nothing
transform_rela(p1::Product, p2::Product, nar) = nothing
# 其它情况不用处理
transform_rela(t1, t2, nar) = nothing

"""
<(*, A, B) --> C>   |-  <A --> (/, C, _, B)>
                    |-  <B --> (/, C, A, _)>
"""
function transform_rela(prod::Product, rela::Term, nar)
    newforms = Vector{Inheritance}(undef, length(prod))
    for (idx, comp) in enumerate(prod)
        left = prod[1:idx-1]
        right = prod[idx+1:end]
        term = Inheritance(prod[idx], ExtImage(idx + 1, [rela; left; PlaceHolder(); right]))
        newforms[idx] = term
    end
    return newforms
end

"""
<C --> (*, A, B)>   |-  <(\\, C, _, B) --> A>
                    |-  <(\\, C, A, _) --> B>
"""
function transform_rela(rela::Term, prod::Product, nar)
    newforms = Vector{Inheritance}(undef, length(prod))
    for (idx, comp) in enumerate(prod)
        left = prod[1:idx-1]
        right = prod[idx+1:end]
        term = Inheritance(IntImage(idx + 1, [rela; left; PlaceHolder(); right]), prod[idx])
        newforms[idx] = term
    end
    return newforms
end


"""
<S --> (/, P, _, M)>    |-  <(*, S, M) --> P>
<S --> (/, P, _, M)>    |-  <M --> (/, P, S, _)>
<S --> (/, P, A, _, M)>    |-  <M --> (/, P, A, S, _)>
"""
function transform_rela(term::Term, image::ExtImage, nar)
    pidx = image.relaidx
    @inbounds left = image[2:pidx-1]
    @inbounds right = image[pidx+1:end]
    rela = Inheritance(Product([left; term; right]), image[1])
    derivetask!(CompoundForward, rela, nar.tasksentence.truth, nar)
    _transformrela(rela, nar)
end

function transform_rela(image::IntImage, term::Term, nar)
    pidx = image.relaidx
    @inbounds left = image[2:pidx-1]
    @inbounds right = image[pidx+1:end]
    rela = Inheritance(image[1], Product([left; term; right]))
    derivetask!(CompoundForward, rela, nar.tasksentence.truth, nar)
    _transformrela(rela, nar)
end

"""
<S --> (/, P, _, M)>    |-  <(*, S, M) --> P>
<S --> (/, P, _, M)>    |-  <M --> (/, P, S, _)>
"""
# 入口
transformrela(rela, nar) = nothing
function transformrela(rela::Inheritance, nar::Nar)
    newforms = _transformrela(rela, nar)
    isnothing(newforms) && return
    for newform in newforms
        newform == rela && continue
        derivetask!(CompoundForward, newform, nar.tasksentence.truth, nar)
    end
end

"""
#  <<(*, term, #) --> #> ==> #>
#  <(&&, <(*, term, #) --> #>, #) ==> #>
"""
function transformrela(rela::Implication, nar)
    @inbounds transformrela2(rela, rela[1], rela[2], nar)
end

#  <<(*, term, #) --> #> ==> #>
function transformrela2(rela, subj::Inheritance, pred, nar)
    newforms = _transformrela(subj, nar)
    isnothing(newforms) && return
    for newform in newforms
        newform == subj && continue
        relacopy = deepcopy(rela)
        @inbounds relacopy[1] = newform
        derivetask!(CompoundForward, relacopy, nar.tasksentence.truth, nar)
    end
end

#  <(&&, <(*, term, #) --> #>, #) ==> #>
function transformrela2(rela, subj::Conjunction, pred, nar)
    index = @inbounds nar.tasklink.pos[2]
    relainh = @inbounds subj[index]
    newforms = _transformrela(relainh, nar)
    isnothing(newforms) && return
    for newform in newforms
        newform == relainh && continue
        relacopy = deepcopy(rela)
        @inbounds relacopy[1][index] = newform
        derivetask!(CompoundForward, relacopy, nar.tasksentence.truth, nar)
    end
end
