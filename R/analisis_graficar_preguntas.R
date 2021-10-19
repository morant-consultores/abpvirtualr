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
#' @examples #notrun (graficar_nube(p_1))

graficar_nube <- function(tokens_clean, interactivo = TRUE){

    if(interactivo){

    tokens_clean %>%
        hchart(hcaes(x = palabra, weight = log(n),
        color=colores), type= "wordcloud") %>%
            hc_chart(style = list(fontFamily="Poppins"))   %>%
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
            wordcloud2::wordcloud(palabra, n,
                      random.order = FALSE, min.freq = 1,
                      max.words = 50, colors=pal))

    }
}

