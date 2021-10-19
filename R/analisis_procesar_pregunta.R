#' @title Limpia, tokeniza y obtiene las frecuencias de palabras a
#' una tabla con variables de texto
#'
#' @param bd (list) La lista con las tablas necesarias provistas por
#'  la función leer_base.
#' @param pregunta (int) Número de pregunta de la etapa.
#' @param etapa (int) Número de la etapa.
#'
#' @return (tibble) Tabla con las palabras, frecuencias y colores asignados.
#' @export
#' @import dplyr
#' @examples #notrun (procesar_p_abierta(bd, pregunta = 1, etapa = 1))

procesar_p_abierta <- function(bd, pregunta, etapa){

    df <- bd$respuesta %>%
        left_join(bd$pregunta) %>%
        filter(IdPregunta == pregunta, IdEtapa == etapa)

    tokens <- df %>%
        tidytext::unnest_tokens(
        output = palabra, input = Respuesta, drop = FALSE) %>%
        group_by(palabra) %>%
        summarise(n = n(),
        completa = stringr::str_c(Respuesta, collapse= "<br>")) %>%
        ungroup()

    stop_words <- tibble::tibble(palabra = tm::stopwords("spanish"))

    tokens_clean <- tokens %>%
        anti_join(stop_words)

    nums <- tokens_clean %>%
        filter(stringr::str_detect(palabra, "^[0-9]")) %>%
        select(palabra) %>%
        unique()

    tokens_clean <- tokens_clean %>%
        anti_join(nums, by = "palabra") %>%
        mutate(colores = case_when(
            n <= quantile(n,probs=.75) ~ inverso,
            n >= quantile(n,probs=.75) & n<=quantile(n,probs=.90) ~ "#485375",
            n >= quantile(n,probs=.90) ~ "#001c50"),
            Pregunta = bd$pregunta %>%
            filter(IdPregunta == pregunta, IdEtapa == etapa) %>%
            pull(Nombre)
        )

    return(tokens_clean)
}

#' Procesamiento de la pregunta brecha, palabras clave por tema de manera
#' global
#'
#' @param bd (list) La lista con las tablas necesarias provistas por
#'  la función leer_base
#'
#' @return (tibble) Tabla con las columnas tema, p_clave (palabras clave),
#'  pregunta (pregunta brecha)
#' @export
#' @import dplyr
#' @examples #notrun (procesar_r_tema(bd))

procesar_brecha <- function(bd){

    junta <- bd$respuesta_cat %>%
        left_join(bd$respuesta %>%
        filter(IdEtapa == 2) %>%
        select(IdRespuesta, IdPregunta, Respuesta)) %>%
        left_join(bd$categoria %>%
        filter(EsDefault) %>%
        select(IdCategoria, Nombre))

    corpus <- junta %>%
        quanteda::corpus(text = "Respuesta")

    toks_news <- quanteda::tokens(corpus, remove_punct = TRUE,
        remove_symbols = T,remove_url = T,
        remove_separators = T) %>%
        quanteda::tokens_group(groups = Nombre)

    dfmat_news <- quanteda::dfm(toks_news)

    p_clave <- bd$categoria %>%
        filter(EsDefault) %>%
        pull(Nombre) %>%
        purrr::map(~{
            palabras <- quanteda.textstats::textstat_keyness(
                dfmat_news,
                target = .x) %>%
                as_tibble %>%
                head(3) %>%
                pull(1) %>%
                paste(collapse = ", ")

            tibble::tibble(tema = .x,p_clave = palabras)
        }) %>% do.call(rbind,.)

    pregunta <- bd$pregunta %>%
        filter(IdEtapa == 2) %>%
        pull(Nombre) %>%
        unique()

    res <- bd$respuesta_cat %>%
        count(IdCategoria,IdRespuesta) %>%
        group_by(IdCategoria) %>%
        summarise(resp = n(), per = sum(n)) %>%
        mutate(
            pct_r = resp/n_distinct(bd$respuesta_cat$IdRespuesta),
            pct = scales::percent(pct_r,1)) %>%
        left_join(bd$categoria %>%
            select(IdCategoria,Nombre)) %>%
        semi_join(bd$categoria %>%
            filter(EsDefault)) %>%
        left_join(p_clave %>%
            rename(Nombre = tema))


    pregunta <- tibble::tibble(
        pregunta = rep(pregunta, nrow(res))
        )

    res <- bind_cols(res, pregunta)

    return(res)
}

