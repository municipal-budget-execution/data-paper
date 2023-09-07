glance_custom.fixest <- function(x, ...) {
  dv <- insight::get_response(x)
  dv <- sprintf("%.2f", mean(dv, na.rm = TRUE))
  data.table::data.table(`Mean of DV` = dv)
}