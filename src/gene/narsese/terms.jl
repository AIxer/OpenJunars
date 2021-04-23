abstract type Term end

abstract type AbstractAtom <: Term end
"""
抽象复合类型的具体类型必须拥有`comps::Vector{Term}`成员!
"""
abstract type AbstractCompound <: Term end

abstract type AbstractVariable <: Term end
abstract type IVar <: AbstractVariable end
abstract type DVar <: AbstractVariable end
abstract type QVar <: AbstractVariable end

"""
# Compound
{} [] & | - ~ * / \\ 两交两差两集合 + Product + Image
# Statement
AbstractStatement 是任何可以具有真值的复合词项
&& || --
Statement 是主谓形式的
--> <-> ==> <=>
"""
abstract type Compound <: AbstractCompound end

abstract type AbstractStatement <: AbstractCompound end
abstract type Statement <: AbstractStatement end

abstract type NALSet <: Compound end
abstract type NALIntersection <: Compound end
abstract type NALDifference <: Compound end
abstract type Image <: Compound end

const Atom = AbstractAtom
const FOTerm = Union{AbstractAtom, Compound}

"Used as '_' in Image."
struct PlaceHolder <: Atom end


"基础的字符词项,仅支持Unicode字符."
mutable struct Word <: Atom
    literal::String
end

"""
NAL-6 里定义的变量:
IVar: 独立变量 \$ 
DVar: 非独立变量 #
QVar: 查询变量 ?
"""
mutable struct Variable{T <: AbstractVariable} <: Atom
    literal::String
end
Base.eltype(::Variable{T}) where T = T

"NAL-8中定义的操作: ^op"
struct Action <: Atom
    op::Symbol
end

"""
## 继承关系词项
形式: <主语 --> 谓语> 主语和谓语不能相同
具有 1.传递性 2. ？？？
更多词项合法性见checkvalid.jl `invalid(s::Statement)`
"""
mutable struct Inheritance <: Statement
    comps::Vector{Term}
    function Inheritance(ϕ₁::FOTerm, ϕ₂::FOTerm)
        ϕ₁ == ϕ₂ && return
        new(deepcopy([ϕ₁, ϕ₂]))
    end
end

"""
相似关系词项
"""
mutable struct Similarity <: Statement
    comps::Vector{Term}
    function Similarity(ϕ₁::FOTerm, ϕ₂::FOTerm)
        ϕ₁ == ϕ₂ && return
        if name(ϕ₁) < name(ϕ₂)
            new(deepcopy([ϕ₁, ϕ₂]))
        else
            new(deepcopy([ϕ₂, ϕ₁]))
        end
    end
end

"""
蕴涵关系
<A ==> <B ==> C>>  等价与 <(&&, A, B) ==> C>
其中 A、B、C 均为 `Statement` 类型的词项
"""
mutable struct Implication <: Statement
    comps::Vector{Term}
    function Implication(ϕ₁::AbstractStatement, ϕ₂::AbstractStatement)
        ϕ₁ == ϕ₂ && return
        new(deepcopy([ϕ₁, ϕ₂]))
    end
end

function Implication(subj::AbstractStatement, pred::Implication)
    psubj = @inbounds pred[1]
    # TODO <A ==> <(&&, A, B) ==> C>>
    if psubj isa Conjunction && subj in psubj
        return
    end
    cond = Conjunction([subj, psubj])
    Implication(cond, pred[2])
end

mutable struct Equivalence <: Statement
    comps::Vector{Term}
    # TODO use sort?
    function Equivalence(ϕ₁::AbstractStatement, ϕ₂::AbstractStatement)
        ϕ₁ == ϕ₂ && return
        if name(ϕ₁) < name(ϕ₂)
            new(deepcopy([ϕ₁, ϕ₂]))
        else
            new(deepcopy([ϕ₂, ϕ₁]))
        end
    end
end

mutable struct Negation <: AbstractStatement
    comps::Vector{Term}
    Negation(ϕ::AbstractStatement) = new(deepcopy([ϕ]))
    Negation(neg::Negation) = Negation(neg.comps[1]) # (--, (--, P)) = P
end


