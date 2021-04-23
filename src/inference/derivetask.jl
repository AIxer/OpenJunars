abstract type TruthStyle end
struct Analy <: TruthStyle end

# TODO
const RELIANCE = 0.9

"""
用于单前提推理
单前提推理其实用不到 belief, 所以 真值 就用tasksentence的 真值
truth_func:: Symbol or Function ?
"""
function derivetask1(::T, term, nar) where T <: BackwardStyle
    # 这里的真值只是用来计算预算值
    truth = nar.tasksentence.truth
    derivetask!(T, term, truth, nar)
end

function derivetask1(::T, term::Term, truth_func::Symbol, nar::Nar) where T <: ForwardStyle
    # ! 避免循环推理
    ptask = nar.task.ptask
    if !isnothing(ptask)
        term == ptask.sentence.term && return
    end
    truth = @eval $truth_func($nar.tasksentence.truth)
    derivetask!(T, term, truth, nar)
end

function derivetask1(::T, term::Term, truth_func::Symbol, nar, ::Analy) where T <: ForwardStyle
    ptask = nar.task.ptask
    if !isnothing(ptask)
        term == ptask.sentence.term && return
    end
    truth = @eval $truth_func($nar.tasksentence.truth, $(RELIANCE))
    derivetask!(T, term, truth, nar)
end

"""
用于双前提推理
"""
function derivetask2(::T, term, nar) where T <: BackwardStyle
    # 这里的真值只是用来计算预算值
    truth = nar.belief.truth
    derivetask!(T, term, truth, nar)
end

function derivetask2(::T, term, truth_func::Symbol, nar) where T <: Union{ForwardStyle, LocalStyle}
    isnothing(nar.belief) && return
    truth = @eval $truth_func($nar.tasksentence.truth, $nar.belief.truth)
    derivetask!(T, term, truth, nar)
end

"""
生成NaTask并放入内部经验中
"""
derivetask!(::Type{T}, ::Nothing, truth, nar) where T = nothing
function derivetask!(::Type{T}, term::Term, truth, nar::Nar) where T <: RuleStyle
    invalid(term) && return
    renamevar!(term)
    isopenvar(term) && return
    # term === nothing && return
    bgt = calcbgt(T, truth, cpx(term), nar)
    !above_threshold(bgt) && return
    SenType = eltype(nar.tasksentence)
    if SenType <: Judgement
        # expect(truth) < NaParam.DEFAULT_CREATION_EXPECTATION && return
        truth.confidence < NaParam.TRUTH_EPSILON && return # no confidence
    end
    token = Token(hash(term), bgt)

    if isnothing(nar.belief)
        stamp = nar.tasksentence.stamp
    else
        stamp = unionstamp(nar.tasksentence.stamp, nar.belief.stamp, nar.time)
    end

    revisable = !(term isa Conjunction && has(DVar, term))
    sentence = Sentence{SenType}(term, truth, stamp; revisable)
    printstyled("    Derived $(name(sentence))\n", bold=true, color=:light_green)
    task = NaTask(token, sentence, nar.task, nar.belief, nothing)
    push!(nar.taskbuffer, task)
    return task
end