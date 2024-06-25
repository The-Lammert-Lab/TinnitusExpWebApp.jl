module LoudnessMatching

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export Loudness

@kwdef mutable struct Loudness <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    freq::Float64 = 0
    LM::Union{Float64,Nothing} = nothing
end

# TODO: add validation rules


end
