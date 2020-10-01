using Kombinator
using Test

@testset "Kombinator.jl" begin
  include("ep.jl")
  include("matching.jl")
  include("msets.jl")
  include("st.jl")
end
