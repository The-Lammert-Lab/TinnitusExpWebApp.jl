module UserExperimentsValidator

using SearchLight, SearchLight.Validation

function not_empty(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    isempty(getfield(m, field)) &&
        return ValidationResult(invalid, :not_empty, "should not be empty")

    ValidationResult(valid)
end

function is_int(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    isa(getfield(m, field), Int) ||
        return ValidationResult(invalid, :is_int, "should be an int")

    ValidationResult(valid)
end

function unique_for_usr_and_exp(
    field::Symbol,
    m::T,
)::ValidationResult where {T<:AbstractModel}
    obj = findone(
        typeof(m);
        NamedTuple(field => getfield(m, field))...,
        experiment_name = getfield(m, :experiment_name),
        user_id = getfield(m, :user_id),
    )
    if (obj !== nothing && !ispersisted(m))
        return ValidationResult(
            invalid,
            :unique_for_usr_and_exp,
            "already exists for this experiment",
        )
    end

    return ValidationResult(valid)
end

function is_experiment end

function is_nonnegative(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    getfield(m, field) >= 0 ||
        return ValidationResult(invalid, :is_nonnegative, "must be greater than zero")

    ValidationResult(valid)
end

function is_positive(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    getfield(m, field) > 0 ||
        return ValidationResult(invalid, :is_nonnegative, "must be greater than zero")

    ValidationResult(valid)
end

function dbid_is_not_nothing(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    isa(getfield(m, field), SearchLight.DbId) &&
        isa(getfield(m, field).value, Nothing) &&
        return ValidationResult(invalid, :dbid_is_not_nothing, "should not be nothing")

    ValidationResult(valid)
end

end