#' Procesa las palabras clave y las respuestas por cada uno de los temas de
#' manera particular
#'
#' @param bd (list) La lista con las tablas necesarias provistas por
#'  la función leer_base.
#' @param top_p (int) El top n de preguntas de cada tema.
#' @param top_r (int) El top n de respuestas de cada tema.
#' @param otro  (char) La forma de como se escribe el otro tema,
#'  regularmente será "Otro".
#'
#' @return (list) Una lista de listas nombradas por tema, las cuales su primer elemento es un vector con el top_r de respuestas de ese tema, y el segundo elemento es un tibble con sus palabras clave y su medida G2.
#' @export
#' @import dplyr
#' @examples #notrun(procesar_r_tema(bd, top_p = 5, top_r = 2, otro = "Otro"))


procesar_r_tema <- function(bd, top_p, top_r, otro){

    junta <- bd$respuesta_cat %>%
        left_join(bd$respuesta %>%
        select(IdRespuesta,Respuesta)) %>%
        left_join(bd$categoria %>%
        filter(EsDefault) %>%
        select(IdCategoria,Nombre))

    corpus <- junta %>%
        quanteda::corpus(text = "Respuesta")

    toks_news <- quanteda::tokens(corpus, remove_punct = TRUE,
        remove_symbols = T, remove_url = T,remove_separators = T) %>%
        quanteda::tokens_group(groups = Nombre)

    dfmat_news <- quanteda::dfm(toks_news)

    respuestas <- junta %>%
        count(Respuesta, Nombre,sort = T) %>%
        left_join(junta %>%
        count(Respuesta,name = "tot")) %>%
        na.omit() %>%
        mutate(pct = n/tot) %>%
        group_by(Nombre) %>%
        arrange(desc(pct)) %>%
        slice(1:top_r) %>%
        ungroup %>%
        mutate(
        Nombre = forcats::fct_relevel(Nombre,otro, after = Inf)) %>%
        split(.$Nombre) %>%
        purrr::imap(~{
            resp <- paste0("<b>(",
                .x %>%
                pull(pct) %>%
                scales::percent(accuracy = 1),")</b>") %>%
                paste(.x %>% pull(Respuesta))

            p_clave <- quanteda.textstats::textstat_keyness(
                dfmat_news, target = .y,measure = "lr" ) %>%
                arrange(desc(G2)) %>%
                slice(1:top_p)

            list(respuesta = resp,
                 p_clave = p_clave)
        })

    return(respuestas)
}

#' Procesa la importancia y cumplimiento de cierta sesión por medio
#' de la mediana.
#'
#' @param bd (list) La lista con las tablas necesarias provistas por
#'  la función leer_base.
#' @param tipo (char) Puede ser "orden_cat" o bien "calif_cat"
#' dependiendo si es importancia y cumplimiento respectivamente.
#'
#' @return (list) Una lista con dos tibbles uno denominado histograma
#' y otro llamado point range para su posterior graficación.
#' @export
#'
#' @import dplyr
#' @examples #notrun (procesar_numerica(bd, "Calificacion"))

procesar_numerica <- function(bd, tipo){

    tipobd <- switch(tipo,
    Orden = "orden_cat",
    Calificacion = "calif_cat"
    )

    histograma <- bd %>%
        purrr::pluck(tipobd) %>%
        left_join(bd$categoria) %>%
        mutate(Categoria = Nombre)

    point_range <- histograma %>%
        group_by(Categoria) %>%
        summarise(
        ggplot2::median_hilow(!!sym(tipo), conf.int = .5)
        )

    res <- list(histograma = histograma,
                point_range = point_range)
}

#' Procesa la importancia y el cumplimiento juntos por
#' medio de sus medianas.
#'
#' @param bd (list) La lista con las tablas necesarias provistas por
#'  la función leer_base.
#'
#' @return (tibble) Un tibble con Importancia relaacionada con
#' Cumplimiento por medio de la mediana.
#' @export
#' @impor dplyr
#'
#' @examples

procesar_juntos <- function(bd){

    res <- bd$orden_cat %>%
        select(IdCategoria,IdUsuario,Orden) %>%
        left_join(bd$calif_cat %>%
        select(IdCategoria,IdUsuario,Calificacion)) %>%
        left_join(bd$categoria) %>%
        group_by(Nombre) %>%
        summarise(importancia = median(Orden),
        cumplimiento = median(Calificacion))

    return(res)
}
