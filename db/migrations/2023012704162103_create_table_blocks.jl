module CreateTableBlocks

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:blocks) do
        [
            pk()
            columns([
                :stim_matrix => :string,
                :responses => :string,
                :n_blocks => :int,
                :n_trials_per_block => :int,
                :n_trials => :int,
                :stimgen => :string,
                :stimgen_type => :string,
                :stimgen_hash => :string,
            ])
        ]
    end

    add_indices(:blocks, :stimgen_hash, :n_trials)
end

function down()
    drop_table(:blocks)
end

end
