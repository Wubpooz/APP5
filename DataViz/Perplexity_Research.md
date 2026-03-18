# Datasets pour étudier l’« évolution de l’ennui » et nos habitudes de temps libre

## 1. Cadre conceptuel : qu’est‑ce que l’ennui ?

La littérature en psychologie définit l’ennui comme une expérience affective négative caractérisée par le fait de vouloir être engagé dans une activité satisfaisante, tout en ayant le sentiment de ne pas pouvoir l’être. L’ennui est associé à des difficultés d’attention, un sentiment de manque de sens et un décalage entre le niveau de stimulation souhaité et celui réellement perçu.[^1][^2][^3]

On distingue classiquement :

- **L’ennui d’état (state boredom)** : ressenti ponctuel pendant une activité donnée.
- **L’ennui de trait (boredom proneness)** : tendance stable d’un individu à ressentir fréquemment de l’ennui dans des situations variées.[^4][^1]

Plusieurs échelles psychométriques largement utilisées existent :

- **Boredom Proneness Scale (BPS)**, 28 items, mesure la propension générale à l’ennui.[^1]
- **Short Boredom Proneness Scale (SBPS)**, version courte validée dans plusieurs langues (anglais, français, chinois, arabe, etc.).[^5][^6][^7][^8]
- **Multidimensional State Boredom Scale (MSBS)**, qui mesure l’ennui comme état momentané.[^9]

Votre projet peut donc articuler :

- Une mesure **subjective** (scores d’ennui ou de bien‑être) là où des données existent.
- Des **proxies comportementaux** via des enquêtes d’emploi du temps, d’usages numériques et de mobilité.


## 2. Opérationnaliser l’ennui : métriques possibles

Comme il y a peu de séries temporelles directes de « taux d’ennui » dans la population, il faut surtout travailler avec des **indicateurs indirects** et des datasets qui peuvent être croisés.

### 2.1 Indicateurs subjectifs

- **Scores moyens d’ennui de trait** dans des échantillons utilisant BPS ou SBPS (plutôt cross‑sectionnels que des séries longues).[^7][^1]
- **Indices de bien‑être / bonheur / satisfaction de vie** issus d’enquêtes internationales (World Values Survey, World Database of Happiness, etc.).[^10][^11]
- **Modules de bien‑être associés aux journaux d’emploi du temps** : par exemple, le Well‑Being Module de l’American Time Use Survey (ATUS) demande aux répondants leur niveau de bonheur, de stress, de sens, etc. pour certaines activités de la journée.[^12][^13]

Même si ces mesures ne parlent pas directement de « boredom », on peut interpréter certaines combinaisons, par exemple : temps passé dans des activités jugées peu plaisantes ou peu signifiantes.

### 2.2 Proxies comportementaux (temps / activités)

À partir des enquêtes d’emploi du temps, on peut construire :

- **Temps moyen passé en activités de loisir passives** (TV, réseaux sociaux, streaming, gaming) vs **loisirs actifs / créatifs** (sport, musique, bricolage, bénévolat).
- **Temps passé dehors** (walks, sports extérieurs, sorties au restaurant/bar, événements culturels) vs **temps passé à la maison**.[^14][^15]
- **Temps passé avec d’autres personnes** (amis, famille, collègues) vs **temps seul**.[^16][^17]
- **Durée moyenne des épisodes d’activité** (fragmentation du temps : micro‑séquences de quelques minutes, typiques de l’économie de l’attention).[^18][^19]

L’hypothèse centrale pourrait être : plus le temps libre est fragmenté et saturé par du contenu numérique, moins nous laissons de « trous » où l’ennui peut s’installer.

### 2.3 Indicateurs technologiques et contextuels

Pour relier ces comportements à des jalons technologiques ou contextuels :

- **Taux de pénétration du smartphone** (par pays, par année).[^20][^21]
- **Part de la population utilisant Internet / abonnements mobiles par 100 habitants**, disponibles dans les bases Our World in Data et World Development Indicators.[^22][^23]
- **Temps moyen quotidien passé sur les réseaux sociaux et les écrans**, par pays et par année (rapports Datareportal / Global Digital, méta‑analyses sur le temps d’écran).[^24][^25][^26]
- **Indices de sévérité des mesures COVID‑19** (Oxford COVID‑19 Government Response Tracker – Stringency Index).[^27][^28][^29]

