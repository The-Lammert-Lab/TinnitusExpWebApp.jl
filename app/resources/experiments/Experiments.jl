module Experiments

import SearchLight: AbstractModel, DbId

using SearchLight
using CharacterizeTinnitus.ExperimentsValidator
using SHA
import SearchLight.Validation: ModelValidator, ValidationRule

export Experiment

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

function hash_settings(settings::AbstractString)
    sha256(settings) |> bytes2hex
end

end
