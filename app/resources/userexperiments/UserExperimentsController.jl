module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication

# TODO: Add error handling (no experiment or no blocks)
function restart_exp()
    authenticated!()
    name = jsonpayload("name")
    instance = jsonpayload("instance")

    experiment = findone(UserExperiment; 
                         experiment_name = name,
                         instance = instance,
                         user_id = current_user_id()
                        )
                        
    blocks = find(Block; 
                    experiment_name = name,
                    instance = instance,
                    user_id = current_user_id()
                )

    experiment.percent_complete = 0
    save(experiment) && delete.(blocks)
end

function remove_exp()
    authenticated!()
    name = jsonpayload("name")
    instance = jsonpayload("instance")

    blocks = find(Block; 
                    experiment_name = name,
                    instance = instance,
                    user_id = current_user_id()
                )

    if !isempty(blocks)
        json(Dict(:msg => (:value => "Data has been collected already. Cannot remove this experiment."),
                  :status => (:value => "error")))
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
    UserExperiment(; 
                    user_id = current_user_id(), 
                    experiment_name = name, 
                    instance = new_instance,
                    percent_complete = 0.0
                ) |> save
end

function home()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    visible_experiments = find(Experiment; visible = true)
    ongoing_experiments = [ex for ex in added_experiments if ex.percent_complete < 100]
    html(:userexperiments, :home; added_experiments, visible_experiments, ongoing_experiments)
end

end
