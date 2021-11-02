library(tidyverse)
library(dbplyr)
library(highcharter)
library(ggpmthemes)
library(showtext)
library(spatstat)
library(scales)
devtools::load_all(here::here())
# Correr ----------------------------------------------------------------

# Necesitas correr esto
primario <- "#232B58"
primario_claro <- "#304E83"
inverso <- "#4C97C8"
inverso_claro <- "#88B9CF"
corte <- seq(0,10000,length.out = 6)
# corte <- expand.grid(i= 0:100, c = 0:100) %>% as_tibble %>% mutate(b =i * (100-c)) %>%
#     summarise(quantile(b,c(0,.2,.4,.6,.8,1))) %>% pull(1)
cortes <- corte
sm_vf <- "#1C6130"
sm_vc <- "#55A630"
sm_a <- "#F5BC38"
sm_rc <- "#BA181B"
sm_rf <- "#660708"
familia <- "Poppins"
gris <- "#343a40"
gris_claro <- "#ced4da"
etiquetas = "14px"


data(conexion)
thm <- tema_high(font = "Poppins", color = "black", size = "15px")
bd <- leer_base(id_sesion = 3156)

# funciones ---------------------------------------------------------------

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
# base --------------------------------------------------------------------
juntos <- bd$orden_cat %>%
    select(usuario = IdUsuario,Orden,IdCategoria) %>%
    left_join(
        bd$calif_cat %>%
            select(usuario = IdUsuario,Calificacion,IdCategoria)
    ) %>%
    na.omit() %>%
    left_join(bd$categoria) %>%
    rename(cat = IdCategoria) %>%
    mutate(brecha = Orden*(100-Calificacion))
# prob brecha -------------------------------------------------------------

brecha_prob_1 <- juntos %>%
    split(.$Nombre) %>%
    imap(~{
        acum <- spatstat.core::CDF(density(.x$brecha, from = 0, to = 10000))
        tibble(inf= corte,sup = lead(corte), color = c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf,"")) %>%
            slice(-6) %>%
            mutate(
                prob = acum(sup-.0000001) - acum(inf),
                Nombre = .y
            )
    }) %>%
    bind_rows() %>%
    group_by(Nombre)

(a <- juntos %>%
        ggplot(aes(x = brecha)) + geom_density() +
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
        geom_point(data = brecha_prob_1 %>%
        filter(prob == max(prob)), aes(color = color, x = 5000, y = .00025), size = 5) +
        # geom_point(data = brecha_prob_2, aes(color = color, x = 7500, y = .00025), size = 5) +
        scale_color_identity() +
        geom_vline(data = juntos %>% group_by(Nombre) %>% summarise(media = mean(brecha)),
                   aes(xintercept = media)
        ) +
        # geom_vline(data = juntos %>% group_by(Nombre) %>% summarise(mediana = median(brecha)),
        #            aes(xintercept = mediana), linetype = "dashed"
        # ) +
        geom_text(data = brecha_prob_1 %>% mutate(mean = (inf+sup)/2),
                  aes(x = mean, y = 0, label = percent(prob,.1)),nudge_y = .00001, color = "white") +
        facet_wrap(~Nombre)+ theme_void() +
        labs(caption = "* El círculo de color representa la propuesta de semaforización. \n** La línea vertical representa el promedio de la brecha.             ")
)

b <- brecha_prob_1 %>%
    ggplot(aes(x = Nombre, y = -sup, color = color)) +
    geom_point(data = brecha_prob_1  %>% filter(prob == max(prob)),size = 30) +
    geom_point(data = brecha_prob_1  %>% mutate(ancho = prob/max(prob)) %>% filter(prob != max(prob)),
               size = 10,
               shape = 21, aes(stroke = ancho*10)) +
    geom_text(data = brecha_prob_1  %>% filter(prob == max(prob)),
              aes(label = percent(prob,accuracy = .01)), color = "white") +
    geom_text(data = brecha_prob_1  %>% filter(prob != max(prob)),
              aes(label = percent(prob,accuracy = .01)), color = "black") +
    scale_color_identity() + theme_minimal() +theme(axis.text.y = element_blank()) +
    labs(x =NULL,y = NULL)


c <- brecha_prob_1 %>%
    mutate(alpha = prob/max(prob)) %>%
    ggplot(aes(x =  stringr::str_wrap(Nombre, 10), y = -sup, fill = color)) +
    geom_tile(show.legend = F, aes(alpha = prob)) +
    geom_tile(data = brecha_prob_1 %>% filter(prob == max(prob)), show.legend = F, color = primario, size = 1) +
    geom_text(family = familia,
        aes(label = percent(prob,accuracy = .1)), color = "black", show.legend = F) +
    scale_fill_identity()+ theme_minimal() + theme(axis.text.y = element_blank()) +
    labs(x =NULL,y = NULL)+
    xaringanthemer::theme_xaringan() +
    scale_y_continuous(labels=scales::percent_format(accuracy = 1), n.breaks = 4)+
    theme(panel.grid = element_blank(), text = element_text(family = familia),
          axis.text = element_text(size = 15))

