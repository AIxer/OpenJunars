module Inference

using ..Gene
using ..Entity
using ..Admins: Nar, attach!

using MLStyle
using MLStyle.AbstractPatterns: literal

export RuleStyle, Forward, Backward, BackwardWeak, CompoundForward, CompoundBackward, CompoundBackwardWeak
export calcbgt, derivetask!, derivetask1, derivetask2, localmatch, transformrela
export dispatch, dispatch2
export trysolution!, revise

const FOStatement = Union{Inheritance, Similarity}

include("inference/validcheck.jl")
include("inference/ruletrait.jl")
include("inference/derivetask.jl")
include("inference/utils.jl")
include("inference/ruledispatch.jl")
include("inference/localrules.jl")
include("inference/compositional.jl")
include("inference/conditional.jl")
include("inference/syllogism.jl")
include("inference/structrual.jl")

include("parameters.jl")

end # module