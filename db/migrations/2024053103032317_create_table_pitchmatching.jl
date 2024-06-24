module CreateTablePitchmatching

import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:pitchs) do
        [
            pk()
            columns([
                :user_id => :int,
                :sound_a => :float,
                :sound_b => :float,
                :PM => :float,
            ])
        ]
    end
end

function down()
    drop_table(:pitchs)
end

end
