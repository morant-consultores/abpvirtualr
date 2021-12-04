devtools::load_all()

parametros <- list(
    primario = "#2A3D6E",
    primario_claro = "#304E83",
    primario_obscuro = "#232B58",
    inverso = "#4C97C8",
    inverso_claro = "#88B9CF",
    cortes = seq(0,10000,length.out = 6),
    # cortes = c(0,4,7.5,11,16,25)*20^2,
    sm_vf = "#6A994E",
    sm_vc = "#A7C957",
    sm_a = "#F9C74F",
    sm_rc = "#D65A1F",
    sm_rf = "#B31D1F",
    familia = "Poppins",
    gris = "#343a40",
    gris_claro = "#ced4da",
    etiquetas = "14px"
)

thm <- tema_high(font = parametros$familia, color = "black", size = "15px")
bd <- leer_base( id_sesion = 3169)


# Etapa 1 -----------------------------------------------------------------

procesar_p_abierta(bd, pregunta = 2, etapa = 1,parametros = parametros) %>%
    purrr::pluck(1) %>% graficar_nube(parametros = parametros)

procesar_p_abierta(bd, pregunta = 2, etapa = 1,parametros = parametros, quitar_altisonantes = F) %>%
    purrr::pluck(2) %>%
    generar_tabla_nube()
# Etapa 2 -----------------------------------------------------------------

procesar_brecha(bd) %>% graficar_brecha(parametros = parametros, thm = thm)

procesar_r_tema(bd, top_p = 5, top_r = 3, otro = "Otro", quitar_altisonantes = T)

procesar_numerica(bd = bd, tipo = "Orden") %>% graficar_numerica(tipo = "point_range",
                                                                parametros = parametros, thm = thm)
procesar_numerica(bd = bd, tipo = "Calificacion") %>% graficar_numerica(tipo = "point_range",
                                                                       parametros = parametros, thm = thm)

procesar_juntos_promedio(bd) %>% graficar_juntos_promedio(parametros = parametros)

calcular_brecha(bd, corte = corte, parametros = parametros) %>% graficar_nbrecha(parametros = parametros)

calcular_brecha(bd, corte = corte, parametros = parametros) %>% generar_tabla(parametros = parametros)

# Etapa 3 -----------------------------------------------------------------

procesar_p_abierta(bd, pregunta = 6, etapa = 5, parametros = parametros) %>%
    purrr::pluck(1) %>% graficar_nube(parametros = parametros)

