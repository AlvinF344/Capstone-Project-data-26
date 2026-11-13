
# C0:  Importer et préparer vos données


# C0.1 Load and save dataframe -----

library(readr)
library(dplyr)

patients <- read_csv("Data/Patients.csv")
hygiene <- read_csv("Data/Hygiene_vie.csv")
glycemie <- read_csv("Data/Historique_glycemique.csv")
consultations <- read_csv("Data/Consultations.csv")
Antecedents <- read_csv("Data/Antecedents_familiaux.csv")
#-------------------------------------------------------------------------

# C0.2 Cleaning dataframe----


# R1----------

library(stringr)

table(patients$Sexe)

# standardize sex with F or M
patients <- patients %>%
  mutate(
    Sexe = str_to_lower(Sexe),
    Sexe = str_replace_all(Sexe, "^f$|^femme$", "F"),  # ^femme$: to match whole values only
    Sexe = str_replace_all(Sexe, "^h$|^homme$|^m$", "M"),
    Sexe = str_replace_all(Sexe, "na", "Unknown")
    )

sum(is.na(patients$Sexe)) # check for missing values

# replace missing values with unknown
patients$Sexe <- ifelse(is.na(patients$Sexe),
                        "Unknown",
                        patients$Sexe
                        )
table(patients$Sexe)


# R2 ---------
# Clean Corticoïdes variable (na,Na with Non)

table(patients$Corticoïdes)
sum(is.na(patients$Corticoïdes))

patients <- patients %>%
  mutate(
    Corticoïdes = str_replace_na(Corticoïdes, "Non"),
    Corticoïdes = str_replace_all(Corticoïdes, "^na$|^Na$", "Non")
  )

table(patients$Corticoïdes)

# R3---------
# Clean Age variable (over 110) to NA

table(patients$`Âge (ans)`)

patients <- patients %>%
  mutate(
    `Âge (ans)` = if_else(`Âge (ans)` > 110, NA_real_, `Âge (ans)`)
  )

table(patients$`Âge (ans)`)


# R4--------
# Standardize Niveau d'activité from hygiene dataset

unique(hygiene$`Niveau d'activité`) # check Niveau d'activité for distinct values

hygiene <- hygiene %>%
  mutate(
    `Niveau d'activité` = str_replace_all(`Niveau d'activité`, "faible", "Faible")
  )

unique(hygiene$`Niveau d'activité`)


# R5---------
# remove duplicate rows from consultations

sum(duplicated(consultations)) # check for duplicates
consultations[duplicated(consultations), ]  # display duplicates

consultations_clean <- distinct(consultations) # remove duplicates

consultations_clean[duplicated(consultations_clean), ]  # display duplicates

# remove duplicate rows from Antecedents

sum(duplicated(Antecedents))  # check for duplicates
Antecedents[duplicated(Antecedents), ]   # display duplicates

Antecedents_clean <- unique(Antecedents)  # remove duplicates
Antecedents_clean[duplicated(Antecedents_clean), ]


# C0.3 ---------

patients_hygiene <- patients %>%
  full_join(hygiene, by = "ID patient")
View(patients_hygiene)


# C0.4-------

patients_hygiene <- patients_hygiene %>%
  mutate(
    BMI = `Poids (kg)` / ((`Taille (cm)` / 100)^2),
    BMI = round(BMI, 2)
    )
summary(patients_hygiene$BMI)
library(ggplot2)

# plot distribution - BMI
ggplot(patients_hygiene, aes(BMI ))+
  geom_histogram(
    binwidth = 2,
    fill = "steelblue",
    color = "black"
  )+
  labs(
    title = "Distribution of BMI",
    x = "BMI",
    y = "Frequency"
  )+
  theme_minimal()


# C1  Décrire la cohorte  **********************

# C1.1------

# report number of patients, mean age, median age and mean blood glucose.

patients_hygiene %>%
  summarise(
    Number_of_patients = n_distinct(`ID patient`),   
    Mean_age = mean(`Âge (ans)`, na.rm = TRUE),
    Median_age = median(`Âge (ans)`, na.rm = TRUE),
    Mean_blood_glucose = mean(`Glycémie (mg/dL)`, na.rm = TRUE)
  )


# C1.2-----

# plot distribution - Glycémie
ggplot(patients_hygiene, aes(`Glycémie (mg/dL)` ))+
  geom_histogram(
    binwidth = 5,
    fill = "steelblue",
    color = "black"
  )+
  labs(
    title = "Distribution of Glycémie",
    x = "Glycémie",
    y = "Frequency"
  )+
  theme_minimal()

