module TrialsValidator

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

function is_unique(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    obj = findone(typeof(m); NamedTuple(field => getfield(m, field))...)
    if (obj !== nothing && !ispersisted(m))
        return ValidationResult(invalid, :is_unique, "already exists")
    end

    ValidationResult(valid)
end

function is_in_active_exp end

function is_pm_one(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    !(getfield(m, field) in [1, -1]) &&
        return ValidationResult(invalid, :is_pm_one, "should be ± one")

    return ValidationResult(valid)
end

function dbid_is_not_nothing(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
    isa(getfield(m, field), SearchLight.DbId) &&
        isa(getfield(m, field).value, Nothing) &&
        return ValidationResult(invalid, :dbid_is_not_nothing, "should not be nothing")

    ValidationResult(valid)
end

end
