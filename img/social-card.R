# Social share card for "R, Databases & SQL" (1200 x 630 px).
#
#   Rscript img/social-card.R      # run from the project root
#
# White canvas, dark title, brand-blue accent bar, the book cover on the right
# third, and the site address bottom left. Everything is drawn with ggplot2 and
# rendered with ragg; the only asset is the book's own cover (img/rdbsql.png).

library(ggplot2)
library(ragg)
library(png)
library(systemfonts)

W <- 1200             # canvas width, px
H <- 630              # canvas height, px (the 1.91:1 link-preview ratio)
M <- 64               # margin from every edge, px (spec asks for >= 40)

ink       <- "#0f172a"  # title
muted     <- "#475569"  # subtitle, site address
brand     <- "#2563eb"  # accent

# ---- type -------------------------------------------------------------------
# ggplot2 sizes are in mm; at res = 72 dpi one point is one pixel, so convert
# the pixel sizes we want into mm.
px <- function(x) x * 25.4 / 72.27

available <- system_fonts()$family
pick_font <- function(candidates) {
  hit <- candidates[candidates %in% available]
  if (length(hit)) hit[[1]] else "sans"
}
family <- pick_font(c("Inter", "Segoe UI", "Helvetica Neue", "Arial", "DejaVu Sans"))

# Shrink a label until it fits the left column.
fit_px <- function(label, start, max_width, weight = "normal") {
  size <- start
  while (size > 12 &&
         string_width(label, family = family, weight = weight, size = size,
                      res = 72) > max_width) {
    size <- size - 0.5
  }
  size
}

# ---- layout -----------------------------------------------------------------
left <- M                                  # left edge of the text column
right <- W - M                             # right edge of the cover
col_width <- 660                           # usable width of the text column

cover <- readPNG("img/rdbsql.png")
cover_h <- H - 2 * M
cover_w <- cover_h * dim(cover)[2] / dim(cover)[1]
cover_xmin <- right - cover_w
cover_xmax <- right
cover_ymin <- M
cover_ymax <- M + cover_h

title_px <- 68                             # well above the 48 px minimum
line_gap <- 78
subtitle <- "Connect R to SQLite, query with dbplyr and SQL"
subtitle_px <- fit_px(subtitle, 34, col_width)
primer_px <- 27
url_px <- 28

title_top <- H - M - 30                    # top line of the title
line3_top <- title_top - 2 * line_gap      # "& SQL"
subtitle_top <- line3_top - title_px - 30
primer_top <- subtitle_top - subtitle_px - 24
lines <- c("R, Databases", "& SQL", "")

p <- ggplot() +
  coord_cartesian(xlim = c(0, W), ylim = c(0, H), expand = FALSE) +
  theme_void() +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    plot.margin      = margin(0, 0, 0, 0)
  ) +
  annotation_raster(cover, cover_xmin, cover_xmax, cover_ymin, cover_ymax,
                    interpolate = TRUE) +
  # brand-blue accent above the title
  annotate("rect", xmin = left, xmax = left + 120, ymin = title_top + 26,
           ymax = title_top + 38, fill = brand, colour = NA) +
  annotate("text", x = left, y = title_top,
           label = lines[[1]], hjust = 0, vjust = 1,
           size = px(title_px), fontface = "bold", colour = ink,
           family = family) +
  annotate("text", x = left, y = title_top - line_gap,
           label = lines[[2]], hjust = 0, vjust = 1,
           size = px(title_px), fontface = "bold", colour = ink,
           family = family) +
  annotate("text", x = left, y = line3_top,
           label = lines[[3]], hjust = 0, vjust = 1,
           size = px(title_px), fontface = "bold", colour = ink,
           family = family) +
  annotate("text", x = left, y = subtitle_top,
           label = subtitle, hjust = 0, vjust = 1,
           size = px(subtitle_px), colour = muted, family = family) +
  annotate("text", x = left, y = primer_top,
           label = "Free 2-hour primer before R4DS", hjust = 0, vjust = 1,
           size = px(primer_px), colour = muted, family = family) +
  annotate("text", x = left, y = M,
           label = "rsquaredacademy.com", hjust = 0, vjust = 0,
           size = px(url_px), fontface = "bold", colour = brand,
           family = family)

ggsave(
  filename = "img/social-card.png",
  plot = p,
  width = W / 72, height = H / 72,   # inches; at res = 72 dpi -> 1200 x 630 px
  dpi = 72,
  device = agg_png,
  bg = "white"
)

message("wrote img/social-card.png")
