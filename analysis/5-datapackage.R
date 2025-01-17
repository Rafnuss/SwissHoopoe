library(GeoLocatoR)
library(zen4R)

## Retrieve Zenodo data
zenodo <- ZenodoManager$new(token = keyring::key_get(service = "ZENODO_PAT"))
z <- zenodo$getDepositionByDOI("10.5281/zenodo.14439690")

# Add data
pkg0 <- zenodoRecord2gldp(z) %>% add_gldp_geopressuretemplate()
pkg <- pkg0

# Remove test/calib data on some tags
measurements(pkg) <- measurements(pkg) %>%
  filter(!( tag_id %in% c("12HM", "12HN", "12HS", "12HV") & datetime < as.POSIXct("2015-05-01") ) )

pkg2 <- pkg
measurements(pkg2) <- measurements(pkg) %>%
  filter(tag_id %in% (measurements(pkg) %>% filter(sensor=="pressure") %>% pull(tag_id) %>% unique()))
plot(pkg)

# Check package
# plot(pkg)
validate_gldp(pkg)

# Write package
frictionless::write_package(pkg, "data/datapackage/")

#upload
for (f in list.files(pkg$version)) {
  zenodo$uploadFile(file.path(pkg$version, f), z)
}

