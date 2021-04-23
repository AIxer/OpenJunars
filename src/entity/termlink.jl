"""
Termlink的token意义:
    target: 目标概念的HashCode
    bgt: 代表链接本身的预算值
dir: ↻ ↑ ↓
index: 1,2,3...
"""
@enum LinkStyle begin
    SELF                # 链接到自己,只能用于TaskLink
    COMPOUND            # C to (&&, A, C)
    COMPONENT           # (&&, A, C) to C
    COMPONENT_STATEMENT # <A --> C> to A
    COMPOUND_STATEMENT  # A to <A --> C>
    COMPONENT_CONDITION # <(&&, C, B) ==> A> to C
    COMPOUND_CONDITION  # C to <(&&, C, B) ==> A>
    TRANSFORM
end

# @data LinkFix begin
#     CONDITION
#     STATEMENT
#     Empty
# end

# @data LinkStyle begin
#    SELF
#    COMPOUND(LinkFix)
#    COMPONENT(LinkFix)
#    TRANSFORM
# end

MLStyle.is_enum(::LinkStyle) = true
MLStyle.pattern_uncall(e::LinkStyle, _, _, _, _) = literal(e)
mutable struct TermLink <: Racer
    token::Token
    ltype::LinkStyle
    pos::SVector
end

Gene.forget!(tlink::TermLink) = forget!(bgt(tlink), NaParam.TERMLINK_FORGET_CYCLES)