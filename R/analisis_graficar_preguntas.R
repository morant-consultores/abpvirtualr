#' Tema para modificar los parámetros estéticos de highcharter
#'
#' @param font (char) Font de google fonts
#' @param color (char) Color de la fuente
#' @param size (char) Tamaño de la fuente
#'
#' @return Tema de highcharter
#' @export
#'
#' @import highcharter
#' @import glue
#' @examples #notrun (tema_highcharter("Popins","black", "15px"))

tema_high <- function(font, color, size){

    options(highcharter.google_fonts = TRUE)

    thm <- hc_theme(
        chart = list(fontFamily = glue::glue("{font}"),
            fontSize = glue::glue("{size}"),
        title = list(style =
            list(fontFamily = glue::glue("{font}"))),
        subtitle = list(style =
            list(fontFamily = glue::glue("{font}")),
        legend = list(itemStyle =
        list(fontFamily = glue::glue({"{font}"}),
        color = glue::glue("{color}")),
        itemHoverStyle = list(color ='gray'))
        ))
    )

    return(thm)
}

#' Nube de palabras interactiva
#'
#' @param tokens_clean (tibble) Marco de datos con las palabras,
#' frecuencias y colores asignados.
#' @param interactivo (logical) TRUE o FALSE dependiendo si es interactivo
#' o no.
#'
#' @return Gráfica de nube de palabras.
#' @export
#'
#' @import highcharter
#' @import dplyr
#' @examples #notrun (graficar_nube(p_1))

graficar_nube <- function(tokens_clean, interactivo = TRUE){

    if(interactivo){

    tokens_clean %>%
        hchart(hcaes(x = palabra, weight = log(n),
        color=colores), type= "wordcloud") %>%
            hc_chart(style = list(fontFamily="Poppins")) %>%
            hc_tooltip(
            enabled=T,
            pointFormat= 'Frases mencionadas:<b/> <br>{point.completa}',
            headerFormat= '',
            backgroundColor= '#FFFFFF',
            style=list(fontSize ="25px", color = "#005B70")) %>%
            hc_plotOptions( wordcloud= list(allowPointSelect = TRUE,
            style=list('{"fontFamily" : "Poppins", "fontWeight": "200"}'))
            )

    }else{

        pal <- RColorBrewer::brewer.pal(8,"Dark2")
        tokens_clean %>% with(
            wordcloud::wordcloud(palabra, n,
                      random.order = FALSE, min.freq = 1,
                      max.words = 50, colors=pal))

    }
}


#' Treemap sobre el resumen del cálculo de la brecha
#'
#' @param bd (tibble)  Marco de datos provista de procesar_brecha
#' @param interactivo (logical) TRUE o FALSE dependiendo si se quiere
#' interactividad o no.
#' @param inverso (char) Código del color inverso
#' @param primario (char) Código del color primario
#' @param thm Tema de la gráfica
#'
#' @return Gráfica treemap
#' @export
#'
#' @import highcharter
#' @import dplyr
#' @examples #notrun (graficar_brecha(bd, inverso, primario, tema_highcharter()))

graficar_brecha <- function(bd, interactivo = TRUE,
                            inverso, primario, thm){

    if(interactivo){
        bd %>%
            mutate(Categoria = factor(Nombre)) %>%
            hchart("treemap",
            hcaes(x = Categoria, value = pct_r, color = pct_r)) %>%
            hc_colorAxis(
            stops = color_stops(colors =
            grDevices::colorRampPalette(c(inverso, primario))(11))
            ) %>%
            hc_tooltip(enabled=T,
                pointFormat= paste(
                'Palabras clave: <br>{point.p_clave}',
                '<br/> Porcentaje de categorización:',
                '<br>{point.pct} <br/>', sep = ""),
                headerFormat= '',
                backgroundColor= '#FFFFFF',
                style=list(fontSize ="15px", color = primario)
            ) %>%
            hc_add_theme(thm)

    }else{
        bd %>%
            ggplot2::ggplot(
            aes(x=forcats::fct_reorder(Nombre, -n), y =n)) +
            ggplot2::geom_col(aes(fill = Nombre)) +
            ggplot2::theme_minimal() +
            ggplot2::geom_label(aes(label = p_clave))
    }
}

#' Gráfica de barras (histograma) y otra de resumen (error bar)
#'
#' @param bd (list) Listas de marcos de datos provistas de
#' procesar_numerica.
#' @param tipo (char) Puede ser "histograma" o "point_range" dependiendo
#' el tipo de gráfica.
#' @param interactivo (logical) TRUE o FALSE dependiendo si se quiere
#' interactividad o no.
#' @param thm Tema de la gráfica.
#'
#' @return Gráfica highcharter; histograma o errorbar
#' @export
#'
#' @import highcharter
#' @import ggplot2
#' @import dplyr
#' @examples #notrun (graficar_numerica(bd %>% procesar_numerica("Calificacion"), tipo = 'point_range',tema_highcharter()) )