d <-   brecha_prob_1 %>%
    mutate(color = factor(color, levels = c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf)),
           acum = cumsum(prob)) %>%
    ggplot(aes(x = 1, y = prob, fill = color)) +
    ggchicklet::geom_chicklet(position = "dodge",show.legend = F, alpha = .8, size= 1) +
    # geom_text(aes(label = percent(prob,1), x = acum)) +
    scale_fill_manual(values =c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf)) +
    facet_wrap(~Nombre)+
        labs(y = "Probabilidad", x = "")+
    xaringanthemer::theme_xaringan() +
        scale_y_continuous(labels=scales::percent_format(accuracy = 1))+
    geom_text(family= familia, aes(label = prob %>% scales::percent(accuracy = 1)) ,
              position = position_dodge(width = .9), vjust = "inward")+
    theme_minimal(base_size=12, base_family = familia,
                  base_line_size = .5, base_rect_size = .5 ) %+replace%
    theme(text = element_text(family = familia),
          axis.title = element_text(size = 15),
          legend.title = element_text(size = 15),
          legend.text = element_text(size = 12),
          axis.text = element_text(size = 10),
          axis.text.x = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          axis.ticks = element_blank(),
          strip.text = element_text(size = 16)

    )

br <- function(x,c = corte[2]) purrr::map_dbl(x, ~ min(c/(100-.x),100))
dominio <- seq(0,100,.1)
library(hexbin)
e <- juntos %>% ggplot() +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2])),
                aes(x = a, ymin = 0, ymax = b), fill = sm_vf,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2]), c = br(a,corte[3])),
                aes(x = a, ymin = b, ymax = c), fill = sm_vc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[3]), c = br(a,corte[4])),
                aes(x = a, ymin = b, ymax = c), fill = sm_a,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[4]), c = br(a,corte[5])),
                aes(x = a, ymin = b, ymax = c), fill = sm_rc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[5])),
                aes(x = a, ymin = b,
                    ymax = 100), fill = sm_rf,alpha = .5) + coord_fixed() +
    xlim(c(0,100)) + ylim(c(0,100)) +
    geom_vline(xintercept = 50, fill = primario) +
    geom_hline(yintercept = 50)+
    geom_abline(linetype = "dotted") +
    geom_hex(aes(x = Calificacion, y = Orden)) +
    labs(fill = "Respuestas") +
    facet_wrap(~Nombre, nrow= 2) +
    theme_void() + theme(legend.position = "bottom") +
    scale_fill_gradientn(colours = hcl.colors(50, "YlOrRd", rev = TRUE),
                         breaks = seq(0,juntos %>% count(Nombre) %>% summarise(max(n)) %>% pull(1),
                                      length.out = 5))
# Gráficas ----------------------------------------------------------------

a
b
c
d
e
# Combinaciones -----------------------------------------------------------

comb <- expand.grid(i= 0:100, c = 0:100) %>% as_tibble %>% mutate(b =i * (100-c))
comb %>%
    summarise(quantile(b,c(0,.2,.4,.6,.8,1))) %>% pull(1)
comb %>% ggplot(aes(x = b)) +geom_density()

i <- juntos$Orden %>% mean
i_sd <- juntos$Orden %>% var %>% sqrt

c <- juntos$Calificacion %>% mean
c_sd <- juntos$Calificacion %>% var %>% sqrt

sim <- tibble(i = rnorm(2000,i,i_sd),
              c = rnorm(2000,c,c_sd),
              b = i*(100-c)
)
corte <- sim %>% summarise(quantile(b,c(0,.2,.4,.6,.8,1))) %>% pull(1)
corte[c(1,6)] <- c(0,10000)
corte
sim %>% ggplot(aes(x = b)) + geom_density()

comb %>% ggplot() + geom_tile(aes(x = c, y = i))

# Simulacion --------------------------------------------------------------

sim <- juntos %>% group_by(Nombre) %>% summarise(media_i = mean(Orden), sd_i = sqrt(var(Orden/5)),
                                          media_c = mean(Calificacion), sd_c = sqrt(var(Calificacion/5))) %>%
    pmap(function(Nombre, media_i,sd_i,media_c,sd_c){
        tibble(tema = Nombre, i = rnorm(100,media_i, sd_i),
               c = rnorm(100,media_c, sd_c),b = i*(100-c))
    }) %>% bind_rows()
sim %>%
    ggplot() +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2])),
                aes(x = a, ymin = 0, ymax = b),
                fill = sm_vf,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2]), c = br(a,corte[3])),
                aes(x = a, ymin = b,
                    ymax = c), fill = sm_vc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[3]), c = br(a,corte[4])),
                aes(x = a, ymin = b,
                    ymax = c), fill = sm_a,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[4]), c = br(a,corte[5])),
                aes(x = a, ymin = b,
                    ymax = c), fill = sm_rc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[5])),
                aes(x = a, ymin = b,
                    ymax = 100), fill = sm_rf,alpha = .5) + coord_fixed() +
    xlim(c(0,100)) + ylim(c(0,100)) +
    geom_vline(xintercept = 50) +
    geom_hline(yintercept = 50)+
    geom_abline(linetype = "dotted") +
    geom_hex(aes(x = c, y = i)) +
    # geom_point(aes(x = c, y = i)) +
    labs(fill = "Respuestas") +
    # geom_point(data = sim %>% group_by(tema) %>%
    #                summarise(i = mean(i), c = mean(c)),
    #            aes(x = c, y = i), color = "red", size = 2
    # )+
    facet_wrap(~tema, nrow= 2) +
    theme_void() + theme(legend.position = "bottom") +
    scale_fill_gradientn(colours = hcl.colors(50, "YlOrRd", rev = TRUE),
                         breaks = seq(0,sim %>% count(tema) %>% summarise(max(n)) %>% pull(1),
                                      length.out = 5))
    # scale_fill_gradient(breaks = seq(0,sim %>% count(tema) %>% summarise(max(n)) %>% pull(1),
    #                                  length.out = 5),
    #                     low = primario, high = sm_rc)
