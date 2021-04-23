module Control

using DataStructures
using StaticArrays

using ..Gene
using ..Entity
using ..Admins
using ..Inference

export absorb!, parse_term, parsese, ignite, addone, cycle!

"""
```
在Revise操作中,作为重复Task的判断变量
```
"""

const HashValue = UInt64
const Memory = Narsche{Concept}

include("parameters.jl")

include("control/memory.jl")
include("control/infer.jl")
include("control/launch.jl")
include("control/channels/Narsese/parser.jl")
include("control/cmdline.jl")

end # module