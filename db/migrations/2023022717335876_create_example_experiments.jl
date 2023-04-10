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

    Experiment(;
        stimgen_settings = stimgen_settings,
        stimgen_type = stimgen_type,
        n_trials = 10,
        name = "Test Experiment 1",
    ) |> save!

    Experiment(;
        stimgen_settings = stimgen_settings,
        stimgen_type = stimgen_type,
        n_trials = 50,
        name = "TestExperiment_2",
    ) |> save!

end

function down()
    findone(Experiment; name = "Test Experiment 1") |> delete
    findone(Experiment; name = "Test Experiment 2") |> delete
end

end
