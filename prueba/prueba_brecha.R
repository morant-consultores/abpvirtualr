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
    ggplot(aes(x = Nombre, y = -sup, fill = color,alpha = prob)) +
    geom_tile(show.legend = F) +
    geom_tile(data = brecha_prob_1 %>% filter(prob == max(prob)), show.legend = F, color = primario, size = 3) +
    geom_text(
        aes(label = percent(prob,accuracy = .1)), color = "black", show.legend = F) +
    scale_fill_identity()+ theme_minimal() + theme(axis.text.y = element_blank()) +
    labs(x =NULL,y = NULL)

d <- brecha_prob_1 %>%
    mutate(color = factor(color, levels = c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf)),
           acum = cumsum(prob)) %>%
    ggplot(aes(x = Nombre, y = prob, fill = color)) +
    geom_col(position = "stack",show.legend = F) +
    # geom_text(aes(label = percent(prob,1), x = acum)) +
    scale_fill_manual(values =c(sm_vf,sm_vc,sm_a,sm_rc,sm_rf))

br <- function(x,c = corte[2]) purrr::map_dbl(x, ~ min(c/(100-.x),100))
dominio <- seq(0,100,.1)
library(hexbin)
juntos %>%
    ggplot() +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2])),
                aes(x = a, ymin = 0, ymax = b), fill = sm_vf,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[2]), c = br(a,corte[3])),
                aes(x = a, ymin = b, ymax = c), fill = sm_vc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[3]), c = br(a,corte[4])),
                aes(x = a, ymin = b, ymax = c), fill = sm_a,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[4]), c = br(a,corte[5])),
                aes(x = a, ymin = b, ymax = c), fill = sm_rc,alpha = .5) +
    geom_ribbon(data = tibble(a = dominio, b = br(a,corte[5])),
                aes(x = a, ymin = b, ymax = 100), fill = sm_rf,alpha = .5) +
    coord_fixed() +
    xlim(c(0,100)) +
    ylim(c(0,100)) +
    # geom_tile(aes(x = Calificacion, y = Orden), width = 10, height = 10) +
    geom_hex(aes(x = Calificacion, y = Orden), bins = 10) +
    # geom_point(aes(x = Calificacion, y = Orden), color = "orange") +
    geom_vline(xintercept = 50) +
    geom_hline(yintercept = 50)+
    geom_abline(linetype = "dotted") +
    geom_point(data = juntos %>%
                   group_by(Nombre) %>%
                   summarise(i = mean(Orden), c = mean(Calificacion)),
               aes(x = c, y = i), color = "red", size = 3
    )+
    facet_wrap(~Nombre, nrow= 2) +
    theme_void()

# Gráficas ----------------------------------------------------------------

a
b
c
d
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

