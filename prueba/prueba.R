library(tidyverse)
library(dbplyr)
library(highcharter)


# Correr ----------------------------------------------------------------


# Necesitas correr esto
primario <- "#001c50"
primario_claro <- "#40557C"
inverso <- "#DE4797"
inverso_claro <- "#E675B1"
cortes <- c(0,4,8,12,16,25)*20^2
sm_vf <- "#264653"
sm_vc <- "#2a9d8f"
sm_a <- "#e9c46a"
sm_rc <- "#f4a261"
sm_rf <- "#e76f51"
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

data(conexion)


# Funciones ------------------------------------------------------------

thm <- tema_high(font = "Poppins", color = "black", size = "15px")
# Hacer que esta función lea un archivo yaml
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
