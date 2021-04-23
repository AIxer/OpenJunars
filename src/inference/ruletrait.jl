"""
推理类型: forward、backward、compound-statement ...
"""
abstract type RuleStyle end
abstract type ForwardStyle <: RuleStyle end
abstract type BackwardStyle <: RuleStyle end
abstract type LocalStyle <: RuleStyle end

struct Revise <: LocalStyle end
struct Forward <: ForwardStyle end
struct Backward <: BackwardStyle end
struct BackwardWeak <: BackwardStyle end
struct CompoundForward <: ForwardStyle end
struct CompoundBackward <: BackwardStyle end
struct CompoundBackwardWeak <: BackwardStyle end


"""
根据推理类型计算结论的预算值
"""
# TODO
calcbgt(::Type{Revise}, truth, cpx::Int, nar::Nar) = reviselinks!(truth, nar)
calcbgt(::Type{Forward}, truth, cpx::Int, nar::Nar) = calcbgt(t2q(truth), 1, nar)
calcbgt(::Type{Backward}, truth, cpx::Int, nar::Nar) = calcbgt(t2q(truth), 1, nar)
calcbgt(::Type{BackwardWeak}, truth, cpx::Int, nar::Nar) = calcbgt(0.5 * t2q(truth), 1, nar)
calcbgt(::Type{CompoundForward}, truth, cpx::Int, nar::Nar) = calcbgt(t2q(truth), cpx, nar)
calcbgt(::Type{CompoundBackward}, truth, cpx::Int, nar::Nar) = calcbgt(1., cpx, nar)
calcbgt(::Type{CompoundBackwardWeak}, truth, cpx::Int, nar::Nar) = calcbgt(0.5, cpx, nar)

function calcbgt(qual::Float64, termcpx::Int, nar::Nar)
    tlink = nar.tasklink
    blink = nar.termlink
    newpri = priority(tlink)
    newdura = durability(tlink) / termcpx
    newqual = qual / termcpx
    if blink !== nothing
        newpri = or(newpri, priority(blink))
        newdura = and(newdura, durability(blink))
        actval = isnothing(nar.beliefcpt) ? 0. : priority(nar.beliefcpt)
        inc_priority!(blink, or(newqual, actval))
        inc_durability!(blink, newqual)
    end
    Budget(newpri, newdura, newqual)
end