# classify Glycémie in 3 categories
patients_hygiene <- patients_hygiene %>%
  mutate(
    Glycémie_categorie = case_when(
      `Glycémie (mg/dL)` < 100 ~ "normale",
      `Glycémie (mg/dL)` < 125 ~ "altérée",
      `Glycémie (mg/dL)` >= 125 ~ "plage_diabétique"
      )
    )
table(patients_hygiene$Glycémie_categorie)

# plot Glycémie category
ggplot(patients_hygiene, aes(x = Glycémie_categorie,
                             fill = Glycémie_categorie ))+
  geom_bar()+
  labs(
    title = "Glycémie Classification",
    x = "Category",
    y = "Number of Patients"
  )+
  theme_sub_axis_bottom() 


# C1.3----

# la glycémie moyenne selon le statut tabagique
Glycémie_Tabagisme <- patients_hygiene %>%
  group_by(Tabagisme) %>%
  summarise(
    Mean_Glycémie = round(mean(`Glycémie (mg/dL)`, na.rm = TRUE), 2),
    n = n(),
    .groups = "drop"
  )

# plot la glycémie moyenne selon le statut tabagique
ggplot(Glycémie_Tabagisme, 
       aes(x = Tabagisme,
           y = Mean_Glycémie,
           colour = Tabagisme)
)+
  geom_boxplot(varwidth = TRUE)+
  labs(
    title = "Avg Glucose Levels by Smoking Status",
    x = "Tabagisme",
    y = "Mean Glycémie"
  )+
  coord_flip()+
  theme_sub_axis_bottom()


# la glycémie moyenne selon la qualité de l’alimentation
Glycémie_Qa_Aliment <- patients_hygiene %>%
  group_by(`Qualité de l'alimentation`) %>%
  summarise(
    Mean_Glycémie = round(mean(`Glycémie (mg/dL)`, na.rm = TRUE), 2),
    n = n(),
    .groups = "drop"
  )


# plot la glycémie moyenne selon la qualité de l’alimentation
ggplot(Glycémie_Qa_Aliment, 
       aes(x = `Qualité de l'alimentation`,
           y = Mean_Glycémie,
           colour = `Qualité de l'alimentation`)
)+
  geom_boxplot(varwidth = TRUE)+
  labs(
    title = "Avg Glucose Levels by Diet",
    x = "Qualité de l'alimentation",
    y = "Mean Glycémie"
  )+
  coord_flip()+
  theme_sub_axis_bottom()


# C2 Tabagisme et glycémie *******************************

# C2.2----
# select only relevant variables for C2
tab_gly <- patients_hygiene %>%
  select(`ID patient`,
         `Glycémie (mg/dL)`,
         Tabagisme
         )

# check assumptions
str(tab_gly)
summary(tab_gly)

# Verifier la normalité des données
by(tab_gly$`Glycémie (mg/dL)`, tab_gly$Tabagisme, shapiro.test)

# verifier l’homogénéité des variances
library(car)
leveneTest(`Glycémie (mg/dL)` ~ Tabagisme,
           data = tab_gly)

# C2.3----
model <- t.test(`Glycémie (mg/dL)` ~ Tabagisme, data = tab_gly, 
                var.equal = FALSE, conf.level = 0.95)
model


# c3  Qualité de l’alimentation et glycémie ********************

# C3.1---------
# select only relevant variables for C3
Qa_Ali_gly <- patients_hygiene %>%
  select(`ID patient`,
         `Glycémie (mg/dL)`,
         `Qualité de l'alimentation`
  )

# clean column names
Qa_Ali_gly$Glycémie <- Qa_Ali_gly$`Glycémie (mg/dL)`
Qa_Ali_gly$Diet <- factor(Qa_Ali_gly$`Qualité de l'alimentation`)
Qa_Ali_gly$ID_patient <- Qa_Ali_gly$`ID patient`

Qa_Ali_gly <- Qa_Ali_gly  %>%
  select(ID_patient,
         Glycémie,
         Diet
  )

# descriptive statistics
Qa_gly_df <- Qa_Ali_gly %>%
  group_by(Diet) %>%
  summarise(
    n = n(),
    Mean_Glycémie = round(mean(Glycémie, na.rm = TRUE), 2),
    IQR_Glycémie = IQR(Glycémie, na.rm = TRUE),
    Min_Glycémie = min(Glycémie, na.rm = TRUE),
    Max_Glycémie = max(Glycémie, na.rm = TRUE),
    Median_Glycémie = median(Glycémie, na.rm = TRUE),
    sd_Glycémie = round(sd(Glycémie, na.rm = TRUE), 2),
    .groups = "drop"
  )

# plot distribution

