#' Show the summary proportion in a widget
#'
#' A `sqlDT` displays a single statistic derived from a linked table, where
#' the numerator and denominator columns are specific. This is best used with
#' the `crosstalk`package, to allow dynamic filtering of the underlying data.
#'
#' @param data A data frame or data table containing the data to summarize,
#' with at least two numeric columns: one for the numerator and one for the
#' denominator. Normally, this should be an instance of [crosstalk::SharedData].
#' @param query A SQL query string to filter the data before calculating the statistic.
#' The `?` placeholder will be replaced with the data specified in the function.
#' For example: "SELECT * FROM ?"
#' @param options A list of options to customize the DataTable display. See [DataTables options](https://datatables.net/reference/option/) for available settings.
#' @param width The width of the widget (optional).
#' @param height The height of the widget (optional).
#' @param elementId An optional element ID for the widget.
#'
#' @import crosstalk
#' @import htmlwidgets
#'
#' @export
#'
#' @examples
#' library(sqlDT)
#' data_iris <- iris
#' names(data_iris) <- c("SepalLength", "SepalWidth", "PetalLength", "PetalWidth", "Species")
#' sqlDT(data_iris, query = "SELECT Species, round(sum(SepalLength)/count(*), 2) as Average_Sepal_Length FROM ? GROUP BY Species")
#'
sqlDT <- function(
  data,
  query,
  options = NULL,
  width = '100%',
  height = '100%',
  elementId = NULL
) {

  if (is.SharedData(data)) {
    # Using Crosstalk
    key <- data$key()
    group <- data$groupName()
    data <- data$origData()
  } else {
    # Not using Crosstalk
    key <- NULL
    group <- NULL
  }

  # Add checks for correct SQL query (i.e. "FROM ?")
  if (!grepl("FROM \\?", query, ignore.case = TRUE)) {
    stop("The SQL query must contain 'FROM ?' to indicate the data source.")
  }

  # Add check for column names in data meeting SQL requirements
  if (any(grepl("\\s", names(data)))) {
    stop("Column names in the data must not contain spaces.")
  }
  # Add check for column names for any non alphanumeric (except underscore)
  if (any(!grepl("^[A-Za-z0-9_]+$", names(data)))) {
    stop("Column names in the data must be alphanumeric or underscores only.")
  }

  # forward options using x
  x <- list(
    data = data,
    settings = list(
      query = query,
      options = options,
      crosstalk_key = key,
      crosstalk_group = group
    )
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'sqlDT',
    x,
    width = width,
    height = height,
    dependencies = crosstalk::crosstalkLibs(),
    package = 'sqlDT',
    elementId = elementId
  )
}

#' Shiny bindings for sqlDT
#'
#' Output and render functions for using sqlDT within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a sqlDT
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name sqlDT-shiny
#'
#' @export
sqlDTOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'sqlDT', width, height, package = 'sqlDT')
}

#' @rdname sqlDT-shiny
#' @export
rendersqlDT <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, sqlDTOutput, env, quoted = TRUE)
}
