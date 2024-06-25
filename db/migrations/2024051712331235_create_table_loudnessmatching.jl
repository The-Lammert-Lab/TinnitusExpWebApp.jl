module CreateTableLoudnessmatching

import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:loudness) do
        [
            pk()
            columns([
                :user_id => :int,
                :freq => :float,
                :LM => :float,
            ])
        ]
    end
end

function down()
    drop_table(:loudness)
end

end
