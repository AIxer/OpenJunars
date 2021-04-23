"""
    dispatch(taskterm, bterm, nar)
规则分发函数
# Arguments
- `taskterm::AbstractStatement` 任务所携带的词项
- `bterm::Term` TermLink 所链接的概念的词项,可能没有信念
- `nar::Nar` 推理机
"""
dispatch(taskterm::Conjunction, bterm::Word, nar::Nar) = nothing
function dispatch(taskterm::AbstractStatement, bterm::Term, nar::Nar)
    tlink = nar.tasklink
    blink = nar.termlink
    tindex = tlink.pos[1]
    bindex = blink.pos[1]
    fireterm = nar.cpt.term
    1 + 1
    @debug "($(tlink.ltype) - $(blink.ltype))" taskterm fireterm bterm

    @match (tlink.ltype, blink.ltype) begin
        (SELF, COMPONENT) => compoundself(taskterm, bterm, nar)
        (SELF, COMPOUND) => begin
            nar.switched = true
            compoundself(bterm, taskterm, nar)
        end
        (SELF, COMPONENT_STATEMENT) => begin
            isnothing(nar.belief) && return
            syllogisim_detach(taskterm, bterm, bindex, nar)
        end
        (SELF, COMPOUND_STATEMENT) => begin
            isnothing(nar.belief) && return
            syllogisim_detach(bterm, taskterm, bindex, nar)
        end
        (SELF, COMPONENT_CONDITION) => begin
            isnothing(nar.belief) && return
            bindex = blink.pos[2]
            conddedind(taskterm, bterm, bindex, tindex, nar)
        end
        (SELF, COMPOUND_CONDITION) => begin
            isnothing(nar.belief) && return
            bindex = blink.pos[2]
            conddedind(bterm, taskterm, bindex, tindex, nar)
        end

        (COMPOUND, COMPOUND) => compoundcompound(taskterm, bterm, nar)
        (COMPOUND, COMPOUND_STATEMENT) => compoundstatement(taskterm, bterm, tindex, bindex, nar)
        (COMPOUND, COMPONENT_STATEMENT) => begin
            firecpt = nar.cpt
            isnothing(firecpt.beliefs) && return
            nar.cpt = nar.beliefcpt
            nar.beliefcpt = firecpt
            nar.belief = first(firecpt.beliefs)
            compoundstatement(taskterm, fireterm, tindex, bindex, nar)
        end
        (COMPOUND, COMPOUND_CONDITION) => begin
            isnothing(nar.belief) && return
            if bterm isa Implication
                if unify!(IVar, bterm[1], taskterm, bterm, taskterm)
                    unify_detach(bterm, taskterm, bterm, taskterm)
                else
                    #! -1 源自 TaskLink SELF
                    conddedind(bterm, taskterm, bindex, -1, nar)
                end
            end
            condana(bterm, taskterm, bindex, -1, nar)
        end

        (COMPOUND_STATEMENT, COMPONENT) => componentstatement(fireterm, taskterm, bindex, tindex, nar)
        (COMPOUND_STATEMENT, COMPOUND) => componentstatement(bterm, taskterm, bindex, tindex, nar)
        (COMPOUND_STATEMENT, COMPOUND_STATEMENT) => begin
            isnothing(nar.belief) && return
            syllogisim(taskterm, bterm, nar)
        end
        (COMPOUND_STATEMENT, COMPOUND_CONDITION) => begin
            isnothing(nar.belief) && return
            bindex = blink.pos[2]
            unify_conddedind(bterm, taskterm, bindex, tindex, nar)
        end

        (COMPOUND_CONDITION, COMPOUND) => begin
            isnothing(nar.belief) && return
            unify_detach(taskterm, bterm, tindex, nar)
        end
        (COMPOUND_CONDITION, COMPOUND_STATEMENT) => begin
            isnothing(nar.belief) && return
            isa(taskterm, Implication) || return # TODO 需要这个判断么？
            subj = deepcopy(taskterm[1]) # TODO 需要deepcopy?
            if subj isa Negation
                if eltype(nar.tasksentence) <: Judgement
                    # BUG # ! 未测试区域 
                    componentstatement(subj, taskterm, bindex, tindex, nar)
                else
                    componentstatement(subj, bterm, tindex, bindex, nar)
                end
            else
                unify_conddedind(taskterm, bterm, tlink.pos[2], bindex, nar)
            end
        end
        _ => nothing
    end
end

