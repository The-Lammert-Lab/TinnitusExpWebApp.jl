module CreateTableInoct

import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:inocts) do
        [
            pk()
            columns([
                :user_id => :int,
                :sound_a => :float,
                :sound_b => :float,
                :closer_sound => :float
            ])
        ]
    end
end

function down()
    drop_table(:inocts)
end

end