Ces séries temporelles fourniront la trame « macro » à croiser avec les données de temps libre et de bien‑être.


## 3. Grands jeux de données sur l’emploi du temps (time‑use)

### 3.1 HETUS : Harmonised European Time Use Surveys

- **Source** : Eurostat / HETUS (Harmonised European Time Use Survey).[^15][^14]
- **Couverture** : plusieurs vagues (2000, 2010, 2020 en cours) dans 15–18 pays européens.[^14]
- **Contenu** : journaux de 24 h avec activités codées à la minute, contexte (où, avec qui), temps de travail, tâches domestiques, loisirs, social life, etc.[^30][^31]
- **Accès** : tableaux agrégés en accès libre, micro‑données via Eurostat (demande de projet de recherche, accord d’utilisation).[^30][^15]

Utilisation possible pour votre sujet :

- Comparer l’évolution (2000 → 2010 → 2020) du **temps passé à l’extérieur, en socialisation informelle, en loisirs numériques** pour différents groupes d’âge et pays.
- Construire un indicateur de **« temps libre non structuré hors écran »** (ex. marcher, rêvasser, attendre, transports sans smartphone) et voir s’il diminue dans le temps.

### 3.2 ATUS : American Time Use Survey (États‑Unis)

- **Source** : Bureau of Labor Statistics (BLS), American Time Use Survey.[^32][^33]
- **Couverture** : enquête annuelle depuis 2003, ~26 000 répondants par an.[^33][^17]
- **Données** : micro‑données détaillées (activité par tranche de temps, lieu, présence d’autrui) + modules thématiques (bien‑être, santé, etc.).[^16][^32][^12]
- **Well‑Being Module** : années 2010, 2012, 2013, 2021, avec auto‑évaluation du bonheur, du stress, de la fatigue et du sens pendant trois activités tirées au sort.[^13][^12]

Utilisation pour votre sujet :

- Suivre sur 20 ans l’évolution du **temps de loisir**, **temps passé seul**, **temps devant écran (TV, ordinateur, jeux)**, **temps passé dehors**, etc.[^17][^16]
- En 2010/2012/2013/2021, lier types d’activités à des scores de bien‑être (par ex. comparer la valence affective d’activités offline vs online, social vs seul).[^12][^13]
- Étudier les modifications structurelles dues au **COVID‑19** en 2020‑2021 (plus de télétravail, plus de temps à la maison) en les mettant en regard de l’indice de sévérité des politiques sanitaires (Stringency Index).[^28][^29][^27]

### 3.3 Autres enquêtes d’emploi du temps

- **Millennium Cohort Study – Time Use Diaries (Royaume‑Uni)** : inclut des journaux détaillés de comportements d’écran et de contexte social chez les adolescents.[^34]
- **Harmonised Multinational Time Use Survey (MTUS)** : base harmonisée multi‑pays (UK, Pologne, US, etc.) pour estimer, entre autres, les dépenses métaboliques quotidiennes mais aussi des patterns détaillés de comportement.[^35][^36]

Ces bases permettent d’ajouter des pays non couverts par HETUS ou d’augmenter la profondeur historique.


## 4. Données sur valeurs, bien‑être et « importance du temps libre »

### 4.1 World Values Survey (WVS)

- **Source** : World Values Survey Association, 7 vagues depuis 1981, ~120 sociétés couvertes.[^37][^10]
- **Contenu** : valeurs, croyances, bonheur, satisfaction de vie, importance accordée au travail, à la famille, au loisir, etc.[^38][^10]
- Exemple : la variable « Important in life: Leisure time » demande si le temps libre est très, plutôt, peu ou pas important.[^38]

Utilisation pour votre sujet :

- Suivre, par pays et par génération, l’**importance déclarée du temps libre**, le **niveau de bonheur**, la **satisfaction de vie**, et croiser ces indicateurs avec la diffusion des technologies (Internet, smartphone).[^10][^22]
- Comparer pays occidentaux vs non‑occidentaux pour voir si la valorisation du loisir et les niveaux de bien‑être évoluent différemment.

