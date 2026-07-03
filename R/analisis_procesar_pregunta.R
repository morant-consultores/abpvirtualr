#' @title Limpia, tokeniza y obtiene las frecuencias de palabras a
#' una tabla con variables de texto
#'
#' @param bd (list) La lista con las tablas necesarias
#'  provistas por la función leer_base.
#' @param pregunta (int) Número de pregunta de la etapa.
#' @param etapa (int) Número de la etapa.
#' @param cuantiles (numeric) Vector de 2 cuantiles (0-1, creciente) que
#'  separan los 3 colores de la nube según la frecuencia de cada palabra:
#'  `<= cuantiles[1]` usa `parametros$inverso`, entre ambos usa
#'  `parametros$primario_claro`, `> cuantiles[2]` usa
#'  `parametros$primario_obscuro`. Default `c(.75, .90)`.
#'
#' @return (list) Lista de dataframes uno con una tabla con las palabras, frecuencias y colores asignados y otro con las respuestas.
#' @export
#' @import dplyr
#' @examples #notrun (procesar_p_abierta(bd, pregunta = 1, etapa = 1))

procesar_p_abierta <- function(bd, pregunta, etapa, parametros, quitar_altisonantes = T, cuantiles = c(.75, .90)){

    df <- bd$respuesta %>%
        left_join(bd$pregunta) %>%
        filter(IdPregunta == pregunta, IdEtapa == etapa)



    stop_words <- tibble::tibble(palabra = c(stopwords::stopwords("es")))

    aux <- df %>%
        tidytext::unnest_tokens(
            output = palabra, input = Respuesta, drop = FALSE)
    aux <- if(quitar_altisonantes){
        altisonantes <- obtener_altisonantes()
        quitar <- aux %>% semi_join(altisonantes %>% mutate(palabra = tolower(palabra))) %>% distinct(Respuesta)
        aux %>% anti_join(quitar)
    } else{
        aux
    }


    tokens_clean <- aux %>%
        anti_join(stop_words) %>%
        group_by(palabra) %>%
        mutate(num = paste0(row_number(),") ")) %>%
        summarise(
            n = n(),
            completa = tolower(stringr::str_c(
                num, Respuesta, collapse= "\n"))) %>%
        ungroup()


    nums <- tokens_clean %>%
        filter(stringr::str_detect(palabra, "^[0-9]")) %>%
        select(palabra) %>%
        unique()

    tokens_clean <- tokens_clean %>%
        anti_join(nums, by = "palabra") %>%
        mutate(colores = case_when(
            n<=quantile(n,probs=cuantiles[1])~ parametros$inverso,
            n>quantile(n,probs=cuantiles[1]) & n<=quantile(n,probs=cuantiles[2])~parametros$primario_claro,
            n>quantile(n,probs=cuantiles[2])~ parametros$primario_obscuro),
            Pregunta = bd$pregunta %>%
                filter(IdPregunta == pregunta, IdEtapa == etapa) %>%
                pull(Nombre)
        )

    respuestas <- df %>% select(Respuesta) %>%
        mutate(Pregunta = bd$pregunta %>%
                   filter(IdPregunta == pregunta, IdEtapa == etapa) %>%
                   pull(Nombre))
    if(quitar_altisonantes){
        respuestas <- respuestas %>% anti_join(quitar)
    }

    respuestas <- respuestas %>% left_join(
        aux %>% group_by(palabra) %>% mutate(n = n()) %>%
            select(palabra, n,Respuesta) %>% ungroup %>%
            count(Respuesta, wt = n)
    ) %>% arrange(desc(n))

    res <- list(tokens_clean, respuestas)

    return(res)
}

#' Procesamiento de la pregunta brecha, palabras clave por tema de manera
#' global
#'
#' @param bd (list) La lista con las tablas necesarias
#'  provistas por la función leer_base.
#' @param otro (char) La forma de como se escribe el otro tema,
#'  regularmente será "Otro".
#' @return (tibble) Tabla con las columnas tema, p_clave (palabras clave),
#'  pregunta (pregunta brecha)
#' @export
#' @examples #notrun (procesar_r_tema(bd))

