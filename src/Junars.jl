module Junars

using Reexport

# include(joinpath(@__DIR__, "xxx.jl")) 用于避免因操作系统平台差异导致的导入问题

include(joinpath(@__DIR__, "Gene.jl"))
Reexport.@reexport using .Gene

include(joinpath(@__DIR__, "Entity.jl"))
Reexport.@reexport using .Entity

include(joinpath(@__DIR__, "Admins.jl"))
Reexport.@reexport using .Admins

include(joinpath(@__DIR__, "Inference.jl"))
Reexport.@reexport using .Inference

include(joinpath(@__DIR__, "Control.jl"))
Reexport.@reexport using .Control

# for fname in names(Gene)
#     @eval import .Gene: $(fname)
#     @eval export $(fname)
# end

end # moudle