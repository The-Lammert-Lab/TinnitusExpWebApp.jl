module ExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.TinnitusReconstructor
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Experiments
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using Genie.Exceptions
using GenieAuthentication
using GenieSession
using InteractiveUtils: subtypes
using NamedTupleTools
using SearchLight
using JSON3

const EXPERIMENT_FIELDS = Dict{Symbol,String}(
    :min_freq => "Minimum frequency (Hz)",
    :max_freq => "Maximum frequency (Hz)",
    :duration => "Duration (s)",
    :n_bins => "Number of bins",
    :min_bins => "Minimum number of bins",
    :max_bins => "Maximum number of bins",
    :Fs => "Playback frequency (Hz)",
    :stimgen_type => "Stimgen type",
    :n_trials => "Number of trials",
    :name => "Experiment name",
    :visible => "Visible"
)

const STIMGEN_MAPPINGS = Dict{String,DataType}(
    "UniformPrior" => UniformPrior,
    "GaussianPrior" => GaussianPrior,
)

"""
    _subtypes(type::Type)    

Collect all concrete subtypes. 

# References
- https://gist.github.com/Datseris/1b1aa1287041cab1b2dff306ddc4f899
"""
function _subtypes(type::Type)
    out = Any[]
    _subtypes!(out, type)
end

function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(T->_subtypes!(out, T), subtypes(type))
    end
    return out
end

function view_exp()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    ex = findone(Experiment; name = params(:name))
    if ex === nothing
        return Router.error(INTERNAL_ERROR, """Could not find an experiment with name "$(params(:name))".""", 
                            MIME"application/json")
    end

    # Get all user experiments for this experiment
    added_experiments = find(UserExperiment; experiment_name = params(:name))

    # Make a vector of dicts with data to display
    user_data = Vector{Dict}()
    cache = Dict{DbId, String}()
    for ae in added_experiments
        if ae.user_id in keys(cache)
            username = cache[ae.user_id]
        else
            username = findone(User; id = ae.user_id).username
            cache[ae.user_id] = username
        end
        push!(user_data, Dict(:username => username, :instance => ae.instance, :frac_complete => ae.frac_complete))
    end

    # Pre-process experiment fields
    exp_data = Dict()
    for field in fieldnames(typeof(ex))
        if field == :id
            continue
        elseif field == :stimgen_settings
            settings = JSON3.read(getproperty(ex, field))
            for setting in keys(settings)
                if setting in keys(EXPERIMENT_FIELDS)
                    exp_data[EXPERIMENT_FIELDS[setting]] = getproperty(settings, setting)
                else
                    exp_data[setting] = getproperty(settings, setting)
                end
            end
        else
            if field in keys(EXPERIMENT_FIELDS)
                exp_data[EXPERIMENT_FIELDS[field]] = getproperty(ex, field)
            else
                exp_data[field] = getproperty(ex, field)
            end
        end
    end

    json(Dict(:experiment_data => (:value => exp_data), :user_data => (:value => user_data)))
end

"""
    get_exp_fields()
    get_exp_fields(ex::E) where {E<:Experiment}

Returns Vector{NamedTuple} corresponding to each non-stimgen field in a generic or specific experiment.
    Each NamedTuple has `name`, `label`, `type`, and `value`.
"""
function get_exp_fields()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    ex = Experiment()
    fnames = fieldnames(typeof(ex))
    exclude = [:id, :stimgen_settings, :stimgen_type]
    exp_fields = Vector{NamedTuple}(undef, length(fnames)-length(exclude))
    ind = 0
    for field in fnames
        if !(field in exclude)
            ind += 1
            if typeof(getproperty(ex,field)) <: Real
                input_type = "number"
            elseif typeof(getproperty(ex,field)) <: AbstractString
                input_type = "text"
            end

            if !(field in keys(EXPERIMENT_FIELDS))
                lab = field
            else
                lab = EXPERIMENT_FIELDS[field]
            end

            exp_fields[ind] = (name = field, label = lab, type = input_type, value = "")
        end
    end
    return exp_fields
end

function get_exp_fields(ex::E) where {E<:Experiment}
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    fnames = fieldnames(typeof(ex))

    exclude = [:id, :stimgen_settings, :stimgen_type]
    exp_fields = Vector{NamedTuple}(undef, length(fnames)-length(exclude))
    ind = 0
    for field in fnames
        if !(field in exclude)
            ind += 1
            if typeof(getproperty(ex,field)) <: Real
                input_type = "number"
            elseif typeof(getproperty(ex,field)) <: AbstractString
                input_type = "text"
            end

            if !(field in keys(EXPERIMENT_FIELDS))
                lab = field
            else
                lab = EXPERIMENT_FIELDS[field]
            end

            exp_fields[ind] = (name = field, label = lab, type = input_type, value = getproperty(ex, field))
        end
    end
    return exp_fields
end

"""
    get_stimgen_fields(s::SG) where {SG<:Stimgen}

Returns Vector{NamedTuple} corresponding to each field in the stimgen struct `s`.
    Each NamedTuple has `name`, `label`, `type`, and `value`.
"""
function get_stimgen_fields(s::SG) where {SG<:Stimgen}
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    fnames = fieldnames(typeof(s))

    sg_fields = Vector{NamedTuple}(undef, length(fnames))
    for (ind, field) in enumerate(fnames)
        if typeof(getproperty(s,field)) <: Real
            input_type = "number"
        elseif typeof(getproperty(s,field)) <: AbstractString
            input_type = "text"
        end

        if !(field in keys(EXPERIMENT_FIELDS))
            lab = field
        else
            lab = EXPERIMENT_FIELDS[field]
        end

        sg_fields[ind] = (name = field, label = lab, type = input_type, value = getproperty(s, field))
    end
    return sg_fields
end

#########################

## PAGE FUNCTIONS ##

#########################

function admin()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    experiments = all(Experiment)
    users = find(User; is_admin = false)
    
    html(:experiments, :admin; users, experiments)
end

function manage()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    user_id = findone(User; username = params(:username)).id

    added_experiments = find(UserExperiment; user_id = user_id)
    experiments = all(Experiment)
    unstarted_experiments = [ex for ex in added_experiments if ex.frac_complete == 0]
    html(:experiments, :manage; added_experiments, visible_experiments, unstarted_experiments, user_id)
end

function create()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))
    
    full_types = _subtypes(Stimgen)
    stimgen_types = Vector{String}(undef, length(full_types))
    [stimgen_types[ind] = split.(type, '.')[end][end] for (ind, type) in enumerate(eachrow(string.(full_types)))]

    # Non-stimgen experiment fields
    exp_fields = get_exp_fields()
    stimgen_fields = nothing

    # html(:experiments, :create; default_stimgens, exp_fields)
    html(:experiments, :create; stimgen_types, exp_fields, stimgen_fields)
end

function get_stimgen()
    s = STIMGEN_MAPPINGS[params(:type)]()
    stimgen_fields = get_stimgen_fields(s);

    json(stimgen_fields)
end

end
