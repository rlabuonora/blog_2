library(shiny)
library(readr)

sales <- readr::read_csv("https://raw.githubusercontent.com/hadley/mastering-shiny/master/sales-dashboard/sales_data_sample.csv")
sales <- sales[c(
    "TERRITORY", "ORDERDATE", "ORDERNUMBER", "PRODUCTCODE",
    "QUANTITYORDERED", "PRICEEACH"
)]

ui <- fluidPage(
    selectInput("territory", "territory", choices = unique(sales$TERRITORY)),
    tableOutput("selected")
)
server <- function(input, output, session) {
    selected <- reactive(subset(sales, sales$TERRITORY %in% input$territory))
    output$selected <- renderTable(head(selected(), 10))
}

# Run the application 
shinyApp(ui = ui, server = server)
