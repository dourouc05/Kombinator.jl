module UniformMatroid

using Kombinator
using JuMP

include("um.jl")

include("um_dp.jl")
include("um_greedy.jl")
include("um_lp.jl")

include("um_budgeted_dp.jl")
include("um_budgeted_lp.jl")

end
