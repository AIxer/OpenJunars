abstract type AbstractSentence end
abstract type Judgement <: AbstractSentence end
abstract type Question <: AbstractSentence end
abstract type Goal <: AbstractSentence end
abstract type Quest <: AbstractSentence end

# TODO revisible
# term isa Conjunction && hasdvar(term)   revisiable = false
mutable struct Sentence{T <: AbstractSentence}
    term::AbstractCompound
    truth::Union{Nothing, Truth}
    stamp::Stamp
    revisable::Bool
end

Sentence{Judgement}(term, truth, stamp; revisable=true) = Sentence{Judgement}(term, truth, stamp, revisable)
Sentence{Question}(term, truth, stamp; revisable=true) = Sentence{Question}(term, nothing, stamp, revisable)

isjudgment(s::Sentence) = s isa Sentence{Judgement}

Gene.name(st::Sentence) = name(st.term) * (isa(st, Sentence{Question}) ? "?" : ". $(string(round(st.truth)))")

Base.hash(st::Sentence, h::UInt) = hash(name(st), h)
Base.:(==)(s1::Sentence, s2::Sentence) = hash(s1) == hash(s2)
Base.eltype(::Sentence{T}) where T = T