### 4.2 World Database of Happiness

- **Source** : World Database of Happiness, Erasmus University Rotterdam.[^11][^39]
- **Contenu** : base d’études sur la satisfaction de vie, avec distributions de bonheur par pays/année et milliers de résultats corrélationnels (facteurs associés au bonheur).[^40][^11]

Utilisation :

- Extraire des séries temporelles de **bonheur moyen** par pays et les corréler avec des indicateurs de numérisation, d’urbanisation, d’emploi du temps, etc.[^23][^22]
- Chercher des études qui relient directement **ennui**, **usage des technologies** et **bien‑être**.


## 5. Données spécifiques sur ennui et boredom proneness

### 5.1 Jeux de données SBPS / BPS

- Un **jeu de données SBPS** (Short Boredom Proneness Scale) disponible dans le package R `bgms` contient les réponses de 986 personnes à l’échelle SBPS (anglais et français).[^41]
- De nombreuses études de validation (allemand, français, chinois, arabe, japonais) fournissent des échantillons de plusieurs centaines de répondants avec SBPS ou BPS, souvent couplés avec des mesures d’anxiété, de solitude, d’addiction au smartphone, etc.[^6][^8][^5][^4]

En pratique, ces jeux sont surtout **transversaux** (cross‑section), donc moins adaptés pour des séries temporelles longues, mais utiles pour :

- Montrer le **profil psychologique** des individus à fort ennui de trait (plus d’anxiété, de solitude, d’addiction au smartphone, moins de satisfaction de vie).[^5][^4]
- Illustrer des relations micro‑niveau (par individu) entre ennui et comportements numériques (addiction au smartphone, temps passé sur les réseaux sociaux).[^42][^43]

### 5.2 Datasets « ennui & activités » via capteurs

- Un dataset récent de **capteurs portés** (acceleromètres et autres) vise à distinguer des activités associées au stress et à l’ennui, avec près de 500 000 points de données.[^44]
- D’autres travaux comme **Screenomics** capturent des captures d’écran continuellement pour analyser la vie numérique seconde par seconde, avec des logs d’apps, de types de contenus, etc.[^45]

Ces jeux sont plus expérimentaux, mais peuvent vous inspirer pour la dimension « comment on occupe chaque micro‑moment libre ».


## 6. Données sur usages numériques et temps d’écran

### 6.1 Indicateurs globaux de temps d’écran

- Rapports **Datareportal / Digital 20XX** fournissent des estimations du temps moyen passé chaque jour sur les réseaux sociaux (environ 143 minutes/jour en moyenne mondiale en 2024) et des ventilations par pays et âge.[^26]
- Synthèses statistiques sur le **temps d’écran total** (smartphone + ordinateur + TV), souvent autour de 6–7 h/jour pour l’adulte moyen dans les pays à haut revenu, avec encore plus pour la Génération Z.[^46][^47][^48]
- Meta‑analyses sur le temps d’écran des enfants/adolescents montrent une augmentation nette depuis les années 2010, fortement amplifiée pendant la pandémie.[^25][^24]

### 6.2 Usages numériques spécifiques

- Études de cohorte comme **Leisure Activities of Healthy Children and Adolescents** documentent l’augmentation massive de l’usage du smartphone entre 2011 et 2017 et la baisse d’activités comme le théâtre, la chorale ou certaines activités de plein air.[^49]
- Des analyses à partir de journaux d’emploi du temps (par ex. Millennium Cohort Study) détaillent les moments de la journée où les adolescents utilisent le plus les écrans et avec qui (seuls, avec amis, avec parents).[^34]
- Des études focalisées sur l’addiction au smartphone montrent des liens entre **temps passé sur réseaux sociaux** et **symptômes problématiques (PSU)**, souvent modérés par l’ennui de trait.[^42][^5]


## 7. Adoption des technologies et jalons historiques

Pour relier les transformations des habitudes à des jalons technologiques :

