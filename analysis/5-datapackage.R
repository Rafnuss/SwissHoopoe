library(GeoLocatoR)
library(zen4R)

## Retrieve Zenodo data
zenodo <- ZenodoManager$new(token = keyring::key_get(service = "ZENODO_PAT"))
z <- zenodo$getDepositionByDOI("10.5281/zenodo.14439690")
pkg <- zenodoRecord2gldp(z)

# Add data
pkg <- pkg %>% add_gldp_geopressuretemplate()

# some Acce and mag data missing for 16AQ 12BA
measurements(pkg) <- measurements(pkg) %>%
  filter(!is.na(value))

# Check package
# plot(pkg)
validate_gldp(pkg)

# Add tags and observations
tags(pkg) <- read_csv("data/tags.csv")
observations(pkg) <- read_csv( "data/observations.csv")

measurements(pkg) %>%
  filter(is.na(value)) %>%
  pull(sensor) %>%
  unique()

#################
# Write datapackage

## Option 1: Manual
# https://zenodo.org/uploads/new
pkg$id <- "https://doi.org/10.5281/zenodo.{ZENODO_ID - 1}"
# e.g. "10.5281/zenodo.14620590" for a DOI reserved as 10.5281/zenodo.14620591
# Update the bibliographic citation with this new DOI
pkg <- pkg %>% update_gldp_bibliographic_citation()

dir.create("data/datapackage", showWarnings = FALSE)
frictionless::write_package(pkg, "data/datapackage/")

# Use the information in datapackage.json to fill the zenodo form.

## Option 2: API
# Create token and Zenodo manager
# https://zenodo.org/account/settings/applications/tokens/new/
keyring::key_set_with_value("ZENODO_PAT", password = "{your_zenodo_token}")
zenodo <- ZenodoManager$new(token = keyring::key_get(service = "ZENODO_PAT"))

# Create a zenodo from data package
z <- gldp2zenodoRecord(pkg)

z <- zenodo$depositRecord(z, reserveDOI = TRUE, publish = FALSE)

pkg$id <- paste0("https://doi.org/", z$getConceptDOI())
pkg <- pkg %>%
  update_gldp()

write_package(pkg, directory = "data/datapackage/")
for (f in list.files(pkg$version)) {
  zenodo$uploadFile(file.path(pkg$version, f), z)
}


#################
# Update zenodo
z_updated <- zenodo$getDepositionByConceptDOI(z$getConceptDOI())
pkg <- zenodoRecord2gldp(z_updated, pkg)


## Make sure to submit to Zenodo community: https://zenodo.org/communities/geolocator-dp/
