primario <- "#001c50"
inverso <- "#ff1895"
cortes <- c(0,5,9,13,17,25)*20^2
sm_vf <- "#264653"
sm_vc <- "#2a9d8f"
sm_a <- "#e9c46a"
sm_rc <- "#f4a261"
sm_rf <- "#e76f51"

pool<- pool::dbPool(odbc::odbc(),
                    Driver = "ODBC Driver 17 for SQL Server",
                    Server = "database.negox.com",
                    Database = "CIDFares2020_ABPVirtualTest",
                    UID = "CIDFares2020_CIDFares2020",
                    PWD = "CIDFares@BP2021",
                    Port = 1433)

bd <- leer_base(pool, id_sesion = "Todo")

procesar_p_abierta(bd, pregunta = 1, etapa = 1)
procesar_brecha(bd)
procesar_r_tema(bd, top_p = 5, top_r = 2, otro = "Otro")

procesar_numerica(bd, "Calificacion")
