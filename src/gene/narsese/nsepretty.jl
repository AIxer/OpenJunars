name(t::Word) = t.literal
name(t::Action) = "^$(string(t.op))"
name(t::PlaceHolder) = "_"
name(t::Variable{IVar}) = "\$$(t.literal)"
name(t::Variable{DVar}) = "#$(t.literal)"
name(t::Variable{QVar}) = "?$(t.literal)"

# name(t::Operation) = @inbounds "($(name(t[2])),$(name(t[1])[4:end])"
name(t::Inheritance) = @inbounds "<$(name(t[1]))-->$(name(t[2]))>"
name(t::Similarity) = @inbounds "<$(name(t[1]))<->$(name(t[2]))>"
name(t::Implication) = @inbounds "<$(name(t[1]))==>$(name(t[2]))>"
name(t::Equivalence) = @inbounds "<$(name(t[1]))<=>$(name(t[2]))>"

name(t::ExtSet) = "{" * join(name.(t.comps), ",") * "}"
name(t::IntSet) = "[" * join(name.(t.comps), ",") * "]"
name(t::ExtIntersection) = "(&," * join(name.(t.comps), ",") * ")"
name(t::IntIntersection) = "(|," * join(name.(t.comps), ",") * ")"
name(t::ExtDiff) =  @inbounds "(-,$(name(t[1])),$(name(t[2])))"
name(t::IntDiff) =  @inbounds "(~,$(name(t[1])),$(name(t[2])))"
name(t::ExtImage) = "(/," * join(name.(t.comps), ",") * ")"
name(t::IntImage) = "(\\," * join(name.(t.comps), ",") * ")"
name(t::Product) = "(*," * join(name.(t.comps), ",") * ")"

name(t::Negation) = "(¬,$(name(t.comps[1])))"
name(t::Conjunction) = "(&&," * join(name.(t.comps), ",") * ")"
name(t::Disjunction) = "(||," * join(name.(t.comps), ",") * ")"

Base.show(io::IO, t::Term) = show(io, name(t))