- **Adoption d’Internet et du mobile** : Our World in Data et autres sources documentent la diffusion du téléphone mobile, des abonnements mobiles par 100 habitants, de l’accès à Internet et d’autres technologies, par pays et par année.[^22][^23]
- **Adoption du smartphone** : rapports GSMA et Statista donnent la part de la population possédant un smartphone (54 % de la population mondiale en 2023, avec de fortes variations régionales).[^21][^20]
- **Technologie adoption (US)** : Our World in Data propose des séries sur le pourcentage de foyers américains possédant TV, ordinateur, Internet, smartphone, etc. sur plusieurs décennies.[^22]

Ces séries forment l’axe « technologique » que vous pouvez superposer aux tendances d’emploi du temps et de bien‑être.


## 8. COVID‑19 et reconfiguration du temps libre

### 8.1 Indices de sévérité des politiques

- **Oxford COVID‑19 Government Response Tracker (OxCGRT)** fournit un **Stringency Index** journalier (0–100) par pays, mesurant la sévérité des mesures de confinement (fermeture d’écoles, télétravail, restrictions de déplacement, etc.).[^50][^29][^28]

Vous pouvez en extraire des épisodes (printemps 2020, hivers successifs) pour voir comment l’emploi du temps et le temps d’écran ont été reconfigurés en fonction du degré de confinement.[^27]

### 8.2 Effets sur temps d’écran et modes de vie

- Une méta‑analyse montre une augmentation moyenne de 68 à 84 minutes de temps d’écran quotidien chez les enfants et adolescents pendant la pandémie par rapport à avant.[^25]
- D’autres travaux rapportent un quasi‑doublement du temps d’écran total chez les adultes pendant les confinements (jusqu’à 13 h/jour dans certains échantillons).[^51][^47]
- Dans les journaux de temps comme l’ATUS, on observe un déplacement massif du temps de travail vers le domicile et une hausse du temps passé à la maison, y compris pour les loisirs.[^17][^16]

L’idée est de traiter la pandémie comme un **choc exogène** qui a densifié l’occupation numérique du temps libre, et de se demander ensuite ce qui est revenu à la « normale » ou non.


## 9. Dimension globale vs phénomène occidental

Pour savoir si ce phénomène est global ou surtout propre aux pays développés, il faut exploiter les jeux de données multi‑pays :

- **WVS** : couvre quasi‑tous les continents, plusieurs vagues depuis les années 1980, avec des variables comparables sur le bonheur, la satisfaction de vie, l’importance du temps libre, des valeurs matérielles/post‑matérielles.[^37][^10]
- **Our World in Data / WDI** : indique que la pénétration du smartphone et d’Internet reste très inégale ; en 2023, 54 % de la population mondiale possède un smartphone, mais ce taux dépasse 80 % en Amérique du Nord, contre beaucoup moins en Afrique subsaharienne.[^20][^21]
- **HETUS / MTUS / ATUS** : fournissent principalement des données pour l’Europe, l’Amérique du Nord et quelques pays à revenu intermédiaire, ce qui permet au moins un contraste « pays riches vs reste du monde ».

Une stratégie raisonnable est :

- Comparer, par quintiles de PIB/habitant, **temps d’écran moyen**, **importance du smartphone**, **temps passé dehors et en socialisation** (là où les données existent).[^49][^22]
- Utiliser WVS pour voir si l’importance déclarée du temps libre et les niveaux de satisfaction de vie convergent ou divergent entre régions, et comment cela se corrèle avec la diffusion des technologies.[^38][^10]


## 10. Esquisse de design d’étude avec ces datasets

Voici une architecture de projet de data analysis cohérente avec votre sujet :

1. **Définir des indicateurs dérivés** à partir des enquêtes d’emploi du temps :
   - part du temps libre passée sur des écrans vs hors écrans,
   - part du temps libre passée avec d’autres vs seul,
   - temps libre passé dehors vs à domicile.
2. **Relier ces indicateurs aux jalons technologiques** :
   - par pays et année, ajouter la pénétration du smartphone, l’usage d’Internet, le temps moyen passé sur les réseaux sociaux.[^26][^20][^22]
3. **Intégrer des mesures de bien‑être / ennui** là où disponibles :
   - scores de bien‑être des modules ATUS WB,
   - niveaux moyens de bonheur / satisfaction de vie (WVS, World Database of Happiness),
   - éventuellement scores SBPS/BPS sur des échantillons ciblés pour illustrer des liens micro‑niveau.[^41][^13][^10]
