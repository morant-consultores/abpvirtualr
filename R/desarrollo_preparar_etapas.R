#' Utiliza la función de imprimir nube para imprimir todos
#' las slides de las etapas inicial y final.
#'
#' @param bd (list) Lista de talbas provistas por leer_base.
#' @param etapa (int) Número de la etapa en la base de datos.
#' @param parametros (list) Parámetros de configuración del reporte.
#' @param thm Tema de highcharter generado por tema_high.
#' @param url (char) URL de la API del resumidor (ver [resumir_respuestas()]).
#'  Default `getOption("abpvirtual.api_url")`, igual que
#'  `resumir_respuestas()` — antes no tenía default y el skeleton del
#'  paquete la llamaba sin pasarlo, causando
#'  `argument "url" is missing, with no default` en cuanto se llegaba a un
#'  resumen de IA.
#' @return (list) Lista de chuncks concatenados por "\n".
#' @export
#'
#' @import dplyr
#' @examples #notrun (slides_nubes(bd, etapa = 1))

slides_nubes <- function(
    bd,
    etapa,
    parametros,
    thm,
    url = getOption(
        "abpvirtual.api_url",
        "https://abp-flask-api.azurewebsites.net/api/v1/resumen_pregunta"
    )
) {
    preguntas <- bd$pregunta %>%
        filter(IdEtapa == etapa, RegistroActivo, Orden != 3) %>%
        pull(IdPregunta)

    if (etapa == 5) {
        preguntas <- preguntas[1]
    }
    out <- list()

    for (i in preguntas) {
        tokens <- procesar_p_abierta(
            bd,
            pregunta = i,
            etapa = etapa,
            parametros = parametros
        ) %>% purrr::pluck(1)

        aux <- bd$respuesta |>
            filter(IdPregunta == i) |>
            left_join(bd$pregunta, by = "IdPregunta") |>
            distinct(IdRespuesta, Respuesta, Nombre)

        lista <- split(aux$Respuesta, aux$Nombre)
        tema <- names(lista)
        respuestas_tema <- lista[[1]]

        # graficar_nube() dentro del chunk de imprimir_nube() se evalua al
        # knitear `out` completo (más abajo); assign() deja p_{i} disponible
        # en ese momento sin parsear texto con eval(parse()).
        assign(paste0("p_", i), tokens)

        y1 <- knitr::knit_expand(text = imprimir_nube(tokens, i, parametros))
        y2 <- knitr::knit_expand(text = imprimir_gt(respuestas_tema, tema, i, url))

        out <- append(out, y1) %>%
            append(y2)
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
#' @param parametros (list) Parámetros de configuración del reporte.
#' @param thm Tema de highcharter generado por tema_high.
#' @param url (char) URL de la API del resumidor (ver [resumir_respuestas()]).
#'  Default `getOption("abpvirtual.api_url")`, igual que
#'  `resumir_respuestas()` — antes no tenía default (ver detalle en
#'  [slides_nubes()]).
#'
#' @return (list) Una lista de chuncks correspondientes a cada pregunta.
#' @export
#'
#' @import dplyr
#' @examples

slides_etapa_2 <- function(
    bd,
    top_p,
    top_r,
    otro = "Otro",
    parametros,
    thm,
    url = getOption(
        "abpvirtual.api_url",
        "https://abp-flask-api.azurewebsites.net/api/v1/resumen_pregunta"
    )
) {
    # Slide brecha
    p_4 <- procesar_brecha(bd, otro = "Otro")
    out1 <- knitr::knit_expand(text = imprimir_brecha(p_4, parametros, thm))

    # Tabla resumen -----------------------------------------------------------
    aux <- bd$respuesta |>
        filter(IdEtapa == 2) |>
        left_join(bd$pregunta, by = "IdPregunta") |>
        distinct(IdPregunta, IdRespuesta, Respuesta, Nombre)

    out2 <- list()

    for (i in unique(aux$IdPregunta)) {
        aux_i <- aux |> filter(IdPregunta == i)
        lista <- split(aux_i$Respuesta, aux_i$Nombre)

        tema <- names(lista)
        respuestas_tema <- lista[[1]]

        out2 <- append(
            out2,
            knitr::knit_expand(text = imprimir_gt(respuestas_tema, tema, i, url))
        )
    }

    # Slide 3: Cumplimiento e Importancia
    g_1 <- bd %>%
        procesar_numerica("Calificacion")
    out3 <- knitr::knit_expand(
        text = imprimir_numerica_p(
            g_1,
            tipo = "Cumplimiento",
            1,
            parametros,
            thm
        )
    )

    # Slide Importancia
    g_2 <- bd %>% procesar_numerica("Orden")
    out4 <- knitr::knit_expand(
        text = imprimir_numerica_p(
            g_2,
            tipo = "Importancia",
            2,
            parametros,
            thm
        )
    )

    # Analisis conjunto
    p_7 <- procesar_juntos(bd)
    out5 <- knitr::knit_expand(text = imprimir_juntos(p_7, parametros))

    p_7.1 <- procesar_juntos_promedio(bd)
    out5.1 <- knitr::knit_expand(
        text = imprimir_juntos_promedio(p_7.1, parametros)
    )

    # Gráfica de calculo de brecha
    brecha2 <- calcular_brecha(bd, corte = corte, parametros = parametros)
    hc <- brecha2 %>% graficar_nbrecha(parametros)

    out6 <- purrr::imap(
        hc,
        ~ {
            r <- glue::glue('r densidad_{gsub("#","",.y)}')
            r <- paste("{", r, "}", sep = "")
            sp <- "```"

            a1 <- knitr::knit_expand(
                text = glue::glue("\n\n # Temas con brecha .{.y}[⬤]")
            ) # título
            a2 <- knitr::knit_expand(
                text = glue::glue("\n\n --- \n\n {sp}{r} \n\n")
            ) # empezar chunk
            a3 <- knitr::knit_expand(
                text = sprintf("\n\n print(hc[['%s']])", .y)
            ) # gráfica
            a4 <- knitr::knit_expand(text = glue::glue("\n\n {sp} \n\n ---")) # terminar chunk
            paste(a1, a2, a3, a4, collapse = ' ')
        }
    )

    # out6.2 <- knitr::knit_expand(
    #     text = imprimir_calc_brecha(brecha2, grafica = TRUE))

    # Tabla de calculo de brecha
    tabla_df <- generar_tabla(brecha2, parametros = parametros)

    out7 <- knitr::knit_expand(
        text = imprimir_calc_brecha(tabla_df, grafica = FALSE)
    )

    # Juntarlos
    out <- list()

    out <- out %>%
        append(out1) %>%
        append(out2) %>%
        append(out4) %>%
        append(out3) %>%
        append(out5) %>%
        append(out5.1) %>%
        append(out6) %>%
        # append(out6.2) %>%
        append(out7)

    knitr::knit(text = paste(out, collapse = '\n'))
}
