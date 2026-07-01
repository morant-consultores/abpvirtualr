---
name: add-function
description: Scaffold a new exported R function with complete roxygen2 documentation in R/. Enforces package conventions.
---

Create a new R function in `R/<filename>.R` following the package's existing conventions.

Ask the user for:
- Function name (snake_case)
- One-line purpose (becomes `@title`)
- Each parameter: name, type in parentheses, description
- Return value description
- Which packages the function imports (for `@import` tags)
- Which existing file to add it to, or a new filename

Then generate the function scaffold:

```r
#' <title>
#'
#' @description
#' <description>
#'
#' @param <name> (<type>) <description>
#'
#' @return <return description>
#' @export
#'
#' @import <package>
#'
<function_name> <- function(<params>) {

}
```

Rules:
- Never add comments inside the function body unless the logic is non-obvious
- Use `glue::glue()` for string interpolation, not `paste()`
- Use tidyverse style: pipe (`|>`), `dplyr`/`tidyr` over base R loops
- After writing, the PostToolUse hook will run `devtools::document()` automatically
