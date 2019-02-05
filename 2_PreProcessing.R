##--------(1) Script Description ------------------------------------------------------------------------
##
##
##
##  Project Name : WIFI Fingerprinting
##  Developer Name : Aurore Paligot
##  
##  Script Name : 2_PreProcessing
##  Description : Preprocessing the data
##  Current Status : In progress
##  Date of 1st Release : 22-01-2019
##  History versions : 2_Preprocessing - 22-01-2019
##
##  Outputs : AllData_Raw - Training and Validation data in one dataset, no other modifications
##
##  Related Scripts : 1_Libraries - script sourced to load libraries
##  
##  Comment : 
##--------(2) DoParallel -----------------------------------------------------------------------------------
##Begin Do Parallel to gain working memory: create and register cluster

cluster <- makeCluster ( 2 )

registerDoParallel ( cluster )

##--------(3) Loading libraries ---------------------------------------------------------------------------
#Loading libraries from the script 1_Libraries associated to the project

source ( file = "Scripts/Deliverable Scripts/1_Libraries.R" )

##--------(4) Importing & unite training and validation data --------------------------------------------------------------------------
#Loading training and validation data

TrainData <- read_csv ( "Data/UJIndoorLoc/trainingData.csv", 
                        col_types = cols(SPACEID = col_integer()))

ValData <- read_csv ( "Data/UJIndoorLoc/validationData.csv" )

#Creation of the column TYPE that refers to "training" and "validation"

TrainData <- TrainData %>% mutate ( TYPE = "training" ) 

ValData <- ValData %>% mutate ( TYPE = "validation" ) 

#Unification of the two subsets in one dataframe

AllData <- bind_rows( TrainData, ValData )

##--------(5) Remove duplicates ----------------------------------------------------------------------------------------------
#     637 duplicates are removed

AllData <- AllData %>% distinct()
 
##--------(6) Assining "-110" value to outliers (>-30 & <-80) and undetected WAPS (100)---------------------------
##Remarq: This process could be done more effectivly with an apply function

#Step 1 : Create a new data frame with inversed rows and columns

AllData <- AllData %>% mutate( OBS = row_number() )

AllData_Converted <- AllData %>%
  gather( WAP001 : WAP520,
          key = "WAPS",
          value = "RSSI" )

#Step 2 : Change values of undetected waps (100) to -110

AllData_Converted$RSSI [ AllData_Converted$RSSI == 100 ] <- -110

#Step 3: Change values of outliers (>-30 & <-80) to -110

AllData_Converted$RSSI [ AllData_Converted$RSSI <= -80 ] <- -110

AllData_Converted$RSSI [ AllData_Converted$RSSI >= -30 ] <- -110

#Step 4 : Reconvert the dataframe in its original form by re-spreading rows ans columns

AllData <- AllData_Converted %>% spread ( WAPS, RSSI )

##--------(7) Add a new colum with unique ID for SPACEID, RELATIVEPOSITION, PHONEID and USERID-----
#I create a new column "ID" with unique space, user and phone identifiers
#Longitude and Latitude are also added, cause sometimes
#same space, user,phone lead to different LOng and Lat
#I add this new column to my main dataframe

AllData_Copy <- AllData

AllData_Copy <- unite( AllData,
                       LONGITUDE,
                       LATITUDE,
                       SPACEID,
                       RELATIVEPOSITION,
                       USERID,
                       PHONEID,
                       col = "ID",
                       sep = "")

IDColumn <- AllData_Copy[, "ID"] #2782 unique levels

AllData <- cbind( AllData, IDColumn )

AllData$ID %<>% as.factor()

#Last thing I'm trying to do here is gather the data based on a single identifier
#I want to obtain the mean for when 10 captures where taken at the same place
#by the same user, phone, same lat and long, etc.
#First step is to create this identifier
#Second step is to "group_by". Attention: by doing so, don't forget
#to only select waps to average
#Also, cheking that these are really unique identifiers, to not create conflict
#A second strategy could by to sum up by SPACE ID altogether, once the scaling
#has been done row per row
#Be careful : This modification should be done on TRAINING ONLY
#Check the nature of the observation on VALIDATION
#If justified, move this step before reuninting the two data sets (training and validation)
