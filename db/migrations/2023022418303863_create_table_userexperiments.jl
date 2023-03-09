module CreateTableUserExperiments

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:userexperiments) do
    [
      pk()
      column(:instance, :int)
      column(:frac_complete, :float)
    ]
  end

  add_index(:userexperiments, :instance)
end

function down()
  drop_table(:userexperiments)
end

end
