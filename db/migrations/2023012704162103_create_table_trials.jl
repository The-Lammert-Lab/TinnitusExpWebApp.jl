module CreateTableTrials

import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:trials) do
        [
            pk()
            columns([:stimulus => :string, :response => :int])
        ]
    end
end

function down()
    drop_table(:trials)
end

end