graficar_numerica <- function(bd, tipo, interactivo = TRUE, thm){

    if (interactivo == TRUE){
        if (tipo == "histograma"){

            bd %>%
                purrr::pluck(1) %>%
                count(Calificacion, Categoria) %>%
                hchart(type = "column",
                    hcaes(y = n, x = Calificacion,
                    group = Categoria)) %>%
                hc_plotOptions(
                    bar = list(stacking = "percent")) %>%
                hc_legend(enabled = T) %>%
                hc_tooltip(enabled=T,
                    pointFormat =
                    'Número de participantes:<b/> <br>{point.n}',
                    headerFormat= '',
                    backgroundColor= '#FFFFFF',
                    style=list(fontSize ="25px", color = "#005B70")) %>%
                hc_add_theme(thm)

        }else if (tipo == "point_range"){

            df <- bd %>%
                purrr::pluck("point_range") %>%
                arrange(desc(y)) %>%
                mutate(
                    Categoria = forcats::fct_reorder(Categoria, y),
                    mediana = round(y, digits = 2))


            df %>%
                hchart(type = "errorbar",
                hcaes(x = Categoria,y = y, low= ymin, high = ymax),
                color = primario) %>%
                hc_legend(enabled = T) %>%
                hc_tooltip(
                    enabled = T,
                    pointFormat = 'Mediana: {point.mediana} ',
                    headerFormat = '',
                    backgroundColor= '#FFFFFF',
                    style=list(fontSize ="20px", color = primario)) %>%
                hc_add_series(df, "point",
                hcaes(x = Categoria, y = y),
                color = inverso) %>%
                hc_xAxis(title = list(text = "Categoria")) %>%
                hc_yAxis(title = list(text = "")) %>%
                hc_add_theme(thm)

        }else{NULL}

    }else{

        if (tipo == "histograma"){
            bd %>%
                purrr::pluck(1) %>%
                ggplot(aes(x = Calificacion,
                           fill = Categoria)) +
                geom_histogram(binwidth = 3) +
                theme_minimal() +
                facet_wrap(~Categoria, ncol = 5)

        }else if (tipo == "point_range"){

            bd %>%
                purrr::pluck(2) %>%
                ggplot(aes(y = fct_reorder(Categoria, prom), x = prom)) +
                geom_col(fill="skyblue", alpha=0.5) +
                geom_pointrange(
                    aes(xmin = prom-se, xmax=prom+se),
                    colour="orange", alpha=0.9, size=0.7) +
                theme_minimal()

        }else{NULL}
    }
}


#' Gráfica conjunta de Importancia y Cumplimiento.
#'
#' @param bd (tibble) Marco de datos provisto por la función
#' procesar_juntos.
#' @param interactivo (logical) TRUE o FALSE dependiendo si
#' la gráfica es interactiva o no.
#' @param corte (vector) Cortes propuestos.
#' @param thm Tema en highcharter
#'
#' @return Gráfica de cumplimiento vs importancia.
#' @export
#' @import highcharter
#' @import dplyr
#' @import ggplot2
#'
#' @examples #notrun ( graficar_juntos(procesar_juntos(bd), tema_highcharter()) )

graficar_juntos <- function(bd, interactivo = FALSE, corte = cortes, thm){

  if(interactivo){

        bd %>%
            hchart("scatter",
                hcaes(x = importancia,
                y = cumplimiento, group = Nombre)) %>%
            hc_add_theme(thm)

    }
    else{

        br <- function(x,c) purrr::map_dbl(x, ~ min(c/(100-.x),100))
        dominio <- seq(0,100,.1)

        ggplot() +
            geom_ribbon(
            aes(x = dominio, ymin = 0, ymax = br(dominio,corte[2])),
            fill = sm_vf,alpha = .3) +
            geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[2]),
            ymax = br(dominio,corte[3])), fill = sm_vc,alpha = .3) +
            geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[3]),
            ymax = br(dominio,corte[4])), fill = sm_a,alpha = .3) +
            geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[4]),
            ymax = br(dominio,corte[5])), fill = sm_rc,alpha = .3) +
            geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[5]),
            ymax = 100), fill = sm_rf,alpha = .3) +
            geom_hline(yintercept = 50) +
            geom_vline(xintercept = 50) +
            geom_abline(linetype = "dotted", color = "gray50") +
            coord_fixed(ylim = c(0,100), xlim = c(0,100)) +
            labs(y = "Importancia", x = "Cumplimiento") +
            theme_xaringan() +
            geom_point(data = bd, aes(
                x = cumplimiento,
                y = importancia,
                color = Nombre))
    }
}



#' Gráfica de barras del cálculo de brecha.
#'
#' @param brecha (tibble) Marco de datos provisto por
#' calcular_brecha.
#' @param thm Tema de highcharter.
#'
#' @return Gráfica de barras del cálculo de brecha
#' @export
#'
#' @import highcharter
#' @import dplyr
#' @examples #notrun ( graficar_nbrecha(calcular_brecha(bd)) )

graficar_nbrecha <- function(brecha, thm){

    bd <- brecha %>%
        arrange(desc(brecha)) %>%
        mutate(Categoria = forcats::fct_reorder(Categoria, brecha))

    highchart() %>%
        hc_add_series(bd,
        type = "bar",
        hcaes(y = brecha, x = Categoria)) %>%
        hc_legend(enabled = F) %>%
        hc_tooltip(
            enabled = T,
            pointFormat =
                ' <br> Brecha: {point.brecha}',
            backgroundColor= '#FFFFFF',
            style=list(fontSize ="16px", color = primario)) %>%
        hc_xAxis(
            list(categories = bd$Categoria)) %>%
        hc_colors(bd %>% pull(color)) %>%
        hc_add_theme(thm)

}
