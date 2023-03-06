module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using GenieAuthentication

function reset_exp()
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

function home()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    visible_experiments = find(Experiment; visible = true)
    html(:userexperiments, :home; added_experiments, visible_experiments)
end

end
