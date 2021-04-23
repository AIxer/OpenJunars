
"""
⋃ bigcup
⋂ bigcap
⊖ ominus

→ rightarrow
⇒ Rightarrow
⇔ Leftrightarrow
↔ leftrightarrow

∧ wedge
∨ vee

⋂ Extensional Intersection
⋃ Intensional Intersection

-  Extensional Differernce
⊖ Intensional Differernce
"""

⋂(t1::Term, t2::Term) = ExtIntersection([t1, t2])
⋃(t1::Term, t2::Term) = IntIntersection([t1, t2])

function ⋂(t1::T, t2::T) where T <: Union{IntSet, ExtSet}
    comps = intersect(t1.comps, t2.comps)
    length(comps) == 0 && return
    T(comps)
end

⋃(t1::Atom, t2::Atom) = IntIntersection([t1, t2])
⋃(t1::T, t2::T) where T <: Union{IntSet, ExtSet} = T(union(t1.comps, t2.comps))

-(t1::Atom, t2::Atom) = Extdiff(t1, t2)
function Base.:-(t1::ExtSet, t2::ExtSet)
    comps = setdiff(t1.comps, t2.comps)
    length(comps) == 0 && return
    Extset(comps)
end

⊖(t1::Atom, t2::Atom) = IntDiff(t1, t2)
function ⊖(t1::IntSet, t2::IntSet)
    comps = setdiff(t1.comps, t2.comps)
    length(comps) == 0 && return
    IntSet(comps)
end

∨(t1::AbstractCompound, t2::AbstractCompound) = Disjunction([t1, t2])
∧(t1::AbstractCompound, t2::AbstractCompound) = Conjunction([t1, t2])


Base.:∈(t::Term, ts::TermSet) = t ∈ ts.comps
