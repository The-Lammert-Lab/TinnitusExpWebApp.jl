module CreateTableBlocks

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:blocks) do
        [
            pk()
            columns([
                :stim_matrix => :string,
                :responses => :string,
                :number => :int
            ])
        ]
    end
end

function down()
    drop_table(:blocks)
end

end
