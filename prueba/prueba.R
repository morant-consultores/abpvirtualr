library(tidyverse)
library(dbplyr)
library(highcharter)
library(ggpmthemes)
library(showtext)

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
procesar_p_abierta(bd, pregunta = 1, etapa = 1) %>%
    graficar_nube()

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
