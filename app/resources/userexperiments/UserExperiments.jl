module UserExperiments

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export UserExperiment

@kwdef mutable struct UserExperiment <: AbstractModel
  id::DbId = DbId()
  user_id::DbId = DbId()
  experiment_name::String = ""
  instance::Integer = 1
  percent_complete::AbstractFloat = 0.0
end

# TODO: Add instance is unique validation

end
