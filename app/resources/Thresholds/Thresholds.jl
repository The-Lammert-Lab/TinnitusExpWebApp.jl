module Thresholds

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export Threshold

@kwdef mutable struct Threshold <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    freq::Float64 = 0
    threshold::Union{Float64,Nothing} = nothing
end

# TODO: add validation rules


end
