module Experiments

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
using CharacterizeTinnitus.ExperimentsValidator
import SearchLight.Validation: ModelValidator, ValidationRule

export Experiment

@kwdef mutable struct Experiment <: AbstractModel
  id::DbId = DbId()
  stimgen_settings::String = ""
  stimgen_type::String = ""
  n_trials::Int = 0
  name::String = ""
  visible::Bool = true
end

SearchLight.Validation.validator(::Type{Experiment}) = ModelValidator([
    ValidationRule(:stimgen_settings, ExperimentsValidator.not_empty),
    ValidationRule(:stimgen_type, ExperimentsValidator.not_empty),
    ValidationRule(:n_trials, ExperimentsValidator.is_positive),
    ValidationRule(:n_trials, ExperimentsValidator.is_int),
    ValidationRule(:name, ExperimentsValidator.not_empty),
])

end
