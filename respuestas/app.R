#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(dplyr)
library(dbplyr)
library(purrr)
library(ggplot2)
library(shinycssloaders)

leer_base <- function(id_sesion = NA){
    conexion <- list(Driver = "ODBC Driver 17 for SQL Server",
                     Server = "database.negox.com",
                     Database = "viajeporchiapas_abpvirtual",
                     UID = "viajeporchiapas_abp_user",
                     PWD = "CIDFares@BP2021",
                     Port = 1433)
    con <- pool::dbPool(odbc::odbc(),
                        Driver = conexion$Driver,
                        Server = conexion$Server,
                        Database = conexion$Database,
                        UID = conexion$UID,
                        PWD = conexion$PWD,
                        Port = conexion$Port)

    id_sesion <- if(is.na(id_sesion)) tbl(con,
                                          in_schema("General","Sesion")) %>%
        summarise(max(IdSesion)) %>%
        pull(1) else id_sesion

    id_sesion <- if(id_sesion == "Todo") tbl(con,
                                             in_schema("General","Sesion")) %>%
        pull(IdSesion) else id_sesion

    etapa <- tbl(con,in_schema("Catalogo", "Etapa")) %>%
        collect()

    pregunta <- tbl(con,in_schema("Cuestionario", "Pregunta")) %>%
        collect()

    respuesta <- tbl(con,in_schema("Cuestionario", "Respuesta")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    categoria <- tbl(con,in_schema("Catalogo", "Categoria")) %>%
        collect()

    respuesta_cat <- tbl(con,
                         in_schema("Cuestionario", "RespuestaCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    orden_cat <- tbl(con,
                     in_schema("Cuestionario", "OrdenCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    calif_cat <- tbl(con,
                     in_schema("Cuestionario", "CalificacionCategoria")) %>%
        filter(IdSesion %in% !! id_sesion) %>%
        collect()

    pool::poolClose(con)

    res <- list(
        etapa = etapa,
        pregunta = pregunta,
        respuesta = respuesta,
        categoria = categoria,
        respuesta_cat = respuesta_cat,
        orden_cat = orden_cat,
        calif_cat = calif_cat
    )

    return(res)
}
# Define UI for application that draws a histogram
ui <- dashboardPage(
    dashboardHeader(title = "Respuestas ABP"),
    dashboardSidebar(disable = T),
    dashboardBody(
        selectInput(inputId = "sesion",label = "Sesión",choices = rev(c("Todas" = "Todo", "Última" = NA))),
        actionButton("actualizar","Actualizar"),
        selectInput(inputId = "etapa", label = "Etapa", choices = 1),
        withSpinner(plotOutput("abierta")),
        fluidRow(
            valueBoxOutput("respuesta_cat"),
            valueBoxOutput("importancia_cat"),
            valueBoxOutput("cumplimiento_cat")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    bd <- eventReactive(c(input$sesion,input$actualizar),{
        leer_base( id_sesion = readr::parse_character(input$sesion))
    })

    etapas <- reactive(
        unique(isolate(bd)() %>% pluck("respuesta") %>% pull(IdEtapa))
    )

    seleccionado <- eventReactive(input$etapa,{
        input$etapa
    })

    observeEvent(bd(),{
        updateSelectInput(session, "etapa", choices = etapas(), selected = seleccionado())
    })

    output$abierta <- renderPlot({
        validate(
            need(input$etapa, "Seleccione etapa")
        )
        bd() %>% pluck("respuesta") %>% filter(IdEtapa == input$etapa) %>% count(IdPregunta) %>%
            ggplot(aes(x = factor(IdPregunta), y = n, label = n)) + geom_col(fill = "#126782",
                                                                             width = .7, alpha =.8) +
            geom_label(label.size = 0.9) + theme_minimal()+
            labs(y = "Respuestas", x = "Pregunta")+
            theme(panel.grid.minor = element_blank())

    })

    output$respuesta_cat <- renderValueBox({
        validate(
            need(input$etapa == 2, "Elija etapa 2")
        )
        valueBox(value = bd() %>% pluck("respuesta_cat") %>% count(IdUsuario) %>% tally() %>% pull(1),
                 subtitle = "Finalizaron categorización",
                 color = "aqua", icon = icon("tag")
        )
    })

    output$importancia_cat <- renderValueBox({
        validate(
            need(input$etapa == 2, "Elija etapa 2")
        )
        valueBox(value = bd() %>% pluck("orden_cat") %>% count(IdUsuario) %>% tally() %>% pull(1),
                 subtitle = "Finalizaron importancia",
                 color = "teal", icon = icon("list-ul")
        )

    })

    output$cumplimiento_cat <- renderValueBox({
        validate(
            need(input$etapa == 2, "Elija etapa 2")
        )
        valueBox(value = bd() %>% pluck("calif_cat") %>% count(IdUsuario) %>% tally() %>% pull(1),
                 subtitle = "Finalizaron cumplimiento",
                 color = "fuchsia", icon = icon("list")
        )

    })
}

# Run the application
shinyApp(ui = ui, server = server)