ggplot(Qa_Ali_gly,
       aes(x = Diet,
           y = Glycémie,
           fill = Diet)) +
  geom_boxplot() +
  labs(
    title = "Distribution de la glycémie selon la qualité de l'alimentation",
    x = "Qualité de l'alimentation",
    y = "Glycémie (mg/dL)"
  ) +
  coord_flip()+
  theme_sub_legend()


# c3.2-----

# Verify the normality of the data.
modele <- aov(Glycémie ~ Diet,
              data = Qa_Ali_gly)
shapiro.test(residuals(modele))


# Homogeneity of variances
leveneTest(
  Glycémie ~ Diet,
  data = Qa_Ali_gly
)   
    

# C3.3----
# ANOVA test 
modele_aov <- aov(Glycémie ~ Diet,
              data = Qa_Ali_gly)
summary(modele_aov) 


# C3.4----
# Tukey test: to check groups that differ.
TukeyHSD(modele_aov)


# non-parametric Kruskal-Wallis test
# since normality is not met

kruskal.test(Glycémie ~ Diet, data = Qa_Ali_gly)



# c4 Évolution de la glycémie chez un même patient *********************

Historique_glycemique <- read_csv("Data/Historique_glycemique.csv")
View(Historique_glycemique)

# clean column names:
Historique_glycemique$ID_patient <- Historique_glycemique$`ID patient`
Historique_glycemique$Glycémie <- Historique_glycemique$`Glycémie (mg/dL)`
Historique_glycemique$Measure_date <- Historique_glycemique$`Date de mesure`
Historique_glycemique$Poids_kg <- Historique_glycemique$`Poids (kg)`
Historique_glycemique$Tension_artérielle_mmHg <- Historique_glycemique$`Tension artérielle (mmHg)`
Historique_glycemique$HbA1c_pct <- Historique_glycemique$`HbA1c (%)`

Historique_glycemique <- Historique_glycemique %>%
  select(
    ID_patient,
    Glycémie,
    Measure_date,
    Poids_kg,
    Tension_artérielle_mmHg,
    HbA1c_pct
  )


# C4.1----
Hist_glycemique_F2L_Date <-  Historique_glycemique %>%
  group_by(ID_patient) %>%
  filter(n_distinct(Measure_date) >= 2) %>%
  arrange(Measure_date, .by_group = TRUE) %>%
  slice(c(1, n()))


# C4.2----
Hist_glycemic_delta <-  Hist_glycemique_F2L_Date %>%
  group_by(ID_patient) %>%
  summarise(
    glucose_first = first(Glycémie),
    glucose_last = last(Glycémie),
    delta = glucose_last - glucose_first,
    .groups = "drop"
  )


# plot glycemic evolution
library(tidyr)

evolution_plot <- Hist_glycemic_delta %>%
  pivot_longer(
    cols = c(glucose_first, glucose_last),
    names_to = "Time",
    values_to = "Glucose"
  )

ggplot(evolution_plot,
       aes(x = Time,
           y = Glucose,
           group = ID_patient)) +
  geom_line(alpha = 0.15, color = "steelblue") +
  geom_point(size = 1) +
  labs(
    title = "Evolution of Blood Glucose",
    x = "Delta/Time",
    y = "Blood Glucose (mg/dL)"
  ) +
  theme_minimal()

