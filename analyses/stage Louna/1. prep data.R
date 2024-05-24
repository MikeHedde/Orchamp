# @title
# Data preparation 
# 
# @description
# Préparation du jeu de données à traiter
# 
# @objectif
# Fusionner les jeux de données, homogénéiser la taxo, préparer les colonnes d'intérêt 
#
# @details
# 0. Interrogation de la base de données Eco&Sols et de INaturalist pour récupérer les données d'occurrence
# 1. Fusion des données et homogénéisation taxonomique
# 2. Export d'un fichier de données propres


# Libraries
librarian::shelf(tidyr, dplyr, ggplot2, rinat, RODBC, stringr, rgnparser)

# Database queries 
## Alternative: importing data from a csv file
# df0 <- read.csv("data/raw-data/Macrofaune_Orchamp_2021_2022.csv", h=T, sep = ";")

## Better way : Connection to Mike's Access database
### Set up driver info and database path
DRIVERINFO <- "driver={Microsoft Access Driver (*.mdb, *.accdb)};"
MDBPATH <- "data/raw-data/fds_230425.accdb"
PATH <- paste0(DRIVERINFO, "DBQ=", MDBPATH)

### Establish connection

channel <- odbcDriverConnect(PATH)
sqlTables(channel)


### Load Orchamp data into R dataframe
### Set up driver info and database path
#DRIVERINFO <- "driver={CData ODBC Driver for Microsoft Access};"
DRIVERINFO <- "driver={Microsoft Access Driver (*.mdb, *.accdb)};"
MDBPATH <- "data/raw-data/fds_230530.accdb"
PATH <- paste0(DRIVERINFO, "DBQ=", MDBPATH)

### Establish connection
channel <- odbcDriverConnect(PATH)
sqlTables(channel)


### Load Orchamp data into R dataframe
df0 <- sqlFetch(channel,"Orchamp_matrix")
df0 <- rename(df0, Valid.Name="Valid Name")

### Close and remove channel
close(channel)
rm(channel)

## Getting valid and homogenized taxonomic names
uniqueNames_raw <- tibble(name = unique(df0$Valid.Name))

#Importation de my taxon checker function 
source("analyses/functions/my_taxonChecker function code.R")
valid_names <- my_taxonChecker(uniqueNames_raw$name)  

## Merging the taxonomic backbone to the observations
df1 <- left_join(df0, valid_names, by = c("Valid.Name" = "initial")) %>%
  #select(!c(canonic, Valid.Name, scientificName)) %>%
  filter(familyName == "Carabidae", method == "barber") %>%
  separate(id_plot, c("gradient", "alti"))

## Save dataset
write.csv(df1, file = paste0("data/derived-data/Esp/clean_data_" , as.character(Sys.Date()) , ".csv"))
