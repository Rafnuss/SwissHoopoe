library(GeoLocatoR)
library(tidyverse)
library(readxl)
# Generation of the data

# Root folder of the dataset (typically the Z-drive)
soi_data_directory <- "/Users/rafnuss/Library/CloudStorage/OneDrive-Vogelwarte/2-geolocator_data/UNIT_Vogelzug"

# Load the geolocator (GDL) database from the access file
gdl0 <- read_gdl(access_file = file.path(soi_data_directory, "database/GDL_Data.accdb"), filter_col = FALSE)

o <- read_excel("data/observations.xlsx")

# Check observations
GeoLocatoR:::validate_gldp_observations(o)

t <- read_excel("data/tags.xlsx")

gdl <- gdl0 %>%
  filter(GDL_ID %in% t$tag_id & !is.na(GDL_ID)) %>%
  filter(!(DataID %in% c(7169, 7172, 7168))) %>%  # Exclude alpine swift with same gdl_id
  filter(!is.na(OrderName)) %>%
  mutate(
    OrderName = ifelse(OrderName=="UpoEpoCH11", "UpuEpoCH11", OrderName),
    OrderName = ifelse(OrderName=="UpoEpoCH10", "UpuEpoCH10", OrderName)
  )

gdl <- GeoLocatoR:::add_gldp_soi_directory(gdl, file.path(soi_data_directory, "data"))

# Tag without data
gdl %>%
  filter(is.na(directory)) %>%
  filter(GDL_ID %in% (o %>% filter(observation_type=="retrieval") %>% .$tag_id)) %>%
  .$GDL_ID

# Tag retrieved without data
o %>%
  filter(!is.na(tag_id)) %>%
  filter(observation_type=="retrieval") %>%
  filter(!(tag_id %in% gdl$GDL_ID)) %>%
  .$tag_id %>% unique()

pkg <- create_gldp(title="dummy", contributors=list()) %>%
  add_gldp_soi(
    gdl = gdl,
    directory_data = file.path(soi_data_directory, "data")
  )

plot(pkg)


observations(pkg) <- o
tags(pkg) <- t


validate_gldp(pkg)

create_geopressuretemplate("~/Downloads/test1/",pkg, open = F)


pkg2=pkg
measurements(pkg2) <- measurements(pkg2) %>%  filter(tag_id=="16AQ")

withr::with_dir("/Users/rafnuss/Downloads/test1", {
GeoLocatoR:::create_geopressuretemplate_data(pkg2)
})
