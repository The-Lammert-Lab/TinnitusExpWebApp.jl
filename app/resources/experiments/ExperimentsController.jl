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

function admin()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    experiments = all(Experiment)
    users = find(User; is_admin = false)
    
    html(:experiments, :admin; users, experiments)
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

function manage()
    authenticated!() 
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    user_id = findone(User; username = params(:username)).id

    added_experiments = find(UserExperiment; user_id = user_id)
    visible_experiments = find(Experiment; visible = true)
    unstarted_experiments = [ex for ex in added_experiments if ex.frac_complete == 0]
    html(:experiments, :manage; added_experiments, visible_experiments, unstarted_experiments, user_id)
end

end