# zzz.R
.onLoad <- function(libname, pkgname) {
  shiny::addResourcePath(
    prefix = "Pictures",
    directoryPath = system.file(
      "Pictures",
      package = "FloraExam"
    )
  )
}

.onUnload <- function(libname, pkgname) {
  shiny::removeResourcePath("Pictures")
}
