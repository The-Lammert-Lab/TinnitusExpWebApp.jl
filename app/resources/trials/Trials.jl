module Trials

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
using CharacterizeTinnitus.TrialsValidator
import SearchLight.Validation: ModelValidator, ValidationRule

export Trial

@kwdef mutable struct Trial <: AbstractModel
    id::DbId = DbId()
    stimulus::String = ""
    response::Int = 0
    user_id::DbId = DbId()
    experiment_name::String = ""
    instance::Int = 0
end

SearchLight.Validation.validator(::Type{Trial}) = ModelValidator([
    ValidationRule(:stimulus, TrialsValidator.not_empty),
    ValidationRule(:response, TrialsValidator.is_pm_one),
    ValidationRule(:user_id, TrialsValidator.dbid_is_not_nothing),
    ValidationRule(:experiment_name, TrialsValidator.not_empty),
    ValidationRule(:instance, TrialsValidator.is_in_active_exp),
])


end
