module LoudnessMatching

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export Loudness

@kwdef mutable struct Loudness <: AbstractModel
    id::DbId = DbId()
    user_id::Int = DbId()
    name::String = ""
    instance::Int = 0
    freq::Float64 = 0
    lm::Float64 = NaN
end

# TODO: add validation rules


end
