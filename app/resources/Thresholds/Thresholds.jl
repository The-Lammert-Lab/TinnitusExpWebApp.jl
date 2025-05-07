module Thresholds

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule
using CharacterizeTinnitus.ThresholdValidator

export Threshold

@kwdef mutable struct Threshold <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    name::String = ""
    instance::Int = 0
    freq::Float64 = 0
    threshold::Float64 = NaN # there must be a better default, nothing gives an error. asked on discord and no response:(
end
# not done but start...
#= SearchLight.Validation.validator(::Type{Threshold}) = ModelValidator([
    ValidationRule(:id, ThresholdValidator.dbid_is_not_nothing),
    ValidationRule(:user_id, ThresholdValidator.dbid_is_not_nothing),
    ValidationRule(:name, ThresholdValidator.not_empty),
    ValidationRule(:freq, ThresholdValidator.not_empty),
    ValidationRule(:instance, ThresholdValidator.is_in_active_exp),
]) =#

end
