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

    t1 <- paste(t, i, 1, sep ="")
    r1 <- glue::glue("r {t1}, eval=requireNamespace('highcharter', quietly=TRUE)")
    r1 <- paste("{", r1, "}", sep="")

    nube <- glue::glue("```{r1} \n graficar_nube(p_{i}) \n ```")

    # Sólo nube
    #char <- glue::glue("\n\n  ## {t} \n\n --- \n\n {nube} \n\n ---")

    # if(nrow(df)>0){
    # t2 <- paste(t, i, 2, sep="")
    # r2 <- glue::glue("r {t2}")
    # r2 <- paste("{", r2, "}", sep="")
    #
    # tabla <- glue::glue("```{r2}\n generar_tabla_nube(q_{i}) \n``` ")
    #
    # char<- paste(glue::glue("\n \n ##{t}\n \n ---"),
    # glue::glue(".pull-left[ \n {nube} \n]"),
    # glue::glue(".pull-right[ \n {tabla} \n]"),
    # "---", sep = "\n")
    # }else{
    # char <- glue::glue("\n\n##{t}\n\n --- \n\n {nube} \n\n ---")
    # }

    # La nube

    nube <- glue::glue("\n\n  # {t} \n\n --- \n\n {nube} \n\n ---")
    char <- nube


    return(char)
}

#' Title
#'
#' @param df (Tibble) El segundo elemento que retorna la función procesar_p_brecha
#' @param i (int) ídice donde se encuentra el slide
#'
#' @return (chunk) de código xaringan
#' @export
#'
#' @examples  #notrun (imprimir_tabla_nube(q_1, 1))

imprimir_tabla_nube <- function(df, i){

    t <- df %>%
        pull(Pregunta) %>%
        unique()

    t2 <- paste(t, i, 2, sep="")
    r2 <- glue::glue("r {t2}")
    r2 <- paste("{", r2, "}", sep="")

    tabla <- glue::glue("```{r2} \n generar_tabla_nube(q_{i}) \n ```")

    if(nrow(df)>0){
        char <- glue::glue("\n\n  # {t} \n\n --- \n\n {tabla} \n\n ---")

    }else{
        char <- glue::glue("\n\n")
    }

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

    r <- glue::glue("r densidad_{grafica}")
    r2 <- glue::glue("r barras")
    r <- paste("{", r, "}", sep="")
    r2 <- paste("{", r2, "}", sep="")
    sp <- "```"

    if(grafica){
        char1 <- glue::glue(paste(
            "\n\n # Gráfica del cálculo de Brecha",
            "\n\n --- \n\n {sp}{r} \n\n",
            "graficar_nbrecha(brecha2)",
            "\n\n {sp} \n\n ---", sep = " ")
        )
        char2 <- glue::glue(paste(
            "\n\n # Gráfica del cálculo de Brecha",
            "\n\n --- \n\n {sp}{r2} \n\n",
            "graficar_nbrecha(brecha2,densidad = F)",
            "\n\n {sp} \n\n ---", sep = " ")
        )

        char <- char1 %>% append(char2)
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
