mutable struct Concept <: Racer
    term::Term
    token::Token
    tasklinks::Narsche{TaskLink}
    termlinks::Narsche{TermLink}
    questions::MutableLinkedList{NaTask}
    beliefs::Union{Nothing, Table{Belief}}
end

function Concept(term, bgt)
    Concept(term,
        Token(hash(term), deepcopy(bgt)),
        Narsche{TaskLink}(5, 3, 20),
        Narsche{TermLink}(5, 3, 20),
        MutableLinkedList{NaTask}(),
        nothing)
end

hashcode(cpt::Concept) = token(cpt).target  # == hash(cpt.term) 没什么用
Gene.name(cpt::Concept) = name(cpt.term)

"""
仅作为激活用
"""
function Base.merge!(cpt1::Concept, cpt2::Concept)
    activate!(cpt1, bgt(cpt2))
    # TODO
    merge!(cpt1.tasklinks, cpt2.tasklinks)
    merge!(cpt1.termlinks, cpt2.termlinks)
    nothing
end

function activate!(ns::Narsche{Concept}, cpt::Concept, task)
    out_track!(ns, cpt)
    activate!(cpt, task)
    into_track!(ns, cpt)
    nothing
end

function activate!(cpt::Concept, bgt::Budget)
    token(cpt).bgt = Budget(
        or(priority(cpt), bgt.priority),
        ave_ari(durability(cpt), bgt.durability),
        quality(cpt)
    )
end
activate!(cpt::Concept, racer::Racer) = activate!(cpt, bgt(racer))
function activate!(ns::Narsche{T}, racer::T, sti) where T
    out_track!(ns, racer)
    activate!(racer, sti)
    intro_track!(ns, racer)
end

Base.show(io::IO, cpt::Concept) = show(io, name(cpt))

Gene.forget!(cpt::Concept) = forget!(bgt(cpt), NaParam.CONCEPT_FORGET_CYCLES)
