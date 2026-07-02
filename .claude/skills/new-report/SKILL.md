---
name: new-report
description: Scaffold a new ABP Virtual report project from the xaringan template — copies the skeleton, wires up brand parametros, and drops in the credential template. Use when starting a new case.
---

Scaffold a new ABP Virtual report (xaringan `.Rmd`) for a new case, reusing the
`abpvirtualr` package. The goal is to reach a renderable report with the fewest
possible manual edits: brand config goes through `parametros_default()`, so the
user overrides only a handful of values instead of authoring the full list.

Ask the user for:
- **Destination directory** for the new report (created if missing).
- **Brand color** (`primario`, hex) — the rest of the palette has documented
  defaults; only ask for more if the user wants to override them.
- **Font family** (`familia`, a Google Font) — default "Poppins".
- **Report title / subtitle** for the slide header.
- **Session id** (`id_sesion`) if known, or leave `NULL` (latest session).

Steps:

1. **Copy the template** from
   `inst/rmarkdown/templates/abpvirtual-xaringan/skeleton/` into the destination:
   `skeleton.Rmd` (rename to something case-specific, e.g. `<caso>.Rmd`),
   `xaringan-themer.css`, and the `img/` assets if present.

2. **Wire the brand.** In the copied `.Rmd`, the `parametros` chunk should call
   `abpvirtualr::parametros_default()` overriding only what the user gave:
   ```r
   parametros <- abpvirtualr::parametros_default(
     primario = "<hex>",
     familia  = "<font>"
   )
   ```
   Do **not** re-expand the full 15-field list — that's the whole point of the
   helper. If the user needs a semáforo/cortes tweak, add just that argument.

3. **Set the header.** Update `title`, `subtitle`, and the logo `<img>` path in
   the YAML front matter to the case's values. Update the `id_sesion` argument
   in the `leer_base(...)` chunk if the user gave one.

4. **Credentials.** Copy `.Renviron.example` into the project root and tell the
   user to fill it in as `.Renviron` (it is gitignored). The report needs the
   `ABPVIRTUAL_DB_*` env vars — see the package README.

5. **Validate before rendering.** Confirm the brand config is well-formed
   without touching the DB:
   ```r
   Rscript -e 'library(abpvirtualr); source_rmd_params <- parametros_default(primario="<hex>", familia="<font>"); validar_parametros(source_rmd_params); cat("parametros OK\n")'
   ```
   (`parametros_default()` already validates, so a clean run means the palette
   is valid.)

6. **Hand off to `render-report`.** Once `.Renviron` is filled, the user (or the
   `render-report` skill) can preflight the DB and render. Do not attempt the
   render here unless the user asks — the DB may not be reachable yet.

Rules:
- Keep the `parametros` chunk minimal — overrides only.
- Never copy or create a `data/conexion.rda`; credentials live in env vars only.
- Preserve the per-etapa structure of the template (`slides_nubes`,
  `slides_etapa_2`) unless the user's case changes the etapas.
