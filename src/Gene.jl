module Gene

import Base: -, union, merge, merge!, string, round, ==
import Random: shuffle!, shuffle

export and, or, c2w, w2c

export Term, AbstractAtom, AbstractCompound
export AbstractVariable, IVar, DVar, QVar
export Compound, AbstractStatement, Statement
export ExtSet, IntSet, ExtIntersection, IntIntersection, ExtDiff, IntDiff
export Product, ExtImage, IntImage, Image
export Inheritance, Similarity, Implication, Equivalence, Negation, Conjunction, Disjunction
export Atom, Word, Variable, Action
export FOTerm, NALSet, NALIntersection, NALDifference

export ⋃, ⋂, ⊖, ∧, ∨
export name, bro, cpx
export isvar, isopenvar, isconstant, iscommutative, has, hasvar, hasivar
export unify!, renamevar!, findsubstitute, applysubs!

export Racer, token, bgt, target, priority, durability, quality
export dec_priority!, dec_durability!, dec_quality!, inc_priority!, inc_durability!, inc_quality!

export Narsche, take!, put!, pick, into_track!, out_track!
export Budget, Token, ave_ari, ave_geo, ave_priority, above_threshold

export Truth, expect, absexpdiff, t2q, revision, isnegative
export deduction, induction, abduction, analogy
export contraposition, negation, conversion, resemblance, exemplification, comparision, intersection, difference
export reduceconj, reducedisj, reduceconj_neg, anonymous_analogy, inv_anonymous_ana,
    inv_abd, inv_ded, inv_ind, inv_com, inv_reduceconj, inv_reducedisj,
    inv_reduceconj_neg, inv_ana, inv_difference

export HashValue, @w_str

include("parameters.jl")
# Extended Boolean function
# A function where the output is conjunctively determined by the inputs
# 这么做是为了提高性能
and(a, b) = a * b
and(a, b, c) = a * b * c
and(a, b, c, d) = a * b * c * d

# A function where the output is disjunctively determined by the inputs
or(a, b) = 1.0 - (1 - a ) * (1 - b)
or(a, b, c) = 1.0 - (1 - a) * (1 - b) * (1 - c)

const H = NaParam.HORIZION

# weight to confidence
w2c(w::Float64) = w / (w + H)
# confidence to weight
c2w(c::Float64) = H * c / (1 - c)

const HashValue = UInt64

include("gene/narsese/terms.jl")
include("gene/narsese/renamevar.jl")
include("gene/narsese/unifyvar.jl")
include("gene/narsese/nsepretty.jl")
include("gene/narsese/operators.jl")

include("gene/truthvalue.jl")
include("gene/budget.jl")

include("gene/racer.jl")
include("gene/token.jl")

include("gene/distributor.jl")
include("gene/narsche.jl")


macro w_str(s)
    Word(s)
end

end # module