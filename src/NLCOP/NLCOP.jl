module NLCOP

using Kombinator
using JuMP

export ExactNonlinearSolver, ApproximateNonlinearSolver

import Kombinator: solve

include("exact.jl")
include("approx.jl") # The actual NLCOP algorithm.

end