# plot glycemic evolution by mean glucose
evolution_plot %>%
  group_by(Time) %>%
  summarise(
    Mean_Glucose = mean(Glucose, na.rm = TRUE)
  ) %>%
  ggplot(aes(x = Time,
             y = Mean_Glucose,
             group = 1)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  labs(
    title = "Mean Blood Glucose Evolution",
    x = "Delta/Time",
    y = "Mean Blood Glucose (mg/dL)"
  ) +
  theme_minimal()
  

# c4.3
# check normality of differences

shapiro.test(Hist_glycemic_delta$delta)

# paired t-test
t_test_res <- t.test(
  Hist_glycemic_delta$glucose_first,
  Hist_glycemic_delta$glucose_last,
  paired = TRUE
)

t_test_res


# c5 Modélisation de la glycémie *********************

# c5.2

names(patients_hygiene)

glycemie_clean_df <- patients_hygiene %>%
  select(
    glycemie_mg_dL = `Glycémie (mg/dL)`,
    Age = `Âge (ans)`,
    BMI,
    Tabagisme,
    Activity_physical_weekly = `Activité physique (min/sem)`,
    Diet = `Qualité de l'alimentation`
  ) %>%
  na.omit()

# number of observations
n_obs <- nrow(glycemie_clean_df)
n_obs

# convert categorical variables into factors
glycemie_clean_df <- glycemie_clean_df %>%
  mutate(
    Tabagisme = as.factor(Tabagisme),
    Diet = as.factor(Diet)
  )

# check levels
levels(glycemie_clean_df$Tabagisme)
levels(glycemie_clean_df$Diet)
names(glycemie_clean_df)

# C5.3----

# fit the model
modele_reg <- lm(
  glycemie_mg_dL ~ Age + BMI + Tabagisme + Activity_physical_weekly + Diet,
  data = glycemie_clean_df
  )

modele_complet <- modele_reg

# display summary
summary(modele_complet)

# display coefficients beta of the model
coef(modele_complet)

# display CI for the model's beta coefficients
confint(modele_complet)


# C5.4----
# verify model assumptions

par(mfrow = c(2, 2))
plot(modele_reg,
     col = "blue",
     pch = 19)


# C5.6----

# exclude diet quality
glycemie_wo_diet <- glycemie_clean_df %>%
  select(
    glycemie_mg_dL,
    Age,
    BMI,
    Tabagisme,
    Activity_physical_weekly
  )

# fit the model
modele_wo_diet_reg <- lm(
  glycemie_mg_dL ~ Age + BMI + Tabagisme + Activity_physical_weekly,
  data = glycemie_wo_diet
)

modele_reduit <- modele_wo_diet_reg

# display summary
summary(modele_reduit)

# display coefficients beta of the model
coef(modele_reduit)

# display CI for the model's beta coefficients
confint(modele_reduit)

# compare two models
anova(modele_reduit, modele_complet)
  
  
  
# C6 : Modélisation des anomalies glycémiques *****************

# C6.1----

glycemie_binary_df <- glycemie_clean_df %>%
  mutate(
    Glycemic_Status = factor(
      ifelse(glycemie_mg_dL >= 126, "High Glucose", "Normal Glucose")
    )
  )

# reorder the Glycemic_Status (model predicts the probability of the second level by default)
glycemie_binary_df <- glycemie_binary_df %>%
  mutate(
    Glycemic_Status = relevel(
      Glycemic_Status,
      ref = "Normal Glucose"
    )
  )

# check levels
levels(glycemie_binary_df$Glycemic_Status)



# C6.3----

# fit the model
modele_logR <- glm(
  Glycemic_Status ~ Age + BMI + Tabagisme,
  data = glycemie_binary_df,
  family = binomial
)

# display the results of the model
summary(modele_logR)

# calculate the odds ratio
exp(coef(modele_logR)) 


# C6.4----

# create a null model
modele_nul <- glm(
  Glycemic_Status ~ 1, 
  data = glycemie_binary_df,
  family = binomial
  )

# comparer the models null and full(logR)
anova(modele_nul, modele_logR, test = "Chisq")

# predict probabilities
glycemie_binary_df$pred_prob <- predict(
  modele_logR,
  type = "response"
  )

# construct ROC curve for model discrimination
roc_obj <- pROC::roc(
  glycemie_binary_df$Glycemic_Status,
  glycemie_binary_df$pred_prob
  )

plot(roc_obj, col = "blue", print.auc = TRUE)
     


# C7 : Exploration multivariée des données **************

# C7.1----

# display all column/variable names
names(patients_hygiene)

# save the required variables in a dataframe
multivar_df <- patients_hygiene %>%
  select(
    Age = `Âge (ans)`,
    BMI,
    Glycémie = `Glycémie (mg/dL)`,
    Insuline_µUI_mL = `Insuline (µUI/mL)`,
    Activity_physical_weekly =  `Activité physique (min/sem)`,
    Sommeil_h_nuit =  `Sommeil (h/nuit)`,
    Diet_score =  `Score alimentation (0-10)`
  ) %>%
  na.omit()

# load the required modules for multivariate analysis and visualization
library(FactoMineR)
library(factoextra)

# select the required variables for PCA
X <- multivar_df[, c("Age",
                     "BMI",
                     "Glycémie",
                     "Insuline_µUI_mL",
                     "Activity_physical_weekly",
                     "Sommeil_h_nuit",
                     "Diet_score")
                 ]

# perform the PCA with scaling and save the results in an object
pca_res <- prcomp(X, center = TRUE, scale. = TRUE)

# visualize the results
summary(pca_res)

# load pca matrix (each variables contribution to each PC)
pca_res$rotation

# plot for visualization
par(mfrow = c(1, 1))
plot(pca_res, type = "lines")

biplot(pca_res)
fviz_eig(pca_res)

fviz_pca_var(pca_res) 
fviz_pca_ind(pca_res) 


# C7.4-----
fviz_pca_ind(
  pca_res,
  geom = "point",
  col.ind = "steelblue",
  repel = TRUE
)


# ***********************************************************************









