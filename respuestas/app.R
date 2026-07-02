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
library(abpvirtualr)

# leer_base() se usa tal cual la expone el paquete (R/utilitaria_colectar_base.R),
# que lee las credenciales de conexión desde variables de entorno (ver README.md).

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
