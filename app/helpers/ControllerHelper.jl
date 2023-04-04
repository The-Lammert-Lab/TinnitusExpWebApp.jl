"""
When TinnitusReconstructor is its own package, use this module to keep things DRY.

"""
module ControllerHelper

# using CharacterizeTinnitus.TinnitusReconstructor
# using JSON3

# export STIMGEN_MAPPINGS
# export stimgen_from_json

# const STIMGEN_MAPPINGS = Dict{String,UnionAll}(
#     "UniformPrior" => UniformPrior,
#     "GaussianPrior" => GaussianPrior,
#     "Brimijoin" => Brimijoin,
#     "Bernoulli" => Bernoulli,
#     "BrimijoinGaussianSmoothed" => BrimijoinGaussianSmoothed,
#     "GaussianNoise" => GaussianNoise,
#     "UniformNoise" => UniformNoise,
#     "GaussianNoiseNoBins" => GaussianNoiseNoBins,
#     "UniformNoiseNoBins" => UniformNoiseNoBins,
#     "UniformPriorWeightedSampling" => UniformPriorWeightedSampling,
#     "PowerDistribution" => PowerDistribution,
# )

# """ 
#     stimgen_from_json(json::T, name::T) where {T<:AbstractString}

# Returns a fully instantiated stimgen type from JSON string of field values and type name.
# """
# function stimgen_from_json(json::T, name::T) where {T<:AbstractString}
#     j = JSON3.read(json, Dict{Symbol,Any})
#     try
#         map!(x -> Meta.parse(x), values(j))
#     finally
#         return STIMGEN_MAPPINGS[name](; j...)
#     end
# end

end
