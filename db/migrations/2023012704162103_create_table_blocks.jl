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
                :stimgen => :string,
                :min_freq => :float,
                :max_freq => :float,
                :duration => :float,
                :n_trials => :int,
                :Fs => :float,
                :n_bins => :int,
                :min_bins => :int,
                :max_bins => :int,
            ])
        ]
    end

    add_indices(:blocks, :stimgen, :min_freq, :max_freq,
        :duration, :n_trials, :Fs, :n_bins, :min_bins, :max_bins)
end

function down()
    drop_table(:blocks)
end

end
