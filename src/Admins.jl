module Admins

using DataStructures
using ..Gene
using ..Entity

export NaCore, Nar, now, attach!, clear!

const Memory = Narsche{Concept}

"""
携带NaCore,可以对Junars做任何操作
"""
mutable struct NaCore
    mem::Memory
    internal_exp::Narsche{NaTask}
    taskbuffer::MutableLinkedList{NaTask}
    cycles::Ref{UInt}
    serials::Ref{UInt}
end

"""
时间固定的NaCore,专门用于推理
switched: 推理时 tasksentence 是否和 belief_sentence 进行了位置调换
"""
mutable struct Nar
    time::UInt
    forward::Bool
    switched::Bool
    mem::Memory
    internal_exp::Narsche{NaTask}
    taskbuffer::MutableLinkedList{NaTask}
    cpt::Union{Concept, Nothing} # ! 当然进行推理的 Concept
    tasklink::Union{Nothing, TaskLink}
    termlink::Union{Nothing, TermLink}
    task::Union{Nothing, NaTask}
    beliefcpt::Union{Nothing, Concept}
    tasksentence::Union{Sentence, Nothing} # TODO 多余设计?
    belief::Union{Sentence, Nothing}
    Nar(nac::NaCore) = new(
        nac.cycles[],
        true,
        false,
        nac.mem,
        nac.internal_exp, nac.taskbuffer, nothing, nothing,
        nothing, nothing, nothing, nothing, nothing
    )
end

now(nac::NaCore) = Nar(nac)

Base.peek(nar::Nar, target::HashValue) = peek(nar.mem, target)

# TODO 待删除?
function clear!(nar::Nar)
    nar.task = nothing
    nar.tasklink = nothing
    nar.termlink = nothing
    nar.cpt = nothing
    nar.belief = nothing
end
attach!(nar::Nar, cpt::Concept) = nar.cpt = cpt
attach!(nar::Nar, task::NaTask) = nar.task = task

end #module