module CreateExampleExperiments

using ..Main.UserApp.Experiments
using ..Main.UserApp.TinnitusReconstructor
using SearchLight
using JSON3
using SHA

function up()
    UP = UniformPrior()
    stimgen_settings = JSON3.write(UP)
    stimgen_type = split(string(Base.typename(typeof(UP)).wrapper), '.')[end]
    n_trials = 10

    Experiment(; 
        stimgen_settings = stimgen_settings,
        stimgen_type = stimgen_type,
        n_trials = n_trials,
        n_blocks = 2,
        n_trials_per_block = 5,
        name = "TestExperiment_1",
        visible = true,
    ) |> save!

    n_trials = 50

    Experiment(; 
        stimgen_settings = stimgen_settings,
        stimgen_type = stimgen_type,
        n_trials = n_trials,
        n_blocks = 5,
        n_trials_per_block = 10,
        name = "TestExperiment_2",
        visible = true,
    ) |> save!

end

function down()
    findone(Experiment, name = "TestExperiment_1") |> delete
    findone(Experiment, name = "TestExperiment_2") |> delete
end

end
