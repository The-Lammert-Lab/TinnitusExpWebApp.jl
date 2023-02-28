module AssignTestUserExampleExperiments

using SearchLight
using ..Main.UserApp.Users
using ..Main.UserApp.Experiments
using ..Main.UserApp.UserExperiments

function up()
    exps = (findone(Experiment, name = "TestExperiment_1"), 
            findone(Experiment, name = "TestExperiment_2")
    )
    usr = findone(User, username = "testuser")

    if nothing in exps
        println("Check migration status and make sure `create example experiments` is up")
    else
        foreach(exps) do exp
            UserExperiment(;
                user_id = usr.id,
                experiment_name = exp.name,
                instance = 1,
                percent_complete = 0.0
            ) |> save!
        end
    end
end

function down()
    findone(UserExperiment, experiment_name = "TestExperiment_1") |> delete
    findone(UserExperiment, experiment_name = "TestExperiment_2") |> delete
end

end
