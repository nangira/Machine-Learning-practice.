### Name: 
### Date: 
### Description: Mammographic Mass Data Set Analysis

#Goal: This data set can be used to predict the severity (benign or malignant)
# of a mammographic mass lesion from BI-RADS attributes and the patient's age.
# It contains a BI-RADS assessment, the patient's age and three BI-RADS attributes
# together with the ground truth (the severity field) for 516 benign and
# 445 malignant masses that have been identified on full field digital mammograms
# collected at the Institute of Radiology of the
# University Erlangen-Nuremberg between 2003 and 2006.


# Question 1: How is the severity(malignant or benign) of the cases across the different ages?

# Question 2: Based on the shapes, what was the severity of the cases?


# Installing and loading required packages.

install.packages("tidyverse")
install.packages("caTools")
install.packages("rpart")

library(tidyverse)
library(caTools)
library(rpart)

# Reading in the data using the url

mammodata <- read.csv(url("http://archive.ics.uci.edu/ml/machine-learning-databases/mammographic-masses/mammographic_masses.data"))

### DATA CLEANING :

## Labeling/Renaming columns.

names(mammodata)[1] <- "bI_RADS"
names(mammodata)[2] <-"age"
names(mammodata)[3] <- "shape"
names(mammodata)[4] <- "margin"
names(mammodata)[5] <- "density"
names(mammodata)[6] <- "severity"

colnames(mammodata) #Checking that the new column names are okay.

# First row of data was excluded when importing/reading in the data so next,
# we add it to the dataset.This was evident since there were 960 observations 
# as opposed to the 961 mentioned in the Data Set information.

row1 <- data.frame(5,67,3,5,3,1) # Creating a dataframe containing the missing row

# Naming the rows in the dataframe
names(row1) <- c("bI_RADS","age","shape", "margin","density","severity") 

#Adding the row to the dataset
mammographic_masses <- rbind(row1,mammodata)

# Viewing the structure of the dataset and summary of the variables in the dataset
str(mammographic_masses)
summary(mammographic_masses)

## In this next step, we will be:

# Assigning the right data types to the variables and coding them where necessary.
# This will help during the visualization process as the labels will be more understandable.
# BI_RADS and Density are supposed to be ordinal/factor variable, age is an interger, 
# shape and margin are nominal which will be coded as 'factor' variables and 
# Severity is a dummy variable.


# Using mutate(), we create new variables with the right coding as provided
# in the Data Information. This  is achieved using the ifelse() command. 

mammographicmasses <- mammographic_masses %>%
        mutate(BI_RADS = ifelse(bI_RADS == 1,"definitely benign",
                         ifelse(bI_RADS == 2, "benign findings",
                         ifelse(bI_RADS == 3, "probably benign",
                         ifelse(bI_RADS == 4, "suspicious abnormality",
                         ifelse(bI_RADS == 5, "highly suspicious of malignancy",
                         ifelse(bI_RADS == 6, "known biopsy with proven malignancy","incomplete"))))))) %>% 
        mutate(Age = ifelse(age == "?", " ", age )) %>% 
        mutate(Density =  ifelse(density == 1, "high",
                          ifelse(density == 2, "iso",
                          ifelse(density == 3,"low",
                          ifelse(density ==4, "fat-containing"," "))))) %>% 
        mutate(Shape =  ifelse(shape == 1, "round",
                        ifelse(shape == 2, "oval",
                        ifelse(shape == 3, "lobular",
                        ifelse(shape == 4, "irregular", " "))))) %>% 
        mutate(Margin = ifelse(margin == 1, "Circumscribed",
                        ifelse(margin == 2, "microlobulated",
                        ifelse(margin == 3, "obscured",
                        ifelse(margin == 4, "ill-defined",
                        ifelse(margin == 5, "spiculated", " ")))))) %>% 
        mutate(Severity = ifelse(severity == 0, "benign",
                          ifelse(severity == 1, "malignant", "")))
  
# Here we assign the levels and labels of the factor variables we created in the previous
# step. We also convert the non-factor variables into their right data types. In this case
# it's the Age variable which we transform using as.integer(). It will now be stored as an integer.
# This is important because we can be able to perform other actions such as finding mean with ease.
# mean of a value cannot be found on a variable that is of type 'character'.

