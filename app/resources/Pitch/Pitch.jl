module PitchMatching

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export Pitch

@kwdef mutable struct Pitch <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    name::String
    instance::Int
    sound_a::Float64 = 0.0
    sound_b::Float64 = 0.0
    pm::Union{Float64,Nothing} = NaN
end

# TODO: add validation rules


end
