module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using SearchLight.Validation
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication

# TODO: Add error handling (no experiment or no trials)
function restart_exp()
    authenticated!()
    name = jsonpayload("name")
    instance = jsonpayload("instance")

    experiment = findone(UserExperiment; 
                         experiment_name = name,
                         instance = instance,
                         user_id = current_user_id()
                        )
                        
    trials = find(Trial; 
                    experiment_name = name,
                    instance = instance,
                    user_id = current_user_id()
                )

    experiment.frac_complete = 0.
    save(experiment) && delete.(trials)
end

function remove_exp()
    authenticated!()
    name = jsonpayload("name")
    instance = jsonpayload("instance")

    trials = find(Trial; 
                    experiment_name = name,
                    instance = instance,
                    user_id = current_user_id()
                )

    if !isempty(trials)
        return Router.error("Could not remove this experiment. Data has already been collected.", 
                            MIME"application/json", INTERNAL_ERROR)
    else
        findone(UserExperiment; 
                experiment_name = name,
                instance = instance,
                user_id = current_user_id()
                ) |> delete
        json(Dict(:status => (:value => "sucess")))
    end                        
end

function add_exp()
    authenticated!()
    name = jsonpayload("name")
    curr_user_exps = find(UserExperiment; experiment_name = name, user_id = current_user_id())
    if !isempty(curr_user_exps)
        new_instance = maximum(getproperty.(curr_user_exps, :instance)) + 1
    else
        new_instance = 1
    end
    ue = UserExperiment(; 
                    user_id = current_user_id(), 
                    experiment_name = name, 
                    instance = new_instance,
                    frac_complete = 0.
                )

    validator = validate(ue)
    if haserrors(validator)
        return redirect("/?error=$(errors_to_string(validator))")
    end

    save(ue)
end

function home()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    visible_experiments = find(Experiment; visible = true)
    unstarted_experiments = [ex for ex in added_experiments if ex.frac_complete == 0]
    html(:userexperiments, :home; added_experiments, visible_experiments, unstarted_experiments)
end

end