mammographicmasses$BI_RADS <- factor(mammographicmasses$BI_RADS,
                                     levels = c("incomplete","definitely benign","benign findings","probably benign","suspicious abnormality","highly suspicious of malignancy"),
                                     labels = c("incomplete","definitely benign","benign findings","probably benign","suspicious abnormality","highly suspicious of malignancy"))

mammographicmasses$Age <- as.integer(mammographicmasses$Age)

mammographicmasses$Density <- factor(mammographicmasses$Density,
                                      levels = c("high","iso","low","fat-containing"),
                                      labels = c("high","iso","low","fat-containing"))

mammographicmasses$Shape <- factor(mammographicmasses$Shape,
                                    levels = c("round","oval","lobular","irregular"),
                                    labels = c("round","oval","lobular","irregular"))

mammographicmasses$Margin <- factor(mammographicmasses$Margin,
                                    levels = c("Circumscribed","microlobulated","obscured","ill-defined","spiculated"),
                                    labels = c("Circumscribed","microlobulated","obscured","ill-defined","spiculated"))
                                    
mammographicmasses$Severity <- factor(mammographicmasses$Severity,
                                      levels = c("benign","malignant"),
                                      labels = c("benign","malignant"))

# Viewing our dataset with the new variables we created above.

View(mammographicmasses)                 


# Dropping variables that are not coded and/or cleaned and remaining 
# with the new variables we had created.

mammographicmasses <- mammographicmasses %>% 
  select(-c(bI_RADS,age,density,shape,margin,severity))

# Ensuring all missing values are registered as NA

mammographicmasses[ mammographicmasses == "?"] <- NA
colSums(is.na(mammographicmasses))

# Removing NAs
mammographicmasses <- na.omit(mammographicmasses) 
colSums(is.na(mammographicmasses))

# Checking for outliers in our continuous variable: Age

outlier_values <- boxplot.stats(mammographicmasses$Age)$out

boxplot(mammographicmasses$Age, main="Age", boxwex=0.1)

mtext(paste("Outliers: ", paste(outlier_values, collapse=", ")), cex=0.6)

# There were no outliers.

### EXPLORATORY DATA ANALYSIS :

# First we run a code that will give us a summary of the variables in our data
summary(mammographicmasses)

# This is the theme that will be used in all visualizations. 

visualization_theme <- theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
                             axis.title = element_text(size = 14),
                             axis.text = element_text(size = 10),
                             axis.line = element_line(size = 1.5),
                             plot.subtitle = element_text(hjust = 0.5, size = 14),
                             plot.caption = element_text(face = "bold", size = 12),
                             panel.background = element_rect(fill = NA))

# The first bargraph will be used to answer our first question.
# Question 1: How is the severity(malignant or benign) of the cases across the different ages?
  
# Table and graph showing cases of different severity by age group


# First we check to see the highest and lowest age in our dataset
# na.rm() ensures that the missing values are not considered.

max(mammographicmasses$Age,na.rm = T)
min(mammographicmasses$Age,na.rm = T)

# Generating age groups

mammographicmassesdf <- mammographicmasses %>% 
      mutate(Age_group = ifelse(Age >= 18 & Age <= 34, "18 - 34",
                         ifelse(Age > 34 & Age <51, "35 - 50",
                         ifelse(Age > 50 & Age < 67, "51 - 66",
                         ifelse(Age > 66 & Age < 83, "67 - 82", "83 - 96")))))

# Creating the table that will be used to generate the bargraph

severityAge_table <- mammographicmassesdf %>% 
  group_by(Severity, Age_group) %>% 
  summarise(Count = n()) %>% ungroup() %>% 
  na.omit() %>%
  group_by(Severity) %>% 
  mutate(Perc = round(Count / sum(Count)*100,0))


age_severity <- ggplot(data = severityAge_table, aes(x = Age_group, y = Perc, fill = Severity,na.rm = T)) +
  geom_bar(stat = "identity",na.rm = T ) +
  geom_text(aes(label = paste0(Perc,"%")), hjust = 0.5, vjust = 1, size = 4, position = position_stack()) +
  visualization_theme+
  scale_y_continuous(labels = function(x) paste0(x, "%"))+
  scale_fill_manual(values = c("#F29E0F","#FF5062")) +
  labs(title = "Distribution of Observations based on their Age group and Severity of their cases",
       x = "Age Group",
       y = "Percentage")