# { }
struct ExtSet <: NALSet
    comps::Vector{Term}
    function ExtSet(c::Vector{T}) where T <: Term
        nothing in c && return # TODO 可能是多余的
        new(deepcopy(sort(c)))
    end
    ExtSet(t::Term) = new([deepcopy(t)]) # 单元素集合表示唯一实例,无外延
end

# []
struct IntSet <: NALSet
    comps::Vector{Term}
    function IntSet(c::Vector{T}) where T <: Term
        nothing in c && return # TODO 可能是多余的
        new(deepcopy(sort(c)))
    end
    IntSet(t::Term) = new([deepcopy(t)]) # 单元素集合表示唯一实例,无内涵
end

# (*, ...)
struct Product <: Compound
    comps::Vector{Term}
    function Product(p::Vector{T}) where T <: Term
        nothing in p && return # TODO 可能是多余的
        new(deepcopy(p))
    end
end

# # (*, arg1, arg2, ...) 操作的参数
# struct ArgProduct <: AbstractProduct
#     comps::Vector{Term}
#     function ArgProduct(ap::Vector{T}) where T <: Term
#         nothing in ap && return
#         new(deepcopy(ap))
#     end
# end

# """
# 操作 (^op, arg1, arg2, ...)
# 实现为继承 <(*, arg1, arg2, arg3, ...) --> ^op>
# """
# mutable struct Operation <: AbstractInheritance
#     comps::Vector{Term}
#     function Operation(ϕ₁::ArgProduct, ϕ₂::Action)
#         new(deepcopy([ϕ₁, ϕ₂]))
#     end
# end

"""
(/, a, b, _, c)
relaidx 的位置其实指的是PlaceHolder的位置
relation总是comps中的第一个元素
"""
struct ExtImage <: Image
    relaidx::Int
    comps::Vector{Term}
    function ExtImage(idx::Int, comps::Vector{T}) where T <: Term
        nothing in comps && return # TODO 可能是多余的
        new(idx, deepcopy(comps))
    end
end

# (\, a, b, _, c)
struct IntImage <: Image
    relaidx::Int
    comps::Vector{Term}
    function IntImage(idx::Int, comps::Vector{T}) where T <: Term
        nothing in comps && return # TODO 可能是多余的
        new(idx, deepcopy(comps))
    end
end

# ∩  &
struct ExtIntersection <: NALIntersection 
    comps::Vector{Term}
    function ExtIntersection(comps::Vector{T}) where T <: Term
        nothing in comps && return # TODO 可能是多余的
        new(deepcopy(sort(comps)))
    end
end

# ∩ |
struct IntIntersection <: NALIntersection
    comps::Vector{Term}
    function IntIntersection(comps::Vector{T}) where T <: Term
        nothing in comps && return # TODO 可能是多余的
        new(deepcopy(sort(comps)))
    end
end

# &&
struct Conjunction <: AbstractStatement
    comps::Vector{AbstractStatement}
    function Conjunction(comps::Vector{T}) where T <: AbstractStatement
        nothing in comps && return # TODO 可能是多余的
        new(deepcopy(sort(comps)))
    end
end

Conjunction(cj1, cj2) = Conjunction(AbstractStatement[cj1, cj2])
Conjunction(cj1::Conjunction, cj2::AbstractStatement) = Conjunction(AbstractStatement[cj1.comps; cj2])
Conjunction(cj1::Conjunction, cj2::Conjunction) = Conjunction(AbstractStatement[cj1.comps; cj2.comps])
Conjunction(cj1::AbstractStatement, cj2::Conjunction) = Conjunction(AbstractStatement[cj1; cj2.comps])


# ||
struct Disjunction <: AbstractStatement
    comps::Vector{Term}
    function Disjunction(comps::Vector{T}) where T <: AbstractStatement
        nothing in comps && return # TODO 可能是多余的
        new(deepcopy(sort(comps)))
    end
end

# -
mutable struct ExtDiff <: NALDifference
    comps::Vector{Term}
    ExtDiff(ϕ₁::Term, ϕ₂::Term) = new(deepcopy([ϕ₁, ϕ₂]))
end

# ~ 确定这个结构体只能存两个数
mutable struct IntDiff <: NALDifference
    comps::Vector{Term}
    IntDiff(ϕ₁::Term, ϕ₂::Term) = new(deepcopy([ϕ₁, ϕ₂]))
