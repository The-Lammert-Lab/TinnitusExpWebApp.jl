module OctaveDetermination

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export OctDetermination

@kwdef mutable struct OctDetermination <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    sound_a::Float64 = 0.0
    sound_b::Float64 = 0.0
    closer_sound::Float64 = 0.0
end

# TODO: add validation rules


end