age_severity

## To answer our first question;
## Majority of the cases in our study population were of people within the 51 - 66 age group, 
## most of them having been malignant cases at 43%.
## Persons aged between 67 - 82 recorded the second highest number of people with malignant cases 
## at 34%.
## Only 1% of persons aged between 18 - 34 are reported having been malignant in our study population.  

# Distribution of age groups:
# Table that will be used: 
AgeGroup_table <- mammographicmassesdf %>% 
  group_by(Age_group) %>% 
  summarise(Count = n()) %>% 
  na.omit() %>%
  mutate(Perc = round(Count / sum(Count)*100,0))

# The pie Chart.
with(AgeGroup_table,pie(Perc, labels=paste0( Perc, "%"),main = "Distribution of cases by their age groups", 
                        radius= 1,col =  c("red", "yellow", "green", "violet", "orange", "blue", "cyan")))
legend("topright", c("18 - 34","35 - 50","51 - 66","67 - 82", "83 - 96"), cex = 0.8,
       fill = c("red", "yellow", "green", "violet", "orange", "blue", "cyan"))

# Our second question will be answered using the following bargraph:
# Question 2: Based on the shapes, what was the severity of the cases?

SeverityShapetable <- mammographicmasses %>% 
  group_by(Severity, Shape) %>% 
  summarise(Count = n()) %>% ungroup() %>% 
  na.omit() %>%
  group_by(Shape) %>% 
  mutate(Perc = round(Count / sum(Count)*100,0))

shape_severity <- ggplot(data = SeverityShapetable, aes(x = Shape, y = Perc, fill = Severity,na.rm = T)) +
  geom_bar(stat = "identity",na.rm = T ) +
  geom_text(aes(label = paste0(Perc,"%")), hjust = 0.5, vjust = 3, size = 4, position = position_stack()) +
  visualization_theme+
  scale_y_continuous(labels = function(x) paste0(x, "%"))+
  scale_fill_manual(values = c("#F29E0F","#30B570","#FF5062")) +
  labs(title = "Distribution of Observations based on their Shape and Severity of their cases",
        x = "Shape",
        y = "Percentage")
shape_severity

# Majority of the malignant cases were irregular in shape while 
# majority of the benign cases were either round or oval according to our study population.


# The following tables and bargraphs were used to explore our dataset further.
# BI_RADS table


BI_RADSeverity_table <- mammographicmasses %>% 
  group_by(Severity, BI_RADS) %>% 
 na.omit() %>% 
  summarise(Count = n()) %>% ungroup() %>% 
  group_by(BI_RADS) %>% 
  mutate(Perc = round(Count / sum(Count)*100,0))


BIRADS_severity <- ggplot(data = BI_RADSeverity_table, aes(x = BI_RADS , y = Perc, fill = Severity, position = 'dodge'),na.rm = T) +
  geom_bar(stat = "identity", na.rm = T) +
  geom_text(aes(label = paste0(Perc,"%")), hjust = 1, vjust = 1, size = 4, position = position_stack()) +
  visualization_theme+
  scale_y_continuous(labels = function(x) paste0(x, "%"))+
  scale_fill_manual(values = c("#F29E0F","#30B570")) +
  labs(title = "Distribution of Observations based on their BI_RADS and Severity of their cases",
       x = "BI_RADS",
       y = "Percentage")
BIRADS_severity

# Of the benign cases 10% were found to be highly suspicious of malignancy 
# according to the  Breast Imaging Reporting and Data System (BI_RADS) assessment.


MarginSeveritytable <- mammographicmasses %>% 
  group_by(Margin,Severity) %>% 
  summarise(Count = n()) %>%
  na.omit() %>%
  ungroup() %>% 
  group_by() %>% 
  mutate(Perc = round(Count / sum(Count)*100,0))

