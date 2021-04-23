module Entity

import Base: union, union!
using DataStructures
using StaticArrays
using MLStyle
using MLStyle.AbstractPatterns: literal

import ..Gene: quality, name, forget!, merge!, isvar, target, priority, above_threshold
using ..Gene

export Concept, Table, Stamp, Belief, NaTask, TaskLink, BLinkRecord, TermLink, LinkStyle
export Sentence, Judgement, Question
export unionstamp, conceptualize, preparelinks, overlapped, rank, isjudgment, LinkTree
export add!, remove!, forget!, activate!, putback!

export SELF, COMPOUND, COMPONENT, COMPOUND_STATEMENT, COMPONENT_STATEMENT, 
    COMPONENT_CONDITION, COMPOUND_CONDITION, TRANSFORM

include("parameters.jl")

include("entity/table.jl")
include("entity/stamp.jl")
include("entity/sentence.jl")
include("entity/task.jl")
include("entity/termlink.jl")
include("entity/tasklink.jl")
include("entity/belief.jl")
include("entity/concept.jl")
include("entity/conceptualize.jl")
include("entity/mix.jl")

end # module