end

const TermSet = Union{NALSet, NALIntersection, Conjunction, Disjunction}

mut(s::Statement) = typeof(s)(s.ϕ₂, s.ϕ₁)
bro(::Type{Inheritance}) = Similarity
bro(::Type{Implication}) = Equivalence

# 词项复杂度
cpx(t::Atom) = 1
cpx(t::Statement) = @inbounds cpx(t[1]) + cpx(t[2])
cpx(t::AbstractCompound) = 1 + sum(cpx.(t.comps))

hasvar(t::Atom) = false
hasvar(t::Variable) = true
hasvar(t::AbstractCompound) = reduce(|, hasvar.(t.comps))

has(::Type{T}, t::Atom) where T <: AbstractVariable = false
has(::Type{T}, t::Variable) where T <: AbstractVariable = eltype(t) == T
has(::Type{T}, t::AbstractCompound) where T <: AbstractVariable = reduce(|, (x->has(T, x)).(t.comps))

hasivar(t::Term) = has(IVar, t)


# 这里得有个预设,默认一个词项是常量还是变量?
# TODO 其实这里判断是不是变量有两种类型，一种是Variable词项，另一种是<$x-->sth>这种复合变量
isvar(t::Term) = t isa Variable

# TODO 目前还不完善
# TODO (*, $1, $2)
isopenvar(t::Term) = false
isopenvar(t::Variable) = true 
# <x --> $1> false
isopenvar(s::Union{Inheritance, Similarity}) = @inbounds isopenvar(s[1]) || isopenvar(s[2])
# <<$x—>bird> ==> <$x—>[fly]>> false 只一边有才行, ⊻ : 异或
isopenvar(s::Union{Implication, Equivalence}) = has(IVar, s[1]) ⊻ has(IVar, s[2])
isopenvar(c::Union{Product, Image}) = hasvar(c)
# ! 检查比较松散
function isopenvar(c::Union{Conjunction, Disjunction})
    dvarc = 0
    for comp in c
        if has(DVar, comp)
            dvarc += 1
        end
    end
    dvarc == 1 && return true
    return false
end

isconstant(t) = !isopenvar(t)
iscommutative(t) = t isa TermSet || t isa Union{Similarity, Equivalence}

Base.hash(t::Term, h::UInt64) = hash(name(t), h)
Base.:(==)(t1::Term, t2::Term) = name(t1) == name(t2)

"""
getindex, setindex, sort, sort! 不能用于Atom
"""
Base.getindex(c::AbstractCompound, i) = c.comps[i]
Base.setindex(c::AbstractCompound, v, i) = c.comps[i] = v
Base.setindex!(c::AbstractCompound, v, i) = @inbounds c.comps[i] = v
Base.firstindex(c::AbstractCompound) = 1
Base.lastindex(c::AbstractCompound) = length(c.comps)
Base.length(c::Atom) = 1
Base.length(c::AbstractCompound) = length(c.comps)
Base.iterate(c::Atom, state=1) = nothing 
Base.iterate(c::AbstractCompound, state=1) = iterate(c.comps, state)

"""
(&&, (&&, A, B), C) => (&&, A, B, C)
"""
function Base.setindex!(c::T, v::T, i) where T <: TermSet
    deleteat!(c.comps, i)
    for comp in v.comps
        comp in c.comps && continue
        push!(c.comps, comp)
    end
    sort!(c)
end

Base.isless(c1::Term, c2::Term) = isless(name(c1), name(c2))
Base.sort(c::AbstractCompound) = typeof(c)(sort(c.comps))
Base.sort!(c::AbstractCompound) = sort!(c.comps)

# Base.setdiff(c1::AbstractCompound, c2::AbstractCompound) = setdiff(c1.comps, c2.comps)
# Base.setdiff(c1::AbstractCompound, c2::Term) = setdiff(c1.comps, [c2])
# Base.setdiff(c1::Term, c2::AbstractCompound) = setdiff(c2, c1)

Base.in(component::Term, compound::Term) = false
Base.in(component::Term, compound::AbstractCompound) = in(component, compound.comps)

shuffle!(t::AbstractCompound) = shuffle!(t.comps)
shuffle(t::AbstractCompound) = typeof(t)(shuffle(t.comps))
