# code/analysis/fig_validation_siconfi.R
# Outputs: Fig 3–5 and Fig A1–A4
#   Histograms of % difference between MiDES and SICONFI for
#   commitments, verifications, and payments (by municipality and by function).
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   commitment_municipality_year.csv
#   commitment_function_municipality_year.csv
#   verification_municipality_year.csv
#   verification_function_municipality_year.csv
#   payment_municipality_year.csv
#   payment_function_municipality_year.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

# ---- Helpers ----

STATES  <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")
CAP     <- 25   # cap proportions at ±25 pp for display

cap_proportion <- function(dt, col = "proportion") {
  dt[[col]] <- pmax(pmin(dt[[col]], CAP), -CAP)
  dt
}

# Build a 7-panel (one per state) histogram of proportion differences
make_histogram_plot <- function(dt, title_label) {

  # Ensure state ordering
  dt[, state := factor(state, levels = STATES)]

  # State-level mean labels
  means <- dt[, .(mean_val = mean(proportion, na.rm = TRUE)), by = state]

  ggplot(dt, aes(x = proportion)) +
    geom_histogram(bins = 60, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "black", linewidth = 0.5, linetype = "dashed") +
    geom_vline(data = means, aes(xintercept = mean_val),
               color = "#C0392B", linewidth = 0.7, linetype = "solid") +
    scale_x_continuous(title_label,
                       limits = c(-CAP - 0.5, CAP + 0.5),
                       breaks = seq(-20, 20, by = 10)) +
    scale_y_continuous("Frequency") +
    facet_wrap(~state, nrow = 2, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 11, y_text_size = 11, size = 12) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 11, family = "LM Roman 10"))
}

# ---- Load and prepare each dataset ----

load_and_prep <- function(filename, filter_rs_pre2010 = TRUE) {
  dt <- fread(file.path(input, filename))

  # Drop rows with infinite or NA proportions
  dt <- dt[is.finite(proportion) & !is.na(proportion)]

  # Exclude RS data before 2010 (known data quality issue)
  if (filter_rs_pre2010 && "year" %in% names(dt)) {
    dt <- dt[!(state == "RS" & year < 2010)]
  }

  # Keep only the states in sample
  dt <- dt[state %in% STATES]

  cap_proportion(dt)
}

# ---- Fig 3: Commitment (by municipality) ----

dt_comm <- load_and_prep("commitment_municipality_year.csv")
p_comm  <- make_histogram_plot(dt_comm, "% Difference (Commitment)")
ggsave(file.path(graph_output, "validation_siconfi_commitment.pdf"),
       p_comm, width = 12, height = 7, device = cairo_pdf)

# ---- Fig A1: Commitment (by function) ----

dt_comm_fn <- load_and_prep("commitment_function_municipality_year.csv")
p_comm_fn  <- make_histogram_plot(dt_comm_fn, "% Difference (Commitment by Function)")
ggsave(file.path(graph_output, "validation_siconfi_commitment_function.pdf"),
       p_comm_fn, width = 12, height = 7, device = cairo_pdf)

# ---- Fig 4: Verification (by municipality) ----

dt_verif <- load_and_prep("verification_municipality_year.csv")
p_verif  <- make_histogram_plot(dt_verif, "% Difference (Verification)")
ggsave(file.path(graph_output, "validation_siconfi_verification.pdf"),
       p_verif, width = 12, height = 7, device = cairo_pdf)

# ---- Fig A2: Verification (by function) ----

dt_verif_fn <- load_and_prep("verification_function_municipality_year.csv")
p_verif_fn  <- make_histogram_plot(dt_verif_fn, "% Difference (Verification by Function)")
ggsave(file.path(graph_output, "validation_siconfi_verification_function.pdf"),
       p_verif_fn, width = 12, height = 7, device = cairo_pdf)

# ---- Fig 5: Payment (by municipality) ----

dt_pay <- load_and_prep("payment_municipality_year.csv")
p_pay  <- make_histogram_plot(dt_pay, "% Difference (Payment)")
ggsave(file.path(graph_output, "validation_siconfi_payment.pdf"),
       p_pay, width = 12, height = 7, device = cairo_pdf)

# ---- Fig A3: Payment (by function) ----

dt_pay_fn <- load_and_prep("payment_function_municipality_year.csv")
p_pay_fn  <- make_histogram_plot(dt_pay_fn, "% Difference (Payment by Function)")
ggsave(file.path(graph_output, "validation_siconfi_payment_function.pdf"),
       p_pay_fn, width = 12, height = 7, device = cairo_pdf)

# ---- Fig A4a: Payment by year — PR ----

dt_pay_pr <- load_and_prep("payment_municipality_year.csv", filter_rs_pre2010 = FALSE)
dt_pay_pr <- dt_pay_pr[state == "PR" & year %in% 2013:2020]
dt_pay_pr[, year := factor(year)]

p_pr <- ggplot(dt_pay_pr, aes(x = proportion)) +
  geom_histogram(bins = 50, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "black", linewidth = 0.5, linetype = "dashed") +
  scale_x_continuous("% Difference (Payment — PR)",
                     limits = c(-CAP - 0.5, CAP + 0.5),
                     breaks = seq(-20, 20, by = 10)) +
  scale_y_continuous("Frequency") +
  facet_wrap(~year, nrow = 2, scales = "free_y") +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 11, y_text_size = 11, size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 11, family = "LM Roman 10"))

ggsave(file.path(graph_output, "validation_siconfi_payment_pr.pdf"),
       p_pr, width = 12, height = 7, device = cairo_pdf)

# ---- Fig A4b: Payment by year — MG ----

dt_pay_mg <- load_and_prep("payment_municipality_year.csv", filter_rs_pre2010 = FALSE)
dt_pay_mg <- dt_pay_mg[state == "MG" & year %in% 2014:2021]
dt_pay_mg[, year := factor(year)]

p_mg <- ggplot(dt_pay_mg, aes(x = proportion)) +
  geom_histogram(bins = 50, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "black", linewidth = 0.5, linetype = "dashed") +
  scale_x_continuous("% Difference (Payment — MG)",
                     limits = c(-CAP - 0.5, CAP + 0.5),
                     breaks = seq(-20, 20, by = 10)) +
  scale_y_continuous("Frequency") +
  facet_wrap(~year, nrow = 2, scales = "free_y") +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 11, y_text_size = 11, size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 11, family = "LM Roman 10"))

ggsave(file.path(graph_output, "validation_siconfi_payment_mg.pdf"),
       p_mg, width = 12, height = 7, device = cairo_pdf)