4. **Traiter le COVID comme expérience naturelle** :
   - utiliser l’indice de sévérité OxCGRT pour diviser les périodes en pré‑COVID, confinement dur, post‑confinement,
   - observer comment l’occupation du temps libre et les usages numériques se transforment et ce qui reste après.[^29][^28][^25]
5. **Comparer pays / régions** :
   - groupe « pays développés à haute pénétration smartphone » vs « pays à plus faible diffusion »,
   - vérifier si la disparition du « temps mort » (non occupé par écran) est plus prononcée dans les premiers.

Cette combinaison de datasets ne donnera probablement pas une mesure unique de « l’impossibilité de s’ennuyer », mais elle permet de **documenter empiriquement** la réduction du temps libre non médié, la montée de l’occupation numérique continue, et de la relier à l’évolution des valeurs et du bien‑être.

---

## References

1. [The bright side of boredom](https://pmc.ncbi.nlm.nih.gov/articles/PMC4217352/) - Boredom proneness is commonly assessed and measured using self-report scales and questionnaires. The...

2. [Perceptions of Control Influence Feelings of Boredom](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2021.687623/full) - by AA Struk · 2021 · Cited by 39 — Conditions of low and high perceived control often lead to boredo...

3. [Boredom is actually linked to stress, say researchers](https://theworld.org/stories/2016/07/31/boredom-actually-linked-stress-say-researchers) - Boredom has more to do with stress than with our seemingly boring surroundings a new study has concl...

4. [Trait Boredom as a Lack of Agency: A Theoretical Model and a New Assessment Tool](https://pmc.ncbi.nlm.nih.gov/articles/PMC10822068/) - ...The aim of this study was to propose a comprehensive theory and a strong assessment tool to addre...

5. [Psychometric properties of an arabic translation of the short boredom proneness scale (SBPS) in adults](https://bmcpsychology.biomedcentral.com/articles/10.1186/s40359-024-02219-1) - The Short Boredom Proneness Scale (SBPS) is a common tool for assessing individuals’ inclination tow...

6. [A Trait-Based Network Perspective on the Validation of the French Short Boredom Proneness Scale](https://econtent.hogrefe.com/doi/10.1027/1015-5759/a000718) - Abstract. The Short Boredom Proneness Scale (SBPS) has recently been developed. Using a standard con...

7. [A Short Boredom Proneness Scale](https://journals.sagepub.com/doi/10.1177/1073191115609996)

8. [Short Boredom Proneness Scale: Adaptation and validation of a Chinese version with college students](https://www.ingentaconnect.com/content/10.2224/sbp.8968) - We translated the Short Boredom Proneness Scale (SBPS) into Chinese and tested its psychometric prop...

9. [Validation of a German version of the Boredom Proneness Scale and the Multidimensional State Boredom Scale](https://pmc.ncbi.nlm.nih.gov/articles/PMC10844236/) - ...report assessments which proved to faithfully reflect boredom in a vast range of experimental env...

10. [WVS Database](https://www.worldvaluessurvey.org/WVSContents.jsp?CMSID=Home&CMSID=Home) - World Values Survey Data-Archive Online Survey analysis website

11. [World Database of Happiness - Wikipedia](https://en.wikipedia.org/wiki/World_Database_of_Happiness)

12. [2.1. 3. Data Format](https://pmc.ncbi.nlm.nih.gov/articles/PMC12971072/) - This paper describes IPUMS ATUS, which simplifies the use of time diary data by disseminating a harm...

13. [American Time Use Survey Well‐Being Module Microdata Files](https://www.bls.gov/tus/modules/wbdatafiles.htm) - American Time Use Survey Well‐Being Module Microdata Files

14. [HETUS Harmonised European Time Use Survey](https://projectwelar.eu/datasets/hetus-harmonised-european-time-use-survey/) - round 2: HETUS 2010 took place during 2008 to 2015 and was conducted in 18 European countries: 15 EU...

15. [Overview - Harmonised European Time Use Surveys (HETUS)](https://ec.europa.eu/eurostat/web/time-use-surveys) - The harmonised European time use survey (HETUS) takes place every 10 years. Data is collected on a v...

16. [American Time Use Survey—ATUS 2003‐2024 Multi‐Year ...](https://www.bls.gov/tus/data/datafiles-0324.htm) - The ATUS multi-year microdata files combine several years of previously-released and publicly-availa...

17. [American Time Use Survey](https://datacatalog.med.nyu.edu/dataset/10035) - The data includes information collected from nearly 245,000 interviews conducted from 2003 to 2023. ...

18. [Mean of episode lengths as a quality indicator of time use diaries](https://www.semanticscholar.org/paper/cab33cd39b3bdc9c743fd81f898f2810ab62d6f1)

19. [Developing a Method to Test the Validity of 24 Hour Time Use Diaries Using Wearable Cameras: A Feasibility Pilot](https://pmc.ncbi.nlm.nih.gov/articles/PMC4669185/) - ... collect a continuous sequenced record of daily activities but the validity of the data they prod...

20. [Smartphone owners are now the global majority, New ...](https://www.gsma.com/newsroom/press-release/smartphone-owners-are-now-the-global-majority-new-gsma-report-reveals/) - Over half (54%) of the global population – some 4.3 billion people – now owns a smartphone, accordin...

21. [Smartphone adoption rate by region 2021-2030 | Statista](https://www.statista.com/statistics/1258906/worldwide-smartphone-adoption-rate-telecommunication-by-region/) - As of 2023, North America has the highest smartphone adoption rate with 84 percent of total mobile c...

22. [Technology Adoption - Our World in Data](https://snow-owid.netlify.app/technology-adoption) - This visualisation details the rates of diffusion and adoption of a range of technologies in the Uni...

23. [Mobile phone subscriptions per 100 people](https://ourworldindata.org/grapher/mobile-cellular-subscriptions-per-100-people) - The database covers a wide range of topics, including economic growth, education, health, poverty, t...

24. [Screen time among school-aged children of aged 6–14: a systematic review](https://pmc.ncbi.nlm.nih.gov/articles/PMC10113131/) - ...Cochrane Central Register of Controlled Trials, CNKI, and Whipple Journal databases from January ...

25. [Assessment of Changes in Child and Adolescent Screen Time During the COVID-19 Pandemic: A Systematic Review and Meta-analysis.](https://pmc.ncbi.nlm.nih.gov/articles/PMC9641597/) - ...collectively may have shifted screen time patterns.


Objective
To estimate changes in the durati...

26. [The time we spend on social media](https://datareportal.com/reports/digital-2024-deep-dive-the-time-we-spend-on-social-media) - A closer look at how much time the world spends using social media in 2024, with detailed stats by c...

27. [Track government measures on COVID-19 with the Oxford ...](https://data.europa.eu/en/publications/datastories/covid-19/track-government-measures-covid-19-oxford-government-response) - The Oxford COVID-19 Government Response Tracker enables a comparison of the measures that government...

28. [What is the COVID-19 Stringency Index?](https://ourworldindata.org/metrics-explained-covid19-stringency-index) - by M Roser · 2021 · Cited by 54 — The Oxford Coronavirus Government Response Tracker (OxCGRT) projec...

29. [SI_Stringency index by Country, Year, Month and Day- ...](https://px.web.ined.fr/GGP/pxweb/en/5%20Covid-19%20Policy%20Response/-/1.3_SI_final.px/) - the Covid-19 Government Response Tracker on 09/02/2023 Citation Guidelines: All data are free for sc...

30. [Harmonised European Time Use Survey , HETUS - B2SHARE](https://b2share.eudat.eu/records/1begr-30133) - The HETUS database compiles comparative time use data taken from the Harmonised European Time Use Su...

31. [Harmonised European Time Use Survey 2000 (HETUS 2000)](https://jp-demographic.eu/dataproject-home/dataproject-database-detail/?study=34&topic=3) - The European Time Use Survey (HETUS) provides data on time spent on various activities and the propo...

32. [Obtaining ATUS Data](https://www.bls.gov/tus/data.htm) - The 2003-2022 American Time Use Survey Microdata files have been archived. The newer multi-year micr...

33. [American Time Use Survey](https://en.wikipedia.org/wiki/American_Time_Use_Survey) - a time-use survey which provides measures of the amounts of time people spend on various activities,...

34. [The diurnal pattern and social context of screen behaviours in adolescents: a cross-sectional analysis of the Millennium Cohort Study](https://pmc.ncbi.nlm.nih.gov/articles/PMC9175381/) - ...and social settings in which young people accumulate screen time may help to inform the design of...

35. [Daily metabolic expenditures: estimates from US, UK and polish time-use data](https://bmcpublichealth.biomedcentral.com/articles/10.1186/s12889-019-6762-9) - BackgroundBehaviour has diverse economic, social and health consequences. Linking time spent in diff...

36. [Daily metabolic expenditures: estimates from US, UK and polish time-use data](https://pmc.ncbi.nlm.nih.gov/articles/PMC6546617/) - ...consequences of behaviour and identifying targets to improve population health and well-being.

#...

37. [WVS Database](https://www.worldvaluessurvey.org) - World Values Survey Data-Archive Online Survey analysis website.

38. [World Values Survey Wave 7 (2017-2020) Variables Report](https://www.statsclass.com/dsci310/Tasks/WorldValuesData_Codebook.pdf) - Important in life: Leisure time. For each of the following aspects, indicate how important it is in ...

39. [WORLD DATABASE OF HAPPINESS](https://hrcak.srce.hr/file/74335)

40. [Overview | World Database of Happiness](https://worlddatabaseofhappiness.eur.nl/this-database/overview-of-the-world-database-of-happiness/)

41. [Short Boredom Proneness Scale Responses](https://www.rdocumentation.org/packages/bgms/versions/0.1.6.1/topics/Boredom) - This dataset includes responses to the 8-item Short Boredom Proneness Scale (SBPS), a self-report me...

42. [Self-Reported Screen Time on Social Networking Sites Associated With Problematic Smartphone Use in Chinese Adults: A Population-Based Study](https://www.frontiersin.org/articles/10.3389/fpsyt.2020.614061/pdf) - Background: Problematic smartphone use (PSU) has been associated with screen time in general, but li...

43. [Boredom in the COVID-19 pandemic: Trait boredom proneness, the desire to act, and rule-breaking](https://pmc.ncbi.nlm.nih.gov/articles/PMC9045809/) - ...the COVID-19 pandemic. We collected data from 924 North American participants (530 Male, Mean age...

44. [A wearable sensors dataset for stress & boredom associated activity recognition](https://pmc.ncbi.nlm.nih.gov/articles/PMC11166685/) - ## Abstract

This article presents a dataset of activities associated with stress and boredom obtain...

45. [Screenomics: A New Approach for Observing and Studying Individuals’ Digital Lives](https://pmc.ncbi.nlm.nih.gov/articles/PMC7065687/) - ...days, hours, and minutes. Screenomes highlight the extent of switching among multiple application...

46. [Average Screen Time Statistics 2026: Are You Addicted?](https://affinco.com/average-screen-time-statistics/) - Daily device usage keeps climbing. See comprehensive Average Screen Time Statistics revealing how mu...

47. [Screen Time Trends: How COVID-19 Shaped Global Usage Patterns](https://www.accio.com/business/screen_time_trends) - Discover how screen time trends surged by 52% post-COVID, with teens averaging 8+ hours daily. Explo...

48. [23 Shocking Average Screen Time Statistics For 2026](https://adamconnell.me/average-screen-time-statistics/) - Want to learn more about the ways people interact with screens this year? Check out these 23 shockin...

49. [Leisure Activities of Healthy Children and Adolescents](https://www.mdpi.com/1660-4601/16/12/2078/pdf) - ...dancing, while children with higher SES met their friends more often. The time trend analysis sho...

50. [Oxford COVID-19 Government Response Tracker (OxCGRT)](https://extranet.who.int/countryplanningcycles/reportsportal/oxford-covid-19-government-response-tracker-oxcgrt) - The Oxford COVID-19 Government Response Tracker (OxCGRT) systematically collects information on seve...

51. [Increased Screen Time and Dry Eye: Another Complication of COVID-19](https://journals.lww.com/10.1097/ICL.0000000000000820) - During a time of relative social isolation because of the coronavirus disease 2019 (COVID-19) virus,...

