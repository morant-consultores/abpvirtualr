#' Crea el chunk de xaringan para poner la nube de palabras.
#'
#' @param df (tibble) Marco de datos que proviene de
#' procesar_p_abierta que contiene la pregunta.
#' @param i (int) Índice relacionado con la etapa y pregunta.
#'
#' @return (char) El chunk de xaringan en cadena de caracteres.
#' @export
#'
#' @import dplyr
#' @examples #notrun (imprimir_nube(p_1, 1))

imprimir_nube <- function(df, i){
    t <- df %>%
        pull(Pregunta) %>%
        unique()
    r <- glue::glue("r {t}, eval=requireNamespace('highcharter', quietly=TRUE)")
    r <- paste("{", r, "}", sep="")
    sp <- "```"

    char <- glue::glue("\n\n  ## {t} \n\n --- \n\n {sp}{r} \n\n  graficar_nube(p_{i})  \n\n {sp} \n\n ---")

    return(char)
}


#' Crea el chunk de xaringan para poner el treemap de brecha.
#'
#' @param df (tibble) Marco de datos que proviene de
#'  procesar_brecha contiene la pregunta.
#'
#' @return (char) Crea el chunk de xaringan para poner el
#'  treemap de brecha.
#' @export
#' @examples #notrun (imprimir_brecha(p_4))

imprimir_brecha <- function(df){
    t1 <- df %>% pull(pregunta) %>%
        unique()

    r <- glue::glue("r etapa_2-2")
    r <- paste("{", r, "}", sep="")
    sp <- "```"

    char <- glue::glue(
        " \n\n # {t1} \n\n --- \n\n {sp}{r} \n\n graficar_brecha(p_4, interactivo = TRUE, inverso, primario, thm) \n\n {sp} \n\n ---")


    return(char)
}


#' Crea el chunk de xaringan para poner las gráficas de
#'  histograma y error bars
#'
#' @param df (tibble) Un marco de datos que proviene de la
#'  función procesar_numerica
#' @param tipo (char) "Importancia" o "Cumplimiento"
#' @param i (int) El índice de la variable a graficar.
#'
#' @return (char) El chunk de xaringan en cadena de caracteres.
#' @export
#'
#' @examples #notrun ( imprimir_numerica_p(g_1, tipo = "Cumplimiento", 1) )

imprimir_numerica_p <- function(df, tipo, i){

    r <- glue::glue("r {tipo}")
    r <- paste("{", r, "}", sep="")
    sp <- "```"

    char <- glue::glue(paste(
        "\n\n # {tipo}",
        "\n\n --- \n\n",
        "{sp}{r} \n\n ",
        "graficar_numerica(g_{i}, tipo = 'point_range', interactivo = TRUE, thm)",
        "\n\n {sp} \n\n ---", sep = " ")
        )

    return(char)
}



#' Crea el chunk de xaringan para poner la gráfica de
#'  cumplimiento vs importancia.
#'
#' @param df (tibble) Un marco de datos proveniente de la función
#' procesar_juntos.
#'
#' @return (char) Crea el chunk de xaringan para poner la
#' gráfica de importancia vs cumplimiento.
#' @export
#'
#' @examples #notrun (imprimir_juntos(p_7))
#'

imprimir_juntos <- function(df){

    t1 <- "Análisis Conjunto"

    r <- glue::glue("r etapa_3-4")
    r <- paste("{", r, "}", sep="")
    sp <- "```"

    char <- glue::glue(paste(
    "\n\n # {t1} ",
    "\n\n --- \n\n",
    "{sp}{r}",
    "\n\n graficar_juntos(p_7,interactivo = FALSE,  corte = cortes, thm) \n\n",
    "{sp} \n\n ---", sep = " "))

    return(char)
}



#' Crea el chunk de xaringan para poner la gráfica del
#' cálculo de la brecha.
#'
#' @param bd (tibble) Un marco de datos que proviene de la función
#' calcular_brecha.
#' @param grafica (logical) TRUE si se requiere la gráfica o FALSE
#'  si se requiere la tabla.
#'
#' @return
#' @export
#'

#' @examples

imprimir_calc_brecha <- function(bd, grafica){

    r <- glue::glue("r {grafica}")
    r <- paste("{", r, "}", sep="")
    sp <- "```"

    if(grafica){
        char <- glue::glue(paste(
            "\n\n # Gráfica del cálculo de Brecha",
            "\n\n --- \n\n {sp}{r} \n\n",
            "graficar_nbrecha(brecha2, thm)",
            "\n\n {sp} \n\n ---", sep = " ")
        )

    }else{
        char <- glue::glue(paste(
            "\n\n # Tabla del cálculo de Brecha",
            "\n\n --- \n\n {sp}{r} \n\n",
            "tabla_df",
            "\n\n {sp} \n\n ---", sep = " ")
        )

    }

    return(char)
}
