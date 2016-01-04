Sequel.migration do
  up do
    run "create index series_register_id_doy_idx on series(register_id, date_part('doy', time))"
  end

  down do
    alter_table(:series) do
      drop_index name: 'series_register_id_doy_idx'
    end
  end
end