Margin_severity <- ggplot(data = MarginSeveritytable, aes(x = Margin , y = Perc, fill = Severity),na.rm = T) +
  geom_bar(stat = "identity", na.rm = T) +
  geom_text(aes(label = paste0(Perc,"%")), hjust = 0.5, vjust = 1, size = 4, position = position_stack()) +
  visualization_theme+
  scale_y_continuous(labels = function(x) paste0(x, "%"))+
  scale_fill_manual(values = c("#F29E0F","#30B570")) +
  labs(title = "Distribution of Observations based on the Margin and Severity of the cases",
       x = "Margin",
       y = "Percentage")
Margin_severity

# Most malignant cases were ill-defined at 21% of all the malignant cases in the study population
# while most benign cases were circumscribed at 35%

DensitySeveritytable <- mammographicmasses %>% 
  group_by(Density,Severity) %>% 
  summarise(Count = n()) %>%
  na.omit() %>%
  ungroup() %>% 
  group_by() %>% 
  mutate(Perc = round(Count / sum(Count)*100,0))


Density_severity <- ggplot(data = DensitySeveritytable, aes(x = Density , y = Perc, fill = Severity),na.rm = T) +
  geom_bar(stat = "identity", na.rm = T) +
  geom_text(aes(label = paste0(Perc,"%")), hjust = 0.5, vjust = 1, size = 4, position = position_stack()) +
  visualization_theme+
  scale_y_continuous(labels = function(x) paste0(x, "%"))+
  scale_fill_manual(values = c("#F29E0F","#30B570")) +
  labs(title = "Distribution of Observations based on the Density and Severity of the cases",
       x = "Density",
       y = "Percentage")
Density_severity

# Majority of the cases had low density with almost equal severities whereby 41% were malignant and 42% were benign.


### MACHINE LEARNING

#############################################################################################
#  1: (Using a logistic regression model )
# How good are the variables at predicting whether or not 
# the mass lesion is malignant or benign.
# Splitting dataset

set.seed(123) # To ensure every run will produce the same output

splitvalues <- sample.split(mammographicmasses$Severity, SplitRatio = 0.80)
train_set <- subset(mammographicmasses, splitvalues == T)
test_set <- subset(mammographicmasses, splitvalues == F)

# Building our classification model.

# We are trying to determine whether the severity of the mass is with respect to
# the BI_RADS assessment, Margin, Shape, Age or Density.

# Logistic regression model

logmodel <- glm(Severity ~ ., family = binomial(link = 'logit'), data = train_set)
summary(logmodel)

# This model had an AIC of 507.36

#  we then perform an ANOVA Chi-square test 
# to check the overall effect of variables on the dependent variable
anova(logmodel, test = 'Chisq')

# We see that Density and Margin are not significant 

# Model Prediction using the new_test data.
log_predict <- predict(logmodel,newdata = test_set, type = "response")
log_predict <- ifelse(log_predict > 0.5,1,0) #compiling the table.
log_predict <- as.factor(log_predict)

ConfusionMatrix2 <- table(test_set$Severity,log_predict)

ConfusionMatrix2

# Out of the 86 benign cases, 73 were correctly predicted and out of the 73 malignant cases, 58 were 
# well predicted.
# The accuracy of this model is:
(73+61) / (73+12+18+61) # 81.7%

#############################################################################################
  
# Our second model will be a random Forest model.

install.packages("randomForest")
library(randomForest)

set.seed(123)

splitvalues2 <- sample.split(mammographicmasses$Severity, SplitRatio = 0.80)

train_set2 <- subset(mammographicmasses, splitvalues2 == TRUE)
test_set2  <- subset(mammographicmasses, splitvalues2 == FALSE)

# We use na.action = na.roughfix if your data contains Na or missing values since 
# it will pass the data exactly the same as it is in datasets.

rfmodel <- randomForest(Severity~ .,data = train_set2, na.action = na.roughfix)
rfmodel

# Now to predict using our test_set2 data set
str(test_set2)
pred <- predict(rfmodel, newdata=test_set2[-6])
pred
# Next we build the confusion matrix to check the accuracy.

confusionmatrix <-  table(test_set2[,6], pred)

confusionmatrix

# accuracy: 
(70+63)/ (70+15+16+63)

#81.1% accuracy


