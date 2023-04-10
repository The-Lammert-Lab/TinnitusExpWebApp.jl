module Experiments

import SearchLight: AbstractModel, DbId

using SearchLight
using CharacterizeTinnitus.ExperimentsValidator
using CharacterizeTinnitus.TinnitusReconstructor
using OrderedCollections
using JSON3
using SHA
import SearchLight.Validation: ModelValidator, ValidationRule

export Experiment

const STIMGEN_MAPPINGS = Dict{String,UnionAll}(
    "UniformPrior" => UniformPrior,
    "GaussianPrior" => GaussianPrior,
    "Brimijoin" => Brimijoin,
    "Bernoulli" => Bernoulli,
    "BrimijoinGaussianSmoothed" => BrimijoinGaussianSmoothed,
    "GaussianNoise" => GaussianNoise,
    "UniformNoise" => UniformNoise,
    "GaussianNoiseNoBins" => GaussianNoiseNoBins,
    "UniformNoiseNoBins" => UniformNoiseNoBins,
    "UniformPriorWeightedSampling" => UniformPriorWeightedSampling,
    "PowerDistribution" => PowerDistribution,
)

"""
    function stimgen_from_json(json::AbstractString, name::AbstractString)

Returns a fully instantiated stimgen type from JSON string of field values and type name.
"""
function stimgen_from_json(json::AbstractString, name::AbstractString)
    j = JSON3.read(json, Dict{Symbol,Any})
    try
        map!(x -> Meta.parse(x), values(j))
    finally
        return STIMGEN_MAPPINGS[name](; j...)
    end
end

mutable struct Experiment <: AbstractModel
    id::DbId
    stimgen_settings::String
    stimgen_type::String
    n_trials::Int
    name::String
    settings_hash::String

    # Inner constructor to force consistency in settings_hash
    function Experiment(;
        id::DbId = DbId(),
        stimgen_settings::AbstractString = "",
        stimgen_type::AbstractString = "",
        n_trials::Int = 0,
        name::AbstractString = "",
    )
        # Reconstruct the stimgen obj to make sure settings are valid and hash is consistent
        if !isempty(stimgen_settings)
            stimgen = try
                stimgen_from_json(stimgen_settings, stimgen_type)
            catch ex
                return error(
                    "Could not construct stimuli from given stimgen_settings and stimgen_type. Error: $ex",
                )
            end
            # Remove Arrays and dist filepath but keep order (LittleDict is ordered)
            stimgen_settings =
                LittleDict{Symbol,Any}(
                    key => getfield(stimgen, key) for key in fieldnames(typeof(stimgen)) if
                    !(getfield(stimgen, key) isa AbstractArray) ||
                    key == :distribution_filepath
                ) |> JSON3.write
        end
        settings_hash = hash_settings(stimgen_settings)
        return new(id, stimgen_settings, stimgen_type, n_trials, name, settings_hash)
    end
end

SearchLight.Validation.validator(::Type{Experiment}) = ModelValidator([
    ValidationRule(:stimgen_settings, ExperimentsValidator.not_empty),
    ValidationRule(:stimgen_type, ExperimentsValidator.not_empty),
    ValidationRule(:n_trials, ExperimentsValidator.is_positive),
    ValidationRule(:n_trials, ExperimentsValidator.is_int),
    ValidationRule(:name, ExperimentsValidator.not_empty),
    ValidationRule(:name, ExperimentsValidator.is_unique),
])

hash_settings(settings::AbstractString) = sha256(settings) |> bytes2hex

end