procesar_brecha <- function(bd,  otro = "Otro", quitar_altisonantes = T){
    junta <- bd$respuesta_cat %>%
        left_join(bd$respuesta %>%
                      filter(IdEtapa == 2) %>%
                      select(IdRespuesta, IdPregunta, Respuesta)) %>%
        left_join(bd$categoria %>%
                      filter(EsDefault) %>%
                      select(IdCategoria, Nombre)) %>%
        tidyr::replace_na(list(Nombre = otro))

    sw <- if(quitar_altisonantes){
        altisonantes <- obtener_altisonantes()
        stopwords::stopwords("es") %>% append(altisonantes %>% mutate(palabra = tolower(palabra)) %>% pull(palabra))
    } else{
        stopwords::stopwords("es")
    }

    dfmat_news <- junta %>%
        quanteda::corpus(text = "Respuesta") %>%
        quanteda::tokens(
            remove_punct = TRUE, remove_symbols = T,
            remove_url = T, remove_separators = T) %>%
        quanteda::tokens_remove(sw) %>%
        quanteda::tokens_group(groups = Nombre) %>%
        quanteda::dfm()

    p_clave <- junta$Nombre %>%
        unique %>%
        purrr::map(~{
            palabras <- quanteda.textstats::textstat_keyness(
                dfmat_news, target = .x) %>%
                as_tibble %>%
                head(3) %>%
                pull(1) %>%
                paste(collapse = ", ")

            tibble::tibble(tema = .x,p_clave = palabras)
        }) %>% dplyr::bind_rows()

    if (nrow(p_clave) == 0) {
        # Sin categorías/respuestas (ej. etapa sin datos aún): tipar la
        # tabla vacía en vez de dejar que rename()/left_join() truenen.
        p_clave <- tibble::tibble(tema = character(), p_clave = character())
    }

    pregunta <- bd$pregunta %>%
        filter(IdEtapa == 2) %>%
        pull(Nombre) %>%
        unique()

    res <- junta %>%
        group_by(Respuesta, Nombre) %>%
        summarise(n=n()) %>%
        mutate(pct = n/sum(n)) %>%
        group_by(Nombre) %>%
        summarise(
            pct_r = sum(pct)/n_distinct(
                bd$respuesta_cat$IdRespuesta)) %>%
        mutate(
            pct = scales::percent(pct_r,1)
        ) %>%
        left_join(p_clave %>%
                      rename(Nombre = tema))


    pregunta <- tibble::tibble(pregunta = rep(pregunta, nrow(res)))

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


procesar_r_tema <- function(bd, top_p, top_r, otro = "Otro", quitar_altisonantes = T){

    junta <- bd$respuesta_cat %>%
        left_join(bd$respuesta %>%
                      select(IdRespuesta, Respuesta)) %>%
        left_join(bd$categoria %>%
                      filter(EsDefault) %>%
                      select(IdCategoria,Nombre)) %>%
        tidyr::replace_na(list(Nombre = otro))

    sw <- if(quitar_altisonantes){
        altisonantes <- obtener_altisonantes() %>% mutate(palabra = tolower(palabra))
        stopwords::stopwords("es") %>% append(altisonantes %>% pull(palabra))
    } else{
        stopwords::stopwords("es")
    }

    dfmat_news <- junta %>%
        quanteda::corpus(text = "Respuesta") %>%
        quanteda::tokens(
            remove_punct = TRUE, remove_symbols = T,
            remove_url = T, remove_separators = T) %>%
        quanteda::tokens_remove(sw) %>%
        quanteda::tokens_group(groups = Nombre) %>%
        quanteda::dfm()

    if(quitar_altisonantes){
        aux <- junta %>%
            tidytext::unnest_tokens(
                output = palabra, input = Respuesta, drop = F)
        quitar <- aux %>% semi_join(altisonantes) %>% distinct(Respuesta)
        junta <- junta %>% anti_join(quitar)
    }

    respuestas <- junta %>%
        group_by(Respuesta,Nombre) %>%
        summarise(n=n()) %>%
        mutate(pct = n/sum(n)) %>%
        group_by(Nombre) %>%
        mutate(
            pct_r =sum(pct)/n_distinct(
                bd$respuesta_cat$IdRespuesta)) %>%
        arrange(desc(pct)) %>%
        slice(1:top_r) %>%
        ungroup %>%
        filter(pct_r >= .1) %>%
        mutate(
            Nombre = forcats::fct_reorder(Nombre,-pct_r)
        ) %>%
        split(.$Nombre) %>%
        purrr::imap(~{
            resp <- paste0("<b>(",
                           .x %>% pull(pct) %>%
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
#' @param bd (list) La lista con las tablas necesarias
#'  provistas por la función leer_base.
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
            ggplot2::mean_se(!!sym(tipo))
        ) %>% mutate(y2 = base::round(y),
                     ymin2 = base::round(ymin),
                     ymax2 = base::round(ymax)
        )

    res <- list(histograma = histograma,
                point_range = point_range)
    return(res)
}

procesar_juntos_promedio <- function(bd){
    juntos <- procesar_juntos(bd)

    res <- juntos %>%
        group_by(Nombre) %>%
        summarise(importancia = base::round(base::mean(Orden)),
                  cumplimiento = base::round(base::mean(Calificacion)))

    return(res)
}
#' Procesa la importancia y el cumplimiento juntos por
#' medio de sus medianas.
#'
#' @param bd (list) La lista con las tablas necesarias
#' provistas por la función leer_base.
#'
#' @return (list) Un tibble con Importancia relaacionada con
#' Cumplimiento por medio de la mediana.
#' @export
#'
#' @examples #notrun(procesar_juntos(bd))

procesar_juntos <- function(bd){

    juntos <- bd$orden_cat %>%
        select(usuario = IdUsuario,Orden,IdCategoria) %>%
        left_join(
            bd$calif_cat %>%
                select(usuario = IdUsuario,Calificacion,IdCategoria)
        )

    incompletos <- sum(!stats::complete.cases(juntos))
    if (incompletos > 0) {
        message(glue::glue(
            "procesar_juntos(): se descartaron {incompletos} pares usuario+",
            "categoria con Orden o Calificacion en NA (par incompleto)."
        ))
    }

    juntos <- juntos %>%
        na.omit() %>%
        left_join(bd$categoria) %>%
        rename(cat = IdCategoria) %>%
        mutate(brecha = Orden*(100-Calificacion))


    return(juntos)
}

#' Obtiene el o los códigos de los colores más repetidos.
#'
#' @param codes (char) Recibe un carácter que es código
#' de un color.
#'
#' @return (char) Regresa el o los códigos más repetidos.
#' @export
#'
#' @examples #notrun (moda(color))

moda <- function(codes){

    cual <- which.max(table(codes))
    if(sum(cual == table(codes))>1){
        NA
    } else{
        names(cual)
    }
}

#' @rdname moda
#' @description `mode()` es un alias retro-compatible de [moda()];
#' hacía *shadowing* de `base::mode()` y se renombró para evitar bugs
#' silenciosos si algún código dependía del `mode()` real de R tras cargar
#' el paquete. Se eliminará en una versión futura.
#' @export
mode <- function(codes){
    .Deprecated("moda")
    moda(codes)
}

#' Asigna colores dependiendo del cálulo de la brecha.
#'
#' @param brecha (dbl) Columna con el cálculo de la brecha.
#' @param corte  Los cortes que se van a asignar para
#' la pregunta brecha
#' @param colores (vector) Vector de colores asginados a
#' esos cortes
#'
#' @return (char) Código del color asignado al corte.
#' @export
#'
#' @examples #notrun (corte(brecha))

corte <- function(brecha, parametros){

    as.character(cut(brecha, parametros$cortes, labels = c(parametros$sm_vf,parametros$sm_vc,parametros$sm_a, parametros$sm_rc,parametros$sm_rf),
                     include.lowest = T))
}

#' Realiza el marco de datos del cálculo de la brecha
#' con sus colores.
#'
#' @param bd (list) La lista con las tablas necesarias
#' provistas por la función leer_base.
#'
#' @return (tibble) Marco de datos con la importancia y cumplimiento,
#' así como el cálculo de la brecha por medias con los colores asignados.
#' @export
#'
#' @import dplyr
#' @examples #notrun (calcular_brecha(bd))

calcular_brecha <- function(bd, corte, parametros){

    juntos <- procesar_juntos(bd)

    res <- juntos %>% split(.$Nombre) %>% purrr::imap(~{
        tibble(inf= parametros$cortes,
               sup = lead(parametros$cortes), color = c(parametros$sm_vf,parametros$sm_vc,parametros$sm_a,parametros$sm_rc,parametros$sm_rf,""),
               nombre_color = c("vf","vc","a","rc","rf","")) %>%
            na.omit() %>%
            mutate(
                Nombre = .y,
                brecha = base::mean(.x$brecha),
                semaforo = corte(brecha, parametros),
                cumplimiento = base::round(base::mean(.x$Calificacion)),
                importancia = base::round(base::mean(.x$Orden)),
                brecha_pct = brecha/10000
            )
    }) %>% bind_rows()

    if (nrow(res) == 0) {
        # Sin usuarios/categorías con par Orden+Calificacion completo (ej.
        # sesión recién abierta): tipar la tabla vacía en vez de que
        # bind_rows(list()) regrese 0 columnas y group_by(Nombre) truene.
        res <- tibble(
            inf = double(), sup = double(), color = character(),
            nombre_color = character(), Nombre = character(),
            brecha = double(), semaforo = character(),
            cumplimiento = double(), importancia = double(),
            brecha_pct = double()
        )
    }
    res <- res %>% group_by(Nombre)

    return(list(juntos, res))
}


#' A partir de la bd de respuesta, genera una base de datos con bigramas
#'
#' @param bd (list) La lista con las tablas necesarias
#'  provistas por la función leer_base.
#' @param pregunta (int) Número de pregunta de la etapa.
#' @param etapa (int) Número de la etapa.
#' @param p (numeric) Percentil (0-1) de frecuencia sobre el que se quedan los
#'  bigramas (`n > quantile(n, probs = p)`), antes de recortar al top 30.
#'  Default `.7`.
#'
#' @return (tibble) bigramas (`palabra1`, `palabra2`) con su frecuencia `n`.
#' @export
#'
#' @examples #notrun (procesar_bigramas(bd, pregunta = 1, etapa = 1, parametros))
procesar_bigramas <- function(bd, pregunta, etapa, parametros, quitar_altisonantes = T, p = .7){

    stop_words <- tibble::tibble(palabra = c(stopwords::stopwords("es")))

    df <- bd$respuesta %>%
        left_join(bd$pregunta) %>%
        filter(IdPregunta == pregunta, IdEtapa == etapa)

    aux <- df %>%
        tidytext::unnest_tokens(bigrama, Respuesta, token = "ngrams", n=2,drop = F ) %>%
        tidyr::separate(bigrama, into = c("palabra1", "palabra2"), sep=" ") %>%
        anti_join(stop_words, by = c("palabra1" = "palabra")) %>%
        anti_join(stop_words, by = c("palabra2" = "palabra"))

    if(quitar_altisonantes){
        altisonantes <- obtener_altisonantes() %>% mutate(palabra = tolower(palabra))
        quitar <- aux %>% semi_join(altisonantes, by = c("palabra1" = "palabra")) %>%
            bind_rows(
                aux %>% semi_join(altisonantes, by = c("palabra2" = "palabra"))
            ) %>% distinct(Respuesta)
        aux <- aux %>%
            anti_join(quitar)
    }


    bigramas <- aux %>%
        count(palabra1, palabra2, sort = T) %>%
        filter(n>quantile(n, probs = p)) %>%
        slice(1:30)


    res <- bigramas

    return(res)
}



