#' Utiliza la función de imprimir nube para imprimir todos
#' las slides de las etapas inicial y final.
#'
#' @param bd (list) Lista de talbas provistas por leer_base.
#' @param etapa (int) Número de la etapa en la base de datos.
#'
#' @return (list) Lista de chuncks concatenados por "\n".
#' @export
#'
#' @import dplyr
#' @examples #notrun (slides_nubes(bd, etapa = 1))

slides_nubes <- function(bd, etapa, parametros, thm){

    preguntas <- bd$pregunta %>%
        filter(IdEtapa == etapa) %>%
        pull(IdPregunta)

    if(etapa == 5){
        preguntas <- preguntas[1]
    }
    out <- list()

    for (i in preguntas){
        a <- procesar_p_abierta(bd, pregunta = i, etapa = etapa, parametros = parametros)

        a1 <- a %>% purrr::pluck(1)
        a2 <- a %>% purrr::pluck(2)

        b1 <- glue::glue("p_{i} <- a1")
        b2 <- glue::glue("q_{i} <- a2")
        eval(parse(text = b1))
        eval(parse(text = b2))


        x1 <- glue::glue(
        "knitr::knit_expand(text = imprimir_nube(p_{i}, {i}, parametros))"
        )
        x2 <- glue::glue(
            "knitr::knit_expand(text = imprimir_tabla_nube(q_{i}, {i}))"
        )

        y1 <- eval(parse(text = x1))
        y2 <- eval(parse(text = x2))

        out <- append(out, y1) %>%
            append(y2)
    }

    knitr::knit(text = paste(out, collapse = '\n'))
}

slides_bigramas <- function(bd, etapa, parametros, thm){
    preguntas <- bd$pregunta %>%
        filter(IdEtapa == etapa) %>%
        pull(IdPregunta)

    if(etapa == 5){
        preguntas <- preguntas[1]
    }
    out <- list()

    for (i in preguntas){
        a <- procesar_bigramas( bd, pregunta = i, etapa = etapa)

        b1 <- glue::glue("p_{i} <- a")
        eval(parse(text = b1))


        x1 <- glue::glue(
            "knitr::knit_expand(text = imprimir_bigramas(p_{i}, {i}, parametros))"
        )


        y1 <- eval(parse(text = x1))


        out <- append(out, y1)
    }

    knitr::knit(text = paste(out, collapse = '\n'))
}
#' Esta función es utilizada para crear los chuncks correspondientes
#' a la etapa 2.
#'
#' @param bd (list) Lista de talbas provistas por leer_base.
#' @param top_p (int) El top n de preguntas de cada tema.
#' @param top_r (int) El top n de respuestas de cada tema.
#' @param otro  (char) La forma de como se escribe el otro
#'  tema, regularmente será "Otro".
#'
#' @return (list) Una lista de chuncks correspondientes a cada pregunta.
#' @export
#'
#' @import dplyr
#' @examples

slides_etapa_2 <- function(bd, top_p, top_r, otro = "Otro", parametros, thm){
    # Slide brecha
    p_4 <- procesar_brecha(bd, otro = "Otro")
    out1 <- knitr::knit_expand(text = imprimir_brecha(p_4, parametros, thm))

    # Slides p clave
    brecha <- procesar_r_tema(
        bd, top_p = top_p, top_r = top_r, otro = otro)

    out2 <- purrr::imap(brecha, ~{

        a1 <- knitr::knit_expand(
            text = sprintf("\n \n # %s\n", .y))
        a1.1 <- knitr::knit_expand(
            text = "\n --- \n .pull-left[")

        a1.3 <- knitr::knit_expand(text = sprintf(
        "\n Las <b> palabras  </b>más representativas son: \n\n * %s \n \n]\n",
        graficar_claves(.x$p_clave)))

        a2 <- knitr::knit_expand(text = ".pull-right[")
        a3 <- knitr::knit_expand(text = sprintf(
            "\n Las <b> respuestas </b>más representativas son: \n\n * %s",
            paste(.x$respuesta,collapse = "\n \n * ")))
        a4 <- knitr::knit_expand(text = "\n] \n---")
        paste(a1,a1.1,a1.3, a2, a3, a4, collapse = '\n')
    })

    # Slide 3: Cumplimiento e Importancia
    g_1 <- bd %>% procesar_numerica("Calificacion")
    out3 <- knitr::knit_expand(
        text = imprimir_numerica_p(g_1, tipo = "Cumplimiento", 1, parametros, thm)
    )

    # Slide Importancia
    g_2 <- bd %>% procesar_numerica("Orden")
    out4 <- knitr::knit_expand(
        text = imprimir_numerica_p(g_2, tipo = "Importancia", 2, parametros, thm)
    )

    # Analisis conjunto
    # p_7 <- procesar_juntos(bd)
    # out5 <- knitr::knit_expand(text = imprimir_juntos(p_7, parametros))

    p_7.1 <- procesar_juntos_promedio(bd)
    out5.1 <- knitr::knit_expand(text = imprimir_juntos_promedio(p_7.1, parametros))

    # Gráfica de calculo de brecha
    brecha2 <- calcular_brecha(bd, corte = corte, parametros = parametros)
    hc <- brecha2 %>% graficar_nbrecha(parametros)

    out6 <- purrr::imap(hc, ~{
        r <- glue::glue('r densidad_{gsub("#","",.y)}')
        r <- paste("{", r, "}", sep="")
        sp <- "```"

        a1 <- knitr::knit_expand(text = glue::glue("\n\n # Temas con brecha .{.y}[⬤]")) # título
        a2 <- knitr::knit_expand(text = glue::glue("\n\n --- \n\n {sp}{r} \n\n")) # empezar chunk
        a3 <- knitr::knit_expand(text = sprintf("\n\n print(hc[['%s']])", .y)) # gráfica
        a4 <- knitr::knit_expand(text = glue::glue("\n\n {sp} \n\n ---")) # terminar chunk
        paste(a1, a2, a3, a4, collapse = ' ')

    })

    # out6.2 <- knitr::knit_expand(
    #     text = imprimir_calc_brecha(brecha2, grafica = TRUE))

    # Tabla de calculo de brecha
    tabla_df <- generar_tabla(brecha2, parametros = parametros)

    out7 <- knitr::knit_expand(
        text = imprimir_calc_brecha(tabla_df, grafica = FALSE))

    # Juntarlos
    out <- list()

    out <- out %>%
        append(out1) %>%
        append(out2) %>%
        append(out4) %>%
        append(out3) %>%
        # append(out5) %>%
        append(out5.1) %>%
        append(out6) %>%
        # append(out6.2) %>%
        append(out7)

    knitr::knit(text = paste(out, collapse = '\n'))
}
