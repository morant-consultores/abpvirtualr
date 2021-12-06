## code to prepare `DATASET` dataset goes here
conexion <- list(Driver = "ODBC Driver 17 for SQL Server",
                 Server = "database.negox.com",
                 Database = "viajeporchiapas_abpvirtual",
                 UID = "viajeporchiapas_abp_user",
                 PWD = "CIDFares@BP2021",
                 Port = 1433)

usethis::use_data(conexion, overwrite = TRUE)
