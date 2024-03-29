"""
Small example functions to do various operations.
    Mostly a reference file. 
"""

"""
    stimgen_from_params(stimgen::S; kwargs...) where {S<:AbstractString}

Returns a stimgen struct with keyword arguments from stringified name.
"""
# function stimgen_from_params(stimgen::S; kwargs...) where {S<:AbstractString}
#     stimgen_args = "("
#     for key in keys(kwargs)
#         name = string(key)
#         value = string(kwargs[key])
#         if stimgen_args == "("
#             stimgen_args = string(stimgen_args, name, "=", value)
#         else
#             stimgen_args = string(stimgen_args, ",", name, "=", value)
#         end
#     end
#     stimgen_args = string(stimgen_args, ")")
#     f = eval(Meta.parse(string("x ->", stimgen, stimgen_args)))
#     return Base.invokelatest(f, ())
# end

# function reset_exp(name::S) where {S<:AbstractString}
#     user = findone(User; username = "testuser")
#     ue = findone(UserExperiment; experiment_name = name, user_id = user.id)
#     ue.frac_complete = 0
#     save(ue)
#     blocks = find(Trial; experiment_name = name, user_id = user.id)
#     delete.(blocks)
# end


"""
    choose_n_trials(x::I) where {I<:Integer}

Find the number closest to IDEAL_BLOCK_SIZE that is a factor of x.
"""
# function choose_n_trials(x::I) where {I<:Integer}
#     if x <= MAX_BLOCK_SIZE
#         return x
#     elseif isprime(x)
#         x += 1
#     end

#     all_prod = prod.(combinations(factor(Vector, x)))
#     n_trials = argmin(ai -> abs(ai - IDEAL_BLOCK_SIZE), all_prod)

#     return n_trials
# end


"""
Get stimgen type as string
"""
# function sg_name()
#     # Get just the stimgen name
#     # NOTE: This method can probably be considerably improved.
#     stimgen_types = Vector{String}(undef, length(full_types))
#     [
#         stimgen_types[ind] = split.(type, '.')[end][end] for
#         (ind, type) in enumerate(eachrow(string.(full_types)))
#     ]
# end

""" Get parametric type name as string without parameters """
# string(Base.typename(typeof(UP)).wrapper)
### OR 
# split(string(Base.typename(typeof(UP)).wrapper), '.')[end]
