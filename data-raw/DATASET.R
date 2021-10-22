## code to prepare `DATASET` dataset goes here
conexion <- list(odbc::odbc(),
                Driver = "ODBC Driver 17 for SQL Server",
                 Server = "database.negox.com",
                 Database = "CIDFares2020_ABPVirtualTest",
                 UID = "CIDFares2020_CIDFares2020",
                 PWD = "CIDFares@BP2021",
                 Port = 1433)

usethis::use_data(conexion, overwrite = TRUE)
