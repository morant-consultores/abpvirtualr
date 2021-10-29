library(tidyverse)
library(dbplyr)
library(highcharter)
library(ggpmthemes)
library(showtext)
library(spatstat)
devtools::load_all(here::here())
# Correr ----------------------------------------------------------------

# Necesitas correr esto
primario <- "#232B58"
primario_claro <- "#304E83"
inverso <- "#4C97C8"
inverso_claro <- "#88B9CF"
cortes <- c(0,4,8,12,16,25)*20^2
sm_vf <- "#1C6130"
sm_vc <- "#55A630"
sm_a <- "#F5BC38"
sm_rc <- "#BA181B"
sm_rf <- "#660708"
familia <- "Poppins"
gris <- "#343a40"
gris_claro <- "#ced4da"
etiquetas = "14px"

xaringanthemer::style_duo_accent(
    primary_color = primario,
    secondary_color = "#485375",
    inverse_header_color = inverso,
    header_color = "#001c50",
    inverse_background_color = "#485375",
    header_font_google = xaringanthemer::google_font(
        "https://fonts.googleapis.com/css2?family=Poppins:wght@400;700"),
    text_font_google = xaringanthemer::google_font(
        "https://fonts.googleapis.com/css2?family=Lato:wght@400;700")
)

options(highcharter.google_fonts = TRUE)
# options(highcharter.tooltip.formatter = JS("function () {
#     var s='<div style='padding:5px;'><b>' + xName +' </b></div> '+
#         '<div style='max-height:50px ;min-width: 170px; overflow-y:auto;overflow-x:hidden '>'+
#     '<table style='width: 150px'>';
#     +......'</table></div>'
#     return s
# }"))

data(conexion)

# Funciones ------------------------------------------------------------

thm <- tema_high(font = "Poppins", color = "black", size = "15px")
bd <- leer_base(id_sesion = 3156)

# 1 - Nube de palabras
procesar_p_abierta(bd, pregunta = 1, etapa = 1) %>% pluck(1) %>%
    graficar_nube()

procesar_p_abierta(bd, pregunta = 1, etapa = 1) %>%
    generar_tabla_nube()

# 2 - Treemap brecha
procesar_brecha(bd, otro = "Otro") %>%
    graficar_brecha(interactivo = TRUE, inverso, primario, thm)

# 3 - P_clave pero no es gráfica

# 4 - Cumplimiento
procesar_numerica(bd, "Calificacion") %>%
    graficar_numerica(tipo = 'point_range', interactivo = TRUE, thm)

# 5 - Importancia
procesar_numerica(bd, "Orden") %>%
    graficar_numerica(tipo = 'point_range', interactivo = TRUE, thm)

# Analisis conjunto
procesar_juntos(bd) %>%
    graficar_juntos(interactivo = FALSE,  corte = cortes, thm)

# Gráfica de calculo de brecha
calcular_brecha(bd) %>%
    graficar_nbrecha(thm)

# Tabla de calculo de brecha
calcular_brecha(bd) %>%
    generar_tabla()

# sandbox -----------------------------------------------------------------
library(spatstat)
library(scales)
library(ggridges)
corte <- seq(0,10000,length.out = 6)
juntos <- bd$orden_cat %>% select(usuario = IdUsuario,Orden,IdCategoria) %>%
    left_join(
        bd$calif_cat %>% select(usuario = IdUsuario,Calificacion,IdCategoria)
    ) %>% na.omit() %>% left_join(bd$categoria) %>% rename(cat = IdCategoria) %>%
    mutate(brecha = Orden*(100-Calificacion))

juntos %>% ggplot(aes(x = Calificacion, y = Orden)) + geom_density2d_filled() +
    facet_wrap(~Nombre)

ggplot() +
    geom_density2d_filled(data = juntos,aes(x = Calificacion, y = Orden), alpha = .7, show.legend = F) +
    geom_function(fun = ~purrr::map_dbl(.x, ~ min(corte[5]/(100-.x),100)), color = sm_rc, linetype = "dashed") +
    geom_function(fun = ~purrr::map_dbl(.x, ~ min(corte[4]/(100-.x),100)), color = sm_a, linetype = "dashed") +
    geom_function(fun = ~purrr::map_dbl(.x, ~ min(corte[3]/(100-.x),100)), color = sm_vc, linetype = "dashed") +
    geom_function(fun = ~purrr::map_dbl(.x, ~ min(corte[2]/(100-.x),100)), color = sm_vf, linetype = "dashed") +
    xlim(0,100) +
    # coord_fixed() +
    facet_wrap(vars(Nombre))

brecha_prob_1 <- juntos %>% split(.$Nombre) %>% imap(~{
    acum <- CDF(density(.x$brecha, from = 0, to = 10000))
    tibble(inf= corte,sup = lead(corte), color = c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf,"")) %>%
        slice(-6) %>% mutate(
            prob = acum(sup-.0000001) - acum(inf),
            Nombre = .y
        )
}) %>% bind_rows() %>% group_by(Nombre)

juntos %>% ggplot(aes(y = brecha, x = Nombre, fill = Nombre)) + geom_violin(guide = F) +
    scale_fill_manual(values = brecha_prob_1$color)


ggplot(juntos, aes(x = brecha, y = Nombre,fill = ..x..)) +
    geom_density_ridges_gradient(scale = 2, rel_min_height = 0.001, gradient_lwd = 1, alpha = .7) +
    # scale_x_continuous(expand = c(0.01, 0)) +
    # scale_y_discrete(expand = c(0.01, 0)) +
    scale_fill_gradientn(colours = c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf),
                         values = corte/10000) +
    # scale_fill_viridis(name = "Temp. [F]", option = "C") +
    # labs(title = 'Temperatures in Lincoln NE',
    #      subtitle = 'Mean temperatures (Fahrenheit) by month for 2016\nData: Original CSV from the Weather Underground') +
    theme_ridges(font_size = 13, grid = TRUE) +
    theme(axis.title.y = element_blank())



