#' Fuerza un locale UTF-8 para el proceso actual si no hay uno ya activo
#'
#' `quarto::quarto_render()` lanza un subproceso de R que hereda las
#' variables de entorno del proceso actual. Sin un locale UTF-8 (comun en
#' Docker/servidores sin configurar, o en shells sin `LANG`/`LC_ALL`), ese
#' subproceso cae en el locale `"C"` y el texto con acentos/eñes se corrompe
#' a escapes tipo `"<U+00E9>"` en el HTML final -- los bytes que llegan de la
#' base de datos ya son UTF-8 correcto, es la impresión/formateo bajo locale
#' `"C"` lo que los rompe.
#'
#' @return (function) Una función sin argumentos que restaura `LC_ALL`/`LANG`
#'   a su valor previo. Si ya había un locale UTF-8 activo, no cambia nada y
#'   la función de restauración no hace nada.
#' @keywords internal
asegurar_locale_utf8 <- function() {
    actual <- Sys.getenv(c("LC_ALL", "LANG"))
    if (any(grepl("UTF-8", actual, ignore.case = TRUE))) {
        return(function() invisible(NULL))
    }
    Sys.setenv(LC_ALL = "en_US.UTF-8", LANG = "en_US.UTF-8")
    function() {
        if (nzchar(actual["LC_ALL"])) Sys.setenv(LC_ALL = actual["LC_ALL"]) else Sys.unsetenv("LC_ALL")
        if (nzchar(actual["LANG"])) Sys.setenv(LANG = actual["LANG"]) else Sys.unsetenv("LANG")
    }
}

#' @title Crear un archivo HTML de abp_ao
#'
#' @description
#' Esta función crea un archivo `.qmd` y la extensión necesaria en el directorio `_extensions` para generar reportes específicos.
#'
#' @param file_name Nombre del archivo `.qmd` que se va a crear. Debe ser una cadena de caracteres.
#' @param ext_name Nombre de la extensión. Por defecto es `"abp_ao"`.
#' @param qmd_name Nombre (sin extensión) de la plantilla `.qmd` dentro de la
#'   extensión a usar como base. Por defecto es igual a `ext_name` (la
#'   plantilla original). Otras plantillas que vivan en la misma carpeta de
#'   extensión, como `"abp_ao_categorias"`, se seleccionan pasando este
#'   parámetro.
#'
#' @return
#' No devuelve un valor, pero crea los archivos necesarios en el sistema de archivos.
#'
#' @export
crear_abp_ao_html <- function(file_name = NULL,
                               ext_name = "abp_ao",
                               qmd_name = ext_name) {
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
    qmd_origen <- file.path(ext_dir, paste0(qmd_name, ".qmd"))
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
#' @param url URL de la API de resumen a usar (opcional). Solo tiene efecto en
#'   plantillas `.qmd` que declaren un parámetro `url` (p.ej.
#'   `abp_ao_categorias`) -- permite apuntar a un endpoint distinto al que la
#'   plantilla trae por defecto, como el pipeline multiagente.
#'
#' @return
#' No devuelve un valor, pero genera un archivo HTML con el reporte renderizado.
#' @import quarto
#' @export
renderizar_reporte <- function(input_file, output_file, sesion, proyecto, pregunta, resumen_general = "F", Database = NULL, Server = NULL, UID = NULL, PWD = NULL, url = NULL){
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
        "PWD" = PWD,
        "url" = url
    ) |>
        purrr::compact()

    # quarto_render() lanza un subproceso de R que hereda las variables de
    # entorno actuales. Sin un locale UTF-8 (comun en Docker/servidores sin
    # configurar, o en shells sin LANG/LC_ALL), ese subproceso cae en el
    # locale "C" y el texto con acentos/enies se corrompe a escapes tipo
    # "<U+00E9>" en el HTML final -- los bytes que llegan de la base de datos
    # ya son UTF-8 correcto, es la impresion/formateo bajo locale "C" lo que
    # los rompe.
    restaurar_locale <- asegurar_locale_utf8()
    on.exit(restaurar_locale(), add = TRUE)

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
