module Users

using SearchLight, SearchLight.Validation
using ..Main.UserApp.UsersValidator
using GenieAuthentication.SHA

export User

Base.@kwdef mutable struct User <: AbstractModel
    ### FIELDS
    id::DbId = DbId()
    username::String = ""
    password::String = ""
    is_admin::Bool = false
end

Validation.validator(u::Type{User}) = ModelValidator([
    ValidationRule(:username, UsersValidator.not_empty),
    ValidationRule(:username, UsersValidator.unique),
])

function hash_password(password::AbstractString)
    sha256(password) |> bytes2hex
end

end
