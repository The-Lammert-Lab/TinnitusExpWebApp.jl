module CreateTableExperiments

import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:experiments) do
        [
            pk()
            columns([
                :stimgen_settings => :string,
                :stimgen_type => :string,
                :n_trials => :int,
                :name => :string,
                :target_sound => :string,
                :threshold_determination_mode => :int,
                :loudness_matching => :int,
                :pitch_matching => :int,
                :settings_hash => :string,
            ])
        ]
    end

    add_indices(:experiments, :name, :settings_hash)
end

function down()
    drop_table(:experiments)
end

end
