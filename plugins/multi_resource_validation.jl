"""
Extends validators for those that require the use of multiple modules.

"""

using ..Main.UserApp.Experiments
using ..Main.UserApp.UserExperiments
using SearchLight, SearchLight.Validation
import ..Main.UserApp.UserExperimentsValidator: is_experiment
import ..Main.UserApp.TrialsValidator: is_in_active_exp

export is_experiment
export is_in_active_exp

"""
    is_experiment(field::Symbol, m::T)::ValidationResult where {T<:SearchLight.AbstractModel}

Check if field is a valid experiment name by checking existing experiments
"""
function is_experiment(field::Symbol, m::T)::ValidationResult where {T<:SearchLight.AbstractModel}
  ex = findone(Experiment; name = getfield(m, field))
  if (ex === nothing)
      return ValidationResult(invalid, :is_experiment, "is not an existing experiment")
  end

  return ValidationResult(valid)
end

"""
    is_in_active_exp(field::Symbol, m::T)::ValidationResult where {T<:SearchLight.AbstractModel}

Check if field is part of an active experiment by checking experiments added to given user.
"""
function is_in_active_exp(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  ue = findone(UserExperiment; 
                  NamedTuple(field => getfield(m, field))..., 
                  experiment_name = getfield(m, :experiment_name), 
                  user_id = getfield(m, :user_id)
              )

  if ue === nothing
      return ValidationResult(invalid, :is_active_instance_of_exp, "does not correspond to active instance of experiment")
  end

  return ValidationResult(valid)
end