# abpvirtualr 0.1.0

Primera versión con puerta de calidad (ver `Roadmap.md`).

* Credenciales de BD fuera del código (`leer_base()` lee `ABPVIRTUAL_DB_*` de
  variables de entorno).
* `corte()` usa `parametros$cortes` de forma explícita (antes dependía de
  *partial matching* accidental sobre `parametros$corte`).
* `altisonantes` se carga como *lazy data* del paquete en vez de una ruta
  relativa, por lo que `procesar_p_abierta()`, `procesar_brecha()`,
  `procesar_r_tema()` y `procesar_bigramas()` funcionan sin importar el
  working directory.
* `Imports` limpiado: se quitan `spatstat.core` (archivado en CRAN y sin uso),
  `tm`, `wordcloud` y `RColorBrewer`; se declara `DT`.
* Suite de pruebas (`tests/testthat/`) como gate antes de aceptar cambios.
