module UniformMatroid

using Kombinator

using JuMP

import Base: copy
import Kombinator: solve, dimension, value, values, formulation, create_solution

export UniformMatroidInstance, UniformMatroidSolution, MinBudgetedUniformMatroidSolution, items, items_all_budgets

include("um.jl")

include("um_dp.jl")
include("um_greedy.jl")
include("um_lp.jl")

include("um_budgeted_dp.jl")
include("um_budgeted_lp.jl")

end
