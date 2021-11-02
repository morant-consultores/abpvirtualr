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
#' @import dplyr
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
#' @examples #notrun (graficar_nube(p_1))

graficar_nube <- function(tokens_clean, interactivo = TRUE){

    if(interactivo){

        tokens_clean %>%
            hchart(hcaes(x= palabra, weight =log(n),
                         color=colores), type= "wordcloud") %>%
            hc_chart(style=list(fontFamily =familia))   %>%
            # hc_yAxis( scrollbar= list(enabled=F)) %>%
            hc_tooltip(
                # positioner= JS("function (labelWidth, labelHeight) {return{x: (this.chart.plotLeft + (this.chart.plotWidth- this.chart.plotLeft)*.000001),
                #           y: (this.chart.plotHeight)-(this.chart.plotHeight-this.chart.plotTop)*.98};}"),
                # useHTML= T,
                # outside = F,
                # formatter = JS("
                # function (H) {
                # H.wrap(H.Tooltip.prototype, 'refresh', function (proceed, point, e) {
                #     if (e && e.type !== 'mousemove') {
                #     proceed.call(this, point, e);
                #     }
                # });
                # H.addEvent(H.Point.prototype, 'click', function (e) {
                # e.point.series.chart.tooltip.refresh(e.point, e);
                # });
                # }(Highcharts)
                # "),
                pointFormat= "
                Respuestas con la palabra <b>{point.palabra}<b/>: <br>
                {point.completa}
                ",
                headerFormat = '',
                backgroundColor = '#FFFFFF',
                style=list(fontSize = "20px", color = gris, 'overflow-y' = "scroll", scrollbar = TRUE)) %>%
            hc_plotOptions( wordcloud = list(allowPointSelect = T,minFontSize = 2))


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
                           '<b>{point.Categoria}</b><br>
                           Palabras clave: {point.p_clave}',
                           '<br> Porcentaje de categorización:',
                           ' {point.pct} <br/>', sep = ""),
                       headerFormat= '',
                       backgroundColor= '#FFFFFF',
                       style=list(fontSize ="15px", color = gris, fontFamily = familia) ) %>%
            hc_plotOptions(treemap = list(borderRadius = 10,
                                          dataLabels = list( style = list(fontFamily = familia,
                                                                          fontSize = "14px")))   ) %>%
            hc_add_theme(thm) %>%
            hc_legend(enabled = F)


    }
}

#' Formato adecuado para las palabras clave en los slides
#'
#' @param df (tibble) Un marco de datos adecuado para las palabras clave.
#'
#' @return (vector) Una lista de palabras clave.
#' @export
#'
#' @examples #notrun (graficar_claves(brecha$pclave$p_clave))

