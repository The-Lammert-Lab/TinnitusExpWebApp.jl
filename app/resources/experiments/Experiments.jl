module Experiments

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Experiment

@kwdef mutable struct Experiment <: AbstractModel
  id::DbId = DbId()
  stimgen_settings::String = ""
  stimgen_type::String = ""
  n_trials::Integer = 1
  n_blocks::Integer = 1
  n_trials_per_block::Integer = 1
  name::String = ""
  visible::Bool = true
end

end
