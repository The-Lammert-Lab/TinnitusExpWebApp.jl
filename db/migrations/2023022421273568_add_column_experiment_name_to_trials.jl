module AddColumnExperimentNameToTrials

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:trials, [:experiment_name => :string])
    add_index(:trials, :experiment_name)
end

function down()
    remove_index(:trials, :experiment_name)

    remove_columns(:trials, [:experiment_name])
end

end
