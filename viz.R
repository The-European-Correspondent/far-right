library(tidyverse)

# ── 1. Load & clean ──────────────────────────────────────────────────────────
df <- read_delim("data/full_data.csv", delim = ";", show_col_types = FALSE) |>
  mutate(
    vote_share    = as.numeric(vote_share),
    election_date = as.Date(election_date)
  ) |>
  filter(!is.na(election_date), !is.na(vote_share), vote_share > 0)

# sort the facets by share of votes to far-right parties in the most recent election per country
far_right_share <- df |>
  filter(far_right == "far-right") |>
  group_by(country_name) |>
  filter(election_date == max(election_date)) |>
  summarise(far_right_share = sum(vote_share), .groups = "drop")

# countries without a far-right party (e.g. Malta, Ireland) get 0 share and sort last
facet_order <- df |>
  distinct(country_name) |>
  left_join(far_right_share, by = "country_name") |>
  mutate(far_right_share = replace_na(far_right_share, 0)) |>
  arrange(desc(far_right_share)) |>
  pull(country_name)

# ── 2. Tile boundaries from DISTINCT election dates per country ───────────────
# (The bug: lead() on party rows gives wrong xmax — must work on distinct dates first)
mean_gaps <- df |>
  distinct(country_name, election_date) |>
  arrange(country_name, election_date) |>
  group_by(country_name) |>
  summarise(
    mean_gap = mean(as.numeric(diff(election_date)), na.rm = TRUE),
    .groups  = "drop"
  ) |>
  mutate(mean_gap = if_else(is.na(mean_gap) | is.nan(mean_gap), 365 * 4, mean_gap))

tile_bounds <- df |>
  distinct(country_name, election_date) |>
  arrange(country_name, election_date) |>
  group_by(country_name) |>
  mutate(xmin = election_date,
         xmax = lead(election_date)) |>
  ungroup() |>
  left_join(mean_gaps, by = "country_name") |>
  mutate(xmax = if_else(is.na(xmax),
                        xmin + as.integer(round(mean_gap)),
                        xmax)) |>
  select(country_name, election_date, xmin, xmax)

# ── 3. Stack order: far-right at BOTTOM, other on top (both desc vote_share) ─
df_stacked <- df |>
  left_join(tile_bounds, by = c("country_name", "election_date")) |>
  mutate(fr_order = case_when(
  far_right == "far-right"      ~ 0L,
  far_right == "not far-right"  ~ 1L,
  TRUE                          ~ 2L
)) |>
  arrange(country_name, election_date, fr_order, desc(vote_share)) |>
  group_by(country_name, election_date) |>
  mutate(ymax = cumsum(vote_share),
         ymin = ymax - vote_share) |>
  ungroup()

# ── 4. Year label data ────────────────────────────────────────────────────────
year_labels <- tile_bounds |>
  mutate(label = paste0("'", format(election_date, "%y")))

# ── 5. Colors & layout ────────────────────────────────────────────────────────
C_FAR   <- "#b22222"
C_NOT_FAR <- "#2980b9"
C_OTHER <- "#b8b8b8"
BG      <- "white"

ncols <- 5L
nrows <- ceiling(n_distinct(df_stacked$country_name) / ncols)

# ── 6. Plot ──────────────────────────────────────────────────────────────────
p <- ggplot(df_stacked) +
  geom_rect(
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = far_right),
    colour = "black", linewidth = 0.12
  ) +
  # Year labels sit just below each bar at the election date
  geom_text(
    data = year_labels,
    aes(x = xmin, y = -Inf, label = label),
    vjust = 1.5, hjust = 0, size = 1.9, colour = "#444444",
    inherit.aes = FALSE
  ) +
  scale_fill_manual(
    values = c("far-right"     = C_FAR,
               "not far-right" = C_NOT_FAR,
               "other" = C_OTHER),
    labels = c("far-right"     = "Far-right",
               "not far-right" = "Other parties"),
    name = NULL
  ) +
  scale_x_date(expand = c(0, 0)) +
  # free_x: each panel has its own date range; y is shared so bars are comparable
  scale_y_continuous(expand = expansion(mult = c(0.12, 0.02))) +
  coord_cartesian(clip = "off") +
  facet_wrap(~ factor(country_name, levels = facet_order), ncol = ncols, scales = "free_x") +
  labs(
    title   = "Party vote share in national elections",
    caption = "Far-right parties stacked at the bottom. Bar width = time to next election.",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 8) +
  theme(
    plot.background   = element_rect(fill = BG, colour = NA),
    panel.background  = element_rect(fill = BG, colour = NA),
    panel.grid        = element_blank(),
    axis.text         = element_blank(),
    axis.ticks        = element_blank(),
    strip.text        = element_text(face = "bold", size = 8, hjust = 0),
    legend.position   = "top",
    legend.justification = "left",
    legend.text       = element_text(size = 8),
    plot.title        = element_text(face = "bold", size = 13),
    plot.caption      = element_text(size = 7, colour = "#777777"),
    plot.margin       = margin(t = 8, r = 8, b = 24, l = 8)
  )

ggsave(
  "visuals/stacked_bar.svg", p,
  width  = ncols * 3,
  height = nrows * 2.6,
  units  = "in"
)

message("Saved → stacked_bar.svg")

# save as a png too
ggsave(
  "visuals/stacked_bar.png", p,
  width  = ncols * 3,
  height = nrows * 2.6,
  units  = "in"
)
message("Saved → stacked_bar.png")
