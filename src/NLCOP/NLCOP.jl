module NLCOP

using Kombinator
using JuMP

include("exact.jl")
include("approx.jl") # The actual NLCOP algorithm.

end