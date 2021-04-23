import Base: round, string

struct Truth
    frequency::Float64
    confidence::Float64
    analytical::Bool    # 该真值是否从定义中得来 有什么用呢？Never Used
end

# TODO 去掉魔数
Truth() = Truth(1.0, 0.9, false)
Truth(f::Float64) = Truth(f, 0.9, false)
Truth(f, c) = Truth(f, c, false)

function round(t::Truth; digits=2)
    roundconf = round(t.confidence; digits)
    Truth(round(t.frequency; digits), roundconf == 1.0 ? 0.99 : roundconf)
end

# truth to quality
function t2q(t::Truth)
    e = expect(t)
    max(e, (1 - e) * 0.75)
end

expect(t::Truth) = t.confidence * (t.frequency - 0.5) + 0.5
absexpdiff(t1, t2) = abs(t2q(t1) - t2q(t2))

string(t::Truth) = "%$(t.frequency);$(t.confidence)%"

"""
Single argument functions, called in MatchingRules:
    conversion(v)

Single argument functions, called in StructuralRules:
    negation(v)
    contraposition(v)

Double argument functions, called in MatchingRules:
    revision(v1, v2)

Double argument functions, called in SyllogisticRules:
    deduction(v1, v2)
    deduction(v, c)
    analogy(v1, v2)
    resemblance(v1, v2)
    abduction(v1, v2)
    abduction(v, c)
    exemplification(v1, v2)
    comparision(v1, v2)

Double argument functions, called in CompositionalRules:
    union(v1, v2)
    intersection(v1, v2)
    reducedisj(v1, v2)
    reduceconj(v1, v2)
    reduceconj_neg(v1, v2)
    anonymous_analogy(v1, v2)
"""

# {< A ==> B>} |- < B ==> A>
function conversion(v::Truth)
    w = and(v.frequency, v.confidence)
    Truth(1, w2c(w))
end

# A |- (--A)
function negation(v::Truth)
    f = 1 - v.frequency
    Truth(f, v.confidence)
end

# {< A ==> B>} |- <(--, B) ==> (--, A)>
function contraposition(v::Truth)
    w = and(1 - v.frequency, v.confidence)
    Truth(0, w2c(w))    
end

function revision(v1::Truth, v2::Truth)
    f1 = v1.frequency
    f2 = v2.frequency
    w1 = c2w(v1.confidence)
    w2 = c2w(v2.confidence)
    w = w1 + w2
    f = (w1 * f1 + w2 * f2) / w
    Truth(f, w2c(w))
end

function deduction(v1::Truth, v2::Truth)
    f = and(v1.frequency, v2.frequency)
    c = and(v1.confidence, v2.confidence, f)
    Truth(f, c)
end
inv_ded(v1::Truth, v2::Truth) = deduction(v2, v1)

# M, M ==> P |- P
# reliance: The confidence of the second premise
# Analitical Truth
function deduction(v::Truth, reliance::Float64)
    c = and(v.frequency, v.confidence, reliance)
    Truth(v.frequency, c, true)
end


function exemplification(v1::Truth, v2::Truth)
    (v1.analytical || v2.analytical) && return Truth(0.5, 0)
    w = and(v1.frequency, v2.frequency, v1.confidence, v2.confidence)
    Truth(1.0, w2c(w))
end

function comparision(v1::Truth, v2::Truth)
    f0 = or(v1.frequency, v2.frequency)
    f = f0 == 0 ? 0 : (and(v1.frequency, v2.frequency) / f0)
    w = and(f0, v1.confidence, v2.confidence)
    Truth(f, w2c(w))
end

inv_com(v1, v2) = comparision(v2, v1)

function abduction(v1::Truth, v2::Truth)
    w = and(v2.frequency, v1.confidence, v2.confidence)
    Truth(v1.frequency, w2c(w))
end
inv_abd(v1::Truth, v2::Truth) = abduction(v2, v1)

function abduction(v::Truth, reliance::Float64)
    v.analytical && return Truth(0.5, 0)
    w = and(v.confidence, reliance)
    Truth(v.frequency, w2c(w))
end

induction(v1::Truth, v2::Truth) = abduction(v2, v1)
inv_ind(v1::Truth, v2::Truth) = abduction(v1, v2)

function intersection(v1::Truth, v2::Truth)
    f = and(v1.frequency, v2.frequency)
    c = and(v1.confidence, v2.confidence)
    Truth(f, c)
end

function union(v1::Truth, v2::Truth)
    f = or(v1.frequency, v2.frequency)
    c = and(v1.confidence, v2.confidence)
    Truth(f, c)
end

function analogy(v1::Truth, v2::Truth)
    f = and(v1.frequency, v2.frequency)
    c = and(v1.confidence, v2.confidence, v2.frequency)
    Truth(f, c)
end
inv_ana(v1::Truth, v2::Truth) = analogy(v2, v1)

function resemblance(v1::Truth, v2::Truth)
    f = and(v1.frequency, v2.frequency)
    c = and(v1.confidence, v2.confidence, or(v1.frequency, v2.frequency))
    Truth(f, c)
end

# {(||, A, B), (--, B)} |- A
function reducedisj(v1::Truth, v2::Truth)
    v0 = intersection(v1, negation(v2))
    deduction(v0, 1.0)
end
inv_reducedisj(v1, v2) = reducedisj(v2, v1)

# {(--, (&&, A, B)), B} |- (--, A)
function reduceconj(v1::Truth, v2::Truth)
    v0 = intersection(negation(v1), v2)
    negation(deduction(v0, 1.0))
end
inv_reduceconj(v1, v2) = reduceconj(v2, v1)

# {(--, (&&, A, (--, B))), (--, B)} |- (--, A)
reduceconj_neg(v1::Truth, v2::Truth) = reduceconj(v1, negation(v2))
inv_reduceconj_neg(v1, v2) = reduceconj_neg(v2, v1)

difference(v1::Truth, v2::Truth) = intersection(v1, negation(v2))
inv_difference(v1::Truth, v2::Truth) = difference(v2, v1)

# {(&&, <#x() ==> M>, <#x() ==> P>), S ==> M} |- P>
function anonymous_analogy(v1::Truth, v2::Truth)
    v0 = Truth(v1.frequency, w2c(v1.confidence))
    analogy(v2, v0)
end
inv_anonymous_ana(v1, v2) = anonymous_analogy(v2, v1)

isnegative(v::Truth) = v.frequency < 0.5
