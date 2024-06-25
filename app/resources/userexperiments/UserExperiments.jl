module UserExperiments

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
using CharacterizeTinnitus.UserExperimentsValidator
import SearchLight.Validation: ModelValidator, ValidationRule

export UserExperiment

@kwdef mutable struct UserExperiment <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    experiment_name::String = ""
    instance::Integer = 1
    trials_complete::Integer = 0
    mult::Float64 = 0.01
    binrange::Int = 60
    white_noise::String = ""
    standard_resynth::String = ""
    adjusted_resynth::String = ""
end

SearchLight.Validation.validator(::Type{UserExperiment}) = ModelValidator([
    ValidationRule(:user_id, UserExperimentsValidator.dbid_is_not_nothing),
    ValidationRule(:experiment_name, UserExperimentsValidator.is_experiment),
    ValidationRule(:instance, UserExperimentsValidator.is_positive),
    ValidationRule(:instance, UserExperimentsValidator.is_int),
    ValidationRule(:instance, UserExperimentsValidator.unique_for_usr_and_exp),
    ValidationRule(:trials_complete, UserExperimentsValidator.is_nonnegative),
    ValidationRule(:trials_complete, UserExperimentsValidator.is_int),
])

end