graficar_claves <- function(df){

    res <- df %>%
        pull(feature) %>%
        paste(collapse = ", ")

    return(res)
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
#' @import ggplot2
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
                hchart(type = "columnrange",
                       hcaes(x = Categoria,y = y, low= ymin, high = ymax),
                       color = primario_claro) %>%
                hc_legend(enabled = T) %>%
                hc_tooltip(
                    enabled = T,
                    pointFormat = 'Media: {point.mediana} <br> límites: inferior {point.ymin2} - superior {point.ymax2}   ',
                    headerFormat = '',
                    borderWidth= 0,
                    backgroundColor= '#FFFFFF',
                    style=list(fontSize ="18px", color = gris)) %>%
                hc_add_series(df, "point",
                              hcaes(x = Categoria, y = y),
                              color = inverso_claro) %>%
                hc_xAxis(title = list(text = "Tema",
                                      style = list(fontSize = etiquetas)),
                         lineWidth = 3.5, lineColor = inverso_claro,
                         labels = list(style = list(fontSize = etiquetas))) %>%
                hc_yAxis(title = list(text = ""),
                         tickAmount = 5, min = 0, max= 100,
                         labels = list(style = list(fontSize = etiquetas))) %>%
                hc_plotOptions(columnrange = list(pointWidth = 7, borderRadius = 4),
                               scatter = list(marker = list(radius = 6.5))) %>%
                hc_add_theme(thm) %>%
                hc_chart(inverted = T, style = list(fontFamily = familia))

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
                ggplot(aes(y = forcats::fct_reorder(
                    Categoria, prom), x = prom)) +
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

        # br <- function(x,c) purrr::map_dbl(x, ~ min(c/(100-.x),100))
        # dominio <- seq(0,100,.1)
        #
        sysfonts::font_add_google(familia)
        #
        # ggplot() +
        #     geom_ribbon(
        #         aes(x = dominio, ymin = 0, ymax = br(dominio,corte[2])),
        #         fill = sm_vf,alpha = .5) +
        #     geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[2]),
        #                     ymax = br(dominio,corte[3])), fill = sm_vc,alpha = .5) +
        #     geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[3]),
        #                     ymax = br(dominio,corte[4])), fill = sm_a,alpha = .5) +
        #     geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[4]),
        #                     ymax = br(dominio,corte[5])), fill = sm_rc,alpha = .5) +
        #     geom_ribbon(aes(x = dominio, ymin = br(dominio,corte[5]),
        #                     ymax = 100), fill = sm_rf,alpha = .5) +
        #     geom_hline(yintercept = 50) +
        #     geom_vline(xintercept = 50) +
        #     geom_abline(linetype = "dotted", color = "gray50") +
        #     coord_fixed(ylim = c(0,100), xlim = c(0,100)) +
        #     labs(y = "Importancia", x = "Cumplimiento", color = "Tema") +
        #     xaringanthemer::theme_xaringan() +
        #     geom_point(data = bd, aes(
        #         x = cumplimiento,
        #         y = importancia,
        #         color = Nombre), size = 5)+
        #     scale_color_manual(values = c("#001C50", "#4DCCBD", "#725E54",
        #                                   "#FF6B6B", "#DBD56E", "#C6B9CD",
        #                                   "#414535", "#EB6534", "#59A5D8",
        #                                   "#DE4797"))+
        #     theme_minimal(base_size=12, base_family = familia,
        #                   base_line_size = .5, base_rect_size = .5 ) %+replace%
        #     theme(text = element_text(family = familia),
        #           axis.title = element_text(size = 15),
        #           legend.title = element_text(size = 15),
        #           legend.text = element_text(size = 12),
        #           axis.text = element_text(size = 12),
        #           panel.grid.minor = element_blank(),
        #           axis.ticks = element_blank()         )

        br <- function(x,c = corte[2]) purrr::map_dbl(x, ~ min(c/(100-.x),100))
        dominio <- seq(0,100,.1)
        sim <- bd %>% group_by(Nombre) %>%
            summarise(media_i = mean(Orden), sd_i = sqrt(var(Orden/5)),
                      media_c = mean(Calificacion), sd_c = sqrt(var(Calificacion/5))) %>%
            purrr::pmap(function(Nombre, media_i,sd_i,media_c,sd_c){
                tibble::tibble(tema = Nombre, i = rnorm(100,media_i, sd_i),
                               c = rnorm(100,media_c, sd_c),b = i*(100-c))
            }) %>% bind_rows()
        # e <- bd %>% ggplot() +
        #     geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2])),
        #                 aes(x = a, ymin = 0, ymax = b), fill = sm_vf,alpha = .5) +
        #     geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2]), c = br(a,corte[3])),
        #                 aes(x = a, ymin = b, ymax = c), fill = sm_vc,alpha = .5) +
        #     geom_ribbon(data = tibble(a = dominio, b = br(a,corte[3]), c = br(a,corte[4])),
        #                 aes(x = a, ymin = b, ymax = c), fill = sm_a,alpha = .5) +
        #     geom_ribbon(data = tibble(a = dominio, b = br(a,corte[4]), c = br(a,corte[5])),
        #                 aes(x = a, ymin = b, ymax = c), fill = sm_rc,alpha = .5) +
        #     geom_ribbon(data = tibble(a = dominio, b = br(a,corte[5])),
        #                 aes(x = a, ymin = b,
        #                     ymax = 100), fill = sm_rf,alpha = .5) + coord_fixed() +
        #     xlim(c(0,100)) + ylim(c(0,100)) +
        #     geom_vline(xintercept = 50, fill = primario) +
        #     geom_hline(yintercept = 50)+
        #     geom_abline(linetype = "dotted") +
        #     geom_hex(aes(x = Calificacion, y = Orden)) +
        #     labs(fill = "Respuestas") +
        #     facet_wrap(~Nombre, nrow= 2) +
        #     theme_void() +# theme(legend.position = "bottom") +
        #     scale_fill_gradientn(colours = hcl.colors(50, "YlOrRd", rev = TRUE),
        #                          breaks = seq(0,bd %>% count(Nombre) %>% summarise(max(n)) %>% pull(1),
        #                                       length.out = 5))
        e <- sim %>%
            ggplot() +
            geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2])),
                        aes(x = a, ymin = 0, ymax = b),
                        fill = sm_vf,alpha = .4) +
            geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2]), c = br(a,corte[3])),
                        aes(x = a, ymin = b,
                            ymax = c), fill = sm_vc,alpha = .4) +
            geom_ribbon(data = tibble(a = dominio, b = br(a,corte[3]), c = br(a,corte[4])),
                        aes(x = a, ymin = b,
                            ymax = c), fill = sm_a,alpha = .4) +
            geom_ribbon(data = tibble(a = dominio, b = br(a,corte[4]), c = br(a,corte[5])),
                        aes(x = a, ymin = b,
                            ymax = c), fill = sm_rc,alpha = .4) +
            geom_ribbon(data = tibble(a = dominio, b = br(a,corte[5])),
                        aes(x = a, ymin = b,
                            ymax = 100), fill = sm_rf,alpha = .4) + coord_fixed() +
            xlim(c(0,100)) + ylim(c(0,100)) +
            geom_vline(xintercept = 50) +
            geom_hline(yintercept = 50)+
            geom_abline(linetype = "dotted") +
            geom_hex(aes(x = c, y = i), ) +
            scale_fill_gradient(low=inverso_claro ,high=primario)+
            # geom_point(aes(x = c, y = i)) +
            labs( x = "Cumplimiento", y ="Importancia", fill = "Respuestas") +
            # geom_point(data = sim %>% group_by(tema) %>%
            #                summarise(i = mean(i), c = mean(c)),
            #            aes(x = c, y = i), color = "red", size = 2
            # )+
            facet_wrap(~tema, nrow= 2) +
            scale_y_continuous(breaks = c(0,50,100)) +
            scale_x_continuous(breaks = c(0,50,100)) +
            # scale_fill_gradientn(colours = hcl.colors(50, "YlOrRd", rev = TRUE)#,
            #                      # breaks = seq(0,sim %>% count(tema) %>% summarise(max(n)) %>% pull(1),
            #                      #              length.out = 5)
            #                      ) +
            xaringanthemer::theme_xaringan() +
            theme_minimal(base_size=12, base_family = familia,
                          base_line_size = .5, base_rect_size = .5 ) %+replace%
            theme(text = element_text(family = familia),
                  axis.title = element_text(size = 15),
                  legend.title = element_text(size = ),
                  # legend.position = "bottom",
                  # legend.direction = "vertical",
                  legend.text = element_text(size = 8),
                  legend.key.size = unit(.8,"line"),
                  axis.text = element_text(size = 12),
                  panel.grid.minor = element_blank(),
                  axis.ticks = element_blank()
            )
        return(e)
    }
}



