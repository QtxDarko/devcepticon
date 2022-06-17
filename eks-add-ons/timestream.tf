resource "aws_timestreamwrite_database" "db_prometheus" {
  count = var.enable_timestream ? 1 : 0

  database_name = "db-prometheus"
}

resource "aws_timestreamwrite_table" "tbl_prometheus" {
  count = var.enable_timestream ? 1 : 0

  database_name = aws_timestreamwrite_database.db_prometheus[0].database_name
  table_name    = "tbl-prometheus"

  retention_properties {
    magnetic_store_retention_period_in_days = 30
    memory_store_retention_period_in_hours  = 24
  }
}