"""
(&&, <天鹅-->鸟>, <鸟-->动物>) , <天鹅-->鸟>
(--, <天鹅-->鸟>) , <天鹅-->鸟>
"""
compoundself(compound, component, nar) = nothing
function compoundself(compound::Union{Conjunction, Disjunction}, component, nar)
    if !isnothing(nar.belief)
        decomposestatement(compound, component, nar)
    else
        # component in compound # ! 这是一定的... 不需要再判断
        structrualcompound(compound, component, nar)
    end
end

"""
(--, A) , A  :  nar.switched == false  compound isa Task
A , (--, A)  : nar.switched == true
把后一个作为任务.
"""
function compoundself(compound::Negation, component, nar)
    content = nar.switched ? compound : component
    transformneg(content, nar)
end

"""
(&&, A, B, C) , (&&, A, D)
(&&, A, B, C) , (&&, A, B)
(--, <A ==> C>) , (--, A) ?
fall into compound_self()
"""
compoundcompound(compound1, compound2, nar) = false
function compoundcompound(compound1::T, compound2::T, nar) where T <: AbstractCompound
    if length(compound1) > length(compound2)
        compoundself(compound1, compound2, nar)
    elseif length(compound1) < length(compound2)
        nar.switched = !nar.switched
        compoundself(compound2, compound1, nar)
    end
end

"""
就是在Conditional deduction和induction之前对变量做一个unification
condst: An Implication with a Conjunction as condition
index : 相同词项在条件中的位置
side : 相同词项在句子中的位置
"""
unify_conddedind(condst, statement, index, side, nar) = nothing
function unify_conddedind(condst::Implication, statement::Implication, index, side, nar)
    @inbounds comp2 = statement[side]
    _cond_dedind_unify(comp2, condst, statement, index, side, nar)
end

function unify_conddedind(condst::Implication, statement::Inheritance, index, side, nar)
    _cond_dedind_unify(statement, condst, statement, index, -1, nar)
end

function _cond_dedind_unify(comp2, condst, statement, index, side, nar)
    @inbounds cond = condst[1]
    @inbounds comp1 = cond[index]
    # TODO deepcopy?
    unified = unify!(IVar, comp1, comp2, condst, statement)
    if !unified
        unified = unify!(DVar, comp1, comp2, condst, statement)
    end
    if unified
        conddedind(condst, statement, index, side, nar)
    end
end

raw"""
(&, S, T) , <S --> P>
(&&, <a-->b>, <c-->d>) , <<a-->b> ==> <e-->f>>
(&&, <$1 --> bird>, <$1 --> robin>) , <swan --> bird>
"""
compoundstatement(compound, statement, index, side, nar) = nothing

function compoundstatement(compound::Conjunction, statement::Statement, index, side, nar)
    component = compound[index]
    if typeof(component) == typeof(statement) && !isnothing(nar.belief)
        if unify!(DVar, component, statement, compound, statement)
            elimidvar(compound, component, nar)
        elseif nar.forward
            introvarinner(compound, statement, component, nar)
        elseif unify!(QVar, component, statement, compound, statement)
            nar.switched = !nar.switched 
            decomposestatement(compound, component, nar)
        end
    end
end

function compoundstatement(compound::Compound, statement::Inheritance, index, side, nar)
    !nar.forward && return
    Threads.@spawn structuralcompose1(compound, statement, index, side, nar)
    structuralcompose2(compound, statement, index, side, nar)
end

function compoundstatement(compound::Compound, statement::Similarity, index, side, nar)
    !nar.forward && return
    structuralcompose2(compound, statement, index, side, nar)
end

function compoundstatement(compound::Union{NALSet, Negation}, statement::Inheritance, index, side, nar)
    !nar.forward && return
    structuralcompose1(compound, statement, index, side, nar)
end

componentstatement(compound, statement, index, side, nar) = nothing
function componentstatement(compound::Compound, statement::Inheritance, index, side, nar)
    Threads.@spawn structuraldecompose1(compound, statement, index, side, nar)
    Threads.@spawn structuraldecompose2(statement, index, nar)
    transformset(statement, compound, side, nar)
end

"""
对于Similarity的情况呢,一般只是两边进行结构化析构
如果compound是NALSet,那么就要尝试集合转换
"""
function componentstatement(compound::Compound, statement::Similarity, index, side, nar)
    Threads.@spawn structuraldecompose2(statement, index, nar)
    transformset(statement, compound, side, nar)
end

function componentstatement(compound::Negation, statement::Implication, index, side, nar)
    whosetruth = index == 1 ? nar.task.sentence : nar.belief
    contraposition(statement, whosetruth, nar)
end

"""
Whether the direction of Inheritance should be revised.
# TODO ???
"""
switchorder(compound::Term, index) = false
switchorder(compound::Image, index) = index != 1 # ? relaidx?
switchorder(_::NALDifference, index) = index == 2