StatAreaUnderDensity <- ggproto(
    "StatAreaUnderDensity", Stat,
    required_aes = "x",
    compute_group = function(data, scales, xlim = NULL, n = 50) {
        fun <- approxfun(density(data$x, from = 0, to = 10000))
        StatFunction$compute_group(data, scales, fun = fun, xlim = xlim, n = n)
    }
)

stat_aud <- function(mapping = NULL, data = NULL, geom = "area",
                     position = "identity", na.rm = FALSE, show.legend = NA,
                     inherit.aes = TRUE, n = 50, xlim=NULL,
                     ...) {
    layer(
        stat = StatAreaUnderDensity, data = data, mapping = mapping, geom = geom,
        position = position, show.legend = show.legend, inherit.aes = inherit.aes,
        params = list(xlim = xlim, n = n, ...))
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
#' @examples #notrun ( graficar_nbrecha(calcular_brecha(bd)) )

graficar_nbrecha <- function(brecha, thm){
    bd <- brecha %>% purrr::pluck(2) %>%
        arrange(desc(prob)) %>%
        mutate(
            prob_pct = base::round(prob*100),
            brecha_pct = base::round(brecha_pct*100),
            Categoria = forcats::fct_reorder(Nombre, prob)
        )

    juntos <- brecha %>% purrr::pluck(1)

    Graph <- juntos %>% ggplot(aes(x = brecha)) + geom_density(color = "white", alpha= .9) +
        stat_aud(geom="area",
                 fill = sm_vf,
                 xlim = cortes[1:2],
                 alpha = 1)+
        stat_aud(geom="area",
                 fill = sm_vc,
                 xlim = cortes[2:3],
                 alpha = 1)+
        stat_aud(geom="area",
                 fill = sm_a,
                 xlim = cortes[3:4],
                 alpha = 1)+
        stat_aud(geom="area",
                 fill = sm_rc,
                 xlim = cortes[4:5],
                 alpha = 1)+
        stat_aud(geom="area",
                 fill = sm_rf,
                 xlim = cortes[5:6],
                 alpha = 1)+
        geom_point(data = bd %>% filter(prob == max(prob)) %>% ungroup, aes(color = color, x = 5000, y = .00022), size = 3) +
        # geom_point(data = brecha_prob_2, aes(color = color, x = 7500, y = .00025), size = 5) +
        scale_color_identity() +
        # geom_vline(data = juntos %>% group_by(Nombre) %>% summarise(media = mean(brecha)),
        #            aes(xintercept = media)
        # ) +
        geom_text(data = bd %>% mutate(mean = (inf+sup)/2), size = 3,family  = familia,
                  aes(x = mean, y = 0, label = scales::percent(prob,.1)),nudge_y = .00001, color = gris) +
        facet_wrap(~Nombre)+ theme_void() +
        labs(caption = "* El círculo de color representa la semaforización más frecuente.")+
        theme(panel.grid = element_blank(), text = element_text(family = familia))


    # bd %>% hchart(hcaes(y = prob_pct, x = Categoria), type = "bar") %>%
    #     hc_plotOptions(bar = list(colorByPoint = T, borderRadius = 6, borderWidth =0)) %>%
    #     hc_legend(enabled = F) %>%
    #     hc_tooltip(
    #         enabled = T,
    #         headerFormat = '<span style="font-size: 14px"><b>{point.key}</b></span><br/>',
    #         pointFormat = ' <br> Brecha: {point.brecha_pct}% <br> Frecuencia: {point.prob_pct}%',
    #         backgroundColor= '#FFFFFF',
    #         borderWidth =0,
    #         style=list(fontSize ="16px", color = gris, fontFamily = familia)) %>%
    #     hc_xAxis(lineWidth = 3.5, lineColor = primario_claro, zIndex= 5,
    #              labels = list(style = list(fontSize = etiquetas)),
    #              title= list(text = "Tema", style = list(fontSize = etiquetas))        ) %>%
    #     hc_colors(bd %>% pull(color)) %>%
    #     hc_yAxis( labels = list(format = "{value}%",
    #                             style = list(fontSize = etiquetas)),
    #               title = list(text = "Frecuencia"),
    #               tickAmount = 5,
    #               min = 0) %>%
    #     hc_add_theme(thm) %>%
    #     hc_chart(style=list(fontFamily = familia))
    return(Graph)
}

#' Genera la tabla en formato kable con sus colores
#'
#' @param brecha (tibble) Un marco de datos que proviene
#' de generar_tabla.
#'
#' @return Una tabla de tipo kable.
#' @export
#'
#' @examples #notrun (generar_tabla(brecha2))
#'

generar_tabla <- function(brecha){
    tabla <- brecha %>% purrr::pluck(2) %>%
        filter(prob == max(prob)) %>% ungroup %>%
        arrange(desc(brecha))
    colores <- tabla %>% pull(color)

    tabla_df <- tabla %>%
        mutate(Brecha = scales::percent(brecha_pct, 1),
               Frecuencia =scales::percent(prob, 1),
               cumplimiento = paste0(cumplimiento, "%"),
               importancia= paste0(importancia, "%")  ) %>%
        select( Tema=Nombre ,
                Brecha,
                Frecuencia,
                Cumplimiento = cumplimiento,
                Importancia = importancia) %>%
        kableExtra::kbl() %>%
        kableExtra::kable_paper("striped", full_width = F) %>%
        kableExtra::column_spec(2:3, color = "white",
                                background = colores) %>%
        kableExtra::kable_classic(full_width = F, html_font = familia)
    return(tabla_df)
}


#' Title
#'
#' @param bd (Tibble) que proviene del segundo elemento de procesar_p_abierta
#'
#' @return Tabla en formato DT.
#' @export
#'
#' @examples #notrun (generar_tabla_nube(procesar_p_abierta(bd,1,1) %>% pluck(2)))

generar_tabla_nube <- function(bd){
    tabla <- bd %>%
        select(Respuesta) %>%
        DT::datatable(
            options = list(
                language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json'),
                lengthMenu = c(5, 10, 25, 50, 100),
                pageLength = 3,
                scrollY = 300   ))
        # DT::formatStyle(columns=colnames(bd),
        #                 backgroundColor = '#222222', color = "white")
    return(tabla)
}
