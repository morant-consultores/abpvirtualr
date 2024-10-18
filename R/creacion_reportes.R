#' @title Crear un archivo HTML de abp_ao
#'
#' @description
#' Esta función crea un archivo `.qmd` y la extensión necesaria en el directorio `_extensions` para generar reportes específicos.
#'
#' @param file_name Nombre del archivo `.qmd` que se va a crear. Debe ser una cadena de caracteres.
#' @param ext_name Nombre de la extensión. Por defecto es `"abp_ao"`.
#'
#' @return
#' No devuelve un valor, pero crea los archivos necesarios en el sistema de archivos.
#'
#' @export
crear_abp_ao_html <- function(file_name = NULL,
                               ext_name = "abp_ao") {
    # Validación de parámetros
    if (is.null(file_name) || !is.character(file_name) || file_name == "") {
        stop("Debe proporcionar un 'file_name' válido y no vacío de tipo carácter.")
    }

    if (!is.character(ext_name) || ext_name == "") {
        stop("El 'ext_name' debe ser una cadena de caracteres no vacía.")
    }

    # Verificar extensiones disponibles
    extensiones_disponibles <- c("abp_ao")
    if (!ext_name %in% extensiones_disponibles) {
        stop(paste("La extensión", shQuote(ext_name), "no está disponible en el paquete. Extensiones disponibles:", paste(extensiones_disponibles, collapse = ", ")))
    }

    # Verificar si existe el directorio '_extensions'
    if(!dir.exists("_extensions")) {
        dir.create("_extensions")
        message("Carpeta '_extensions' creada")
    }

    # Crear carpeta de extensión
    ext_dir <- file.path("_extensions", ext_name)
    if(!dir.exists(ext_dir)) {
        dir.create(ext_dir)
    }

    # Copiar desde los archivos internos
    origen <- system.file(paste0("ext_data/_extensions/", ext_name), package = "abpvirtualr")
    if (origen == "") {
        stop("No se pudo encontrar la extensión en el paquete 'abpvirtualr'.")
    }

    file.copy(
        from = origen,
        to = "_extensions/",
        overwrite = TRUE,
        recursive = TRUE,
        copy.mode = TRUE
    )

    # Verificar que los archivos de extensión fueron movidos
    n_files <- length(dir(ext_dir))

    if(n_files >= 2){
        message(paste(ext_name, "fue instalada en la carpeta '_extensions' en el directorio de trabajo actual."))
    } else {
        stop("Parece que la extensión no fue creada correctamente.")
    }

    # Crear nuevo reporte qmd basado en el esqueleto
    qmd_origen <- file.path(ext_dir, paste0(ext_name, ".qmd"))
    qmd_destino <- paste0(file_name, ".qmd")

    if (!file.exists(qmd_origen)) {
        stop(paste("El archivo", shQuote(qmd_origen), "no existe."))
    }

    file.copy(qmd_origen, qmd_destino)

    message("Archivo", shQuote(qmd_destino), "creado exitosamente.")
}



#' @title Renderizar reporte
#'
#' @description
#' Esta función renderiza un reporte Quarto utilizando parámetros específicos y verifica que el archivo de entrada exista en el directorio correspondiente.
#'
#' @param input_file Nombre del archivo de entrada (sin extensión) ubicado en el directorio `_extensions`.
#' @param output_file Nombre del archivo HTML de salida (sin extensión).
#' @param sesion Identificador de la sesión.
#' @param proyecto Nombre del proyecto.
#' @param pregunta Pregunta o descripción para el reporte.
#' @param resumen_general Indica si se debe incluir un resumen general. Valores posibles: `"F"` (falso) o `"T"` (verdadero).
#' @param Database Nombre de la base de datos (opcional).
#' @param Server Servidor de la base de datos (opcional).
#' @param UID Usuario de la base de datos (opcional).
#' @param PWD Contraseña de la base de datos (opcional).
#'
#' @return
#' No devuelve un valor, pero genera un archivo HTML con el reporte renderizado.
#' @import quarto
#' @export
renderizar_reporte <- function(input_file, output_file, sesion, proyecto, pregunta, resumen_general = "F", Database = NULL, Server = NULL, UID = NULL, PWD = NULL){
    # Validación de parámetros obligatorios
    if (missing(input_file) || !is.character(input_file) || input_file == "") {
        stop("Debe proporcionar un 'input_file' válido y no vacío de tipo carácter.")
    }

    if (missing(output_file) || !is.character(output_file) || output_file == "") {
        stop("Debe proporcionar un 'output_file' válido y no vacío de tipo carácter.")
    }

    if (missing(sesion) || !is.character(sesion) || sesion == "") {
        stop("El parámetro 'sesion' es obligatorio y debe ser una cadena de caracteres no vacía.")
    }

    if (missing(proyecto) || !is.character(proyecto) || proyecto == "") {
        stop("El parámetro 'proyecto' es obligatorio y debe ser una cadena de caracteres no vacía.")
    }

    if (missing(pregunta) || !is.character(pregunta) || pregunta == "") {
        stop("El parámetro 'pregunta' es obligatorio y debe ser una cadena de caracteres no vacía.")
    }

    if (!resumen_general %in% c("F", "T")) {
        stop("El parámetro 'resumen_general' debe ser 'F' (falso) o 'T' (verdadero).")
    }

    # Construir el nombre completo del archivo de entrada con extensión y directorio
    input_file_full <- file.path(paste0(input_file, ".qmd"))

    # Verificar si el archivo de entrada existe en el directorio especificado
    if(!file.exists(input_file_full)){
        stop(paste("El archivo de entrada", shQuote(input_file_full), "no existe en el directorio '_extensions'. Por favor, asegúrese de que el archivo esté correctamente ubicado."))
    }

    # Preparar parámetros, eliminando valores NULL
    parametros <- list(
        "sesion" = sesion,
        "proyecto" = proyecto,
        "pregunta" = pregunta,
        "resumen_general" = resumen_general,
        "Database" = Database,
        "Server" = Server,
        "UID" = UID,
        "PWD" = PWD
    ) |>
        purrr::compact()

    # Renderizar el reporte usando Quarto
    tryCatch({
        quarto::quarto_render(
            input = input_file_full,
            output_file = paste0(output_file, ".html"),
            execute_params = parametros
        )
        message("Reporte renderizado exitosamente y guardado como", shQuote(paste0(output_file, ".html")))
    }, error = function(e) {
        stop("Ocurrió un error al renderizar el reporte: ", e$message)
    })
}
