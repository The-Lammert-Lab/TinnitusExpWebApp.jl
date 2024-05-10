module Ratings

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
import SearchLight.Validation: ModelValidator, ValidationRule

export Rating

@kwdef mutable struct Rating <: AbstractModel
    id::DbId = DbId()
    user_id::DbId = DbId()
    experiment_name::String = ""
    instance::Int = 0
    # rating columns
    # TODO: look into how to save nulls in the database.
    white_noise::Int = -1
    standard_resynth::Int = -1
    adjusted_resynth::Int = -1

end

# TODO: add validation rules


end
