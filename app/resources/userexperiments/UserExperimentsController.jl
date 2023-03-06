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

function restart_exp()
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
    name = jsonpayload("name")
    instance = jsonpayload("instance")

    blocks = find(Block; 
                    experiment_name = name,
                    instance = instance,
                    user_id = current_user_id()
                )

    if !isempty(blocks)
        json(Dict(:msg => (:value => "Data has been collected already. Cannot remove this experiment.")))
    else
        findone(UserExperiment; 
                experiment_name = name,
                instance = instance,
                user_id = current_user_id()
                ) |> delete
        json(Dict(:msg => (:value => "Experiment $name, instance $instance has been removed.")))
    end                        
end

function home()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    visible_experiments = find(Experiment; visible = true)
    html(:userexperiments, :home; added_experiments, visible_experiments)
end

end
