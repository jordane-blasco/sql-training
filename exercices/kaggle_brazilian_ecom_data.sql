/*
Création des tables Brazilian ecommerce pour importer les fichiers csv
*/

CREATE TABLE customers (
    customer_id VARCHAR PRIMARY KEY,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city VARCHAR,
    customer_state VARCHAR
);

CREATE TABLE orders (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id VARCHAR,
    order_item_id INTEGER,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

CREATE TABLE order_payments (
    order_id VARCHAR,
    payment_sequential INTEGER,
    payment_type VARCHAR,
    payment_installments INTEGER,
    payment_value NUMERIC
);

CREATE TABLE order_reviews (
    review_id VARCHAR,
    order_id VARCHAR,
    review_score INTEGER,
    review_comment_title VARCHAR,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE products (
    product_id VARCHAR PRIMARY KEY,
    product_category_name VARCHAR,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE sellers (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix VARCHAR,
    seller_city VARCHAR,
    seller_state VARCHAR
);

CREATE TABLE category_translation (
    product_category_name VARCHAR PRIMARY KEY,
    product_category_name_english VARCHAR
);

/*
Vérification que les tables ont bien été ingérées via union all et count(*)
*/

select'category translation' AS table_name, COUNT(*) AS nb_lignes
FROM category_translation ct
UNION ALL
SELECT  'customers'
       ,COUNT(*)
FROM customers c
UNION ALL
SELECT  'order_items'
       ,COUNT(*)
FROM order_items
UNION ALL
SELECT  'order_payments'
       ,COUNT(*)
FROM order_payments
UNION ALL
SELECT  'order_reviews'
       ,COUNT(*)
FROM order_reviews
UNION ALL
SELECT  'orders'
       ,COUNT(*)
FROM orders
UNION ALL
SELECT  'products'
       ,COUNT(*)
FROM products p
UNION ALL
SELECT  'sellers'
       ,COUNT(*)
FROM sellers s

/*
Exercice 1 — Exploration de base
Affiche les 10 premières commandes de la table orders avec toutes leurs colonnes, uniquement celles qui ont le statut delivered.
*/
SELECT  *
FROM orders
WHERE order_status = 'delivered'
LIMIT 10;

/*
Exercice 2 — Agrégat
Affiche le nombre de commandes par statut, trié par nombre décroissant.
*/

SELECT  o.order_status             AS status
       ,COUNT(distinct o.order_id) AS nbr_commandes
FROM orders o
GROUP BY  o.order_status
ORDER BY  nbr_commandes desc

/*
Exercice 3 — JOIN
Affiche le nom de la ville (customer_city) et le nombre de clients distincts par ville, uniquement pour les villes qui ont plus de 100 clients. Trié par nombre de clients décroissant.
*/

SELECT  c.customer_city AS ville
       ,COUNT(customer_id) nbr_customers
FROM customers c
GROUP BY  c.customer_city
HAVING COUNT(customer_id) > 100
ORDER BY nbr_customers desc;

/*
Exercice 4 — JOIN
Affiche pour chaque commande :

l'order_id
la customer_city du client
le order_status
le payment_value total de la commande

Trié par payment_value décroissant, limite 20 résultats.
*/

SELECT  o.order_id       AS id_commande
       ,c.customer_city  AS ville_client
       ,o.order_status   AS statut_commande
       ,op.payment_value AS montant
FROM orders o
INNER JOIN order_payments op
ON o.order_id = op.order_id
INNER JOIN customers c
ON o.customer_id = c.customer_id
ORDER BY montant DESC
LIMIT 20
;

/*
Exercice 5 — Agrégat + JOIN
Affiche le chiffre d'affaires total par ville (customer_city), uniquement pour les villes avec un CA supérieur à 50 000. Trié par CA décroissant.
*/

SELECT  c.customer_city       AS ville
       ,SUM(op.payment_value) AS CA
FROM orders o
INNER JOIN order_payments op
ON o.order_id = op.order_id
INNER JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY  c.customer_city
HAVING SUM(op.payment_value) > 50000
ORDER BY ca desc;

/*
Exercice 6 — CASE WHEN
On reprend là où on s'était arrêtés hier. Affiche pour chaque commande :

l'order_id
le payment_value
une colonne segment_paiement :

'Petit' si payment_value < 50
'Moyen' si payment_value entre 50 et 200
'Grand' si payment_value > 200

Trié par payment_value décroissant.
*/


SELECT  o.order_id                                                           AS id_commande
       ,op.payment_value                                                     AS montant
       ,CASE WHEN op.payment_value < 50 THEN 'Petit'
             WHEN op.payment_value BETWEEN 50 AND 200 THEN 'Moyen'
             WHEN op.payment_value > 200 THEN 'Grand'  ELSE 'hors scope' END AS segment_paiement
FROM orders o
INNER JOIN order_payments op
ON o.order_id = op.order_id
ORDER BY montant desc;

/*
Exercice 7 — CASE WHEN + agrégat
Affiche le nombre de commandes et le CA total par segment de paiement (Petit / Moyen / Grand), trié par CA décroissant.
C'est le même CASE WHEN que l'exercice précédent, mais cette fois tu dois agréger les résultats par segment.
*/

SELECT  CASE WHEN op.payment_value < 50 THEN 'Petit'
             WHEN op.payment_value BETWEEN 50 AND 200 THEN 'Moyen'
             WHEN op.payment_value > 200 THEN 'Grand'  ELSE 'hors scope' END AS segment_paiement
       ,COUNT(o.order_id)                                                    AS nbr_commandes
       ,round(SUM(op.payment_value))                                         AS CA_total
FROM orders o
INNER JOIN order_payments op
ON o.order_id = op.order_id
GROUP BY  segment_paiement
ORDER BY  CA_total desc;

/*
Exercice 8 — Window function
Affiche pour chaque commande :

l'order_id
le payment_value
le rang de la commande par montant décroissant par ville (customer_city)

Limite aux 50 premiers résultats, trié par ville puis par rang.
*/

SELECT  c.customer_city                                                           AS ville
       ,o.order_id                                                                AS commande
       ,op.payment_value                                                          AS montant
       ,rank() over(PARTITION BY c.customer_city ORDER BY  op.payment_value DESC) AS rang_commande
FROM order_payments op
INNER JOIN orders o
ON op.order_id = o .order_id
INNER JOIN customers c
ON c.customer_id = o.customer_id
ORDER BY ville, rang_commande
LIMIT 50

/*
Exercice 9 — CTE + window function
Affiche uniquement la commande la plus chère par ville, avec :

la customer_city
l'order_id
le payment_value

Trié par payment_value décroissant.
*/

WITH commande_max AS
(
	SELECT  c.customer_city                                                            AS ville
	       ,o.order_id                                                                 AS commandes
	       ,op.payment_value                                                           AS montant
	       ,rank() over(PARTITION BY c.customer_city ORDER BY  op.payment_value DESC ) AS rank
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
)
SELECT  cm.ville
       ,cm.commandes
       ,cm.montant
FROM commande_max cm
WHERE cm.rank = 1
ORDER BY cm.montant desc;

/*
Exercice 10 — Analyse métier (intermédiaire)
Affiche le top 10 des catégories de produits (en anglais grâce à category_translation) par chiffre d'affaires total, avec :

le nom de la catégorie en anglais
le nombre de produits distincts vendus
le CA total (arrondi)

Trié par CA décroissant.
*/

SELECT  ct.product_category_name_english AS category
       ,COUNT(distinct p.product_id)     AS produits_distincts
       ,round(SUM(op.payment_value))     AS montants
FROM orders o
INNER JOIN order_items oi
ON o.order_id = oi.order_id
INNER JOIN order_payments op
ON o.order_id = op.order_id
INNER JOIN products p
ON oi.product_id = p.product_id
INNER JOIN category_translation ct
ON p.product_category_name = ct.product_category_name
GROUP BY  ct.product_category_name_english
ORDER BY  montants DESC
LIMIT 10;

/*
Exercice 11 — Analyse vendeurs
Affiche le top 10 des vendeurs par nombre de commandes livrées (delivered), avec :

le seller_id
la ville du vendeur (seller_city)
le nombre de commandes livrées
le CA total généré (arrondi)

Trié par nombre de commandes décroissant.
*/

SELECT  s.seller_id                  AS vendeur
       ,s.seller_city                AS ville_vendeur
       ,COUNT(o.order_id)            AS nbr_commandes
       ,round(SUM(op.payment_value)) AS montant
FROM sellers s
INNER JOIN order_items oi
ON s.seller_id = oi.seller_id
INNER JOIN orders o
ON oi.order_id = o.order_id 
-- INNER JOIN pour vérifier qu'on ne perd pas de commandes entre les tables order_items et orders 
INNER JOIN order_payments op
ON o.order_id = op.order_id 
-- INNER JOIN pour vérifier qu'on n'a bien un montant pour chaque commande 
WHERE o.order_status = 'delivered'
GROUP BY  vendeur
         ,ville_vendeur
ORDER BY  nbr_commandes DESC
LIMIT 10;


/*
Exercice 12 — Analyse temporelle
Affiche le CA mensuel sur toute la période disponible, avec :

l'année
le mois
le nombre de commandes
le CA total (arrondi)
la variation du CA par rapport au mois précédent (arrondie)

Trié par année et mois croissants.
*/

WITH table_ca AS
(
	SELECT  extract(year
	FROM o.order_purchase_timestamp) AS annee, extract(month
	FROM o.order_purchase_timestamp) AS mois, COUNT(o.order_id) AS nbr_commandes, round(SUM(op.payment_value)) AS montant
	FROM orders o
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
	GROUP BY  1
	         ,2
)
SELECT  *
       ,montant - lag(montant,1,0) OVER (order by annee,mois) AS difference_month_before
FROM table_ca
ORDER BY 1, 2;


/*
Exercice 13 — Ranking par catégorie
Pour chaque catégorie de produit, affiche :

le nom de la catégorie en anglais
le CA total (arrondi)
le rang de la catégorie par CA décroissant

Trié par rang croissant.
La table category_translation te sera utile.
*/
SELECT  ct.product_category_name_english                 AS category_name
       ,SUM(op.payment_value)                            AS montant
       ,rank() over(order by SUM(op.payment_value) DESC) AS rang
FROM products p
LEFT JOIN category_translation ct
ON p.product_category_name = ct.product_category_name -- capturer si des product_id n'ont pas de catégorie 
LEFT JOIN order_items oi
ON p.product_id = oi.product_id --
LEFT JOIN ici car
ON tous les product_id dans products non pas forcément de valeur dans order_items 
LEFT JOIN order_payments op
ON oi.order_id = op.order_id --
LEFT JOIN ici car
ON veut conserver les lignes des deux
LEFT JOIN précédents 
GROUP BY  1;

/*
Exercice 14 — Top 3 des vendeurs par état
Pour chaque état du vendeur, affiche les 3 meilleurs vendeurs par CA, avec :

l'état
l'identifiant du vendeur
le CA total (arrondi)
leur rang dans l'état

Trié par état, puis rang croissant.
Indice : tu auras besoin d'une window function avec PARTITION BY, et d'un moyen de filtrer sur le rang dans un second temps.
*/

WITH eval_rank AS
(
	SELECT  s.seller_state                                                                AS etat_vendeur
	       ,s.seller_id                                                                   AS id_vendeur
	       ,round(SUM(op.payment_value))                                                  AS montant
	       ,rank() over(PARTITION BY s.seller_state ORDER BY  SUM(op.payment_value) DESC) AS rank_ca
	FROM sellers s
	INNER JOIN order_items oi
	ON s.seller_id = oi.seller_id
	INNER JOIN order_payments op
	ON oi.order_id = op.order_id
	GROUP BY  1
	         ,2
	ORDER BY  1
	         ,4
)
SELECT  *
FROM eval_rank
WHERE rank_ca <= 3 /* */
-- création de la 1ere cte afin d'avoir une "base" générale 
 
/*
Exercice 15 — Cohortes clients
Pour chaque mois d'acquisition (le mois de leur première commande), affiche :

l'année et le mois d'acquisition
le nombre de nouveaux clients acquis ce mois-là
le CA total généré par ces clients sur l'ensemble de leur vie (pas uniquement le mois d'acquisition)

Trié par année et mois croissants.
Indice : tu auras besoin d'identifier pour chaque client sa première commande, puis de relier ces clients à toutes leurs commandes.
*/

-- création de la 1ere cte afin d'avoir une "base" générale
WITH request_basis AS (
SELECT  
extract(year FROM order_purchase_timestamp) AS annee, 
extract(month FROM order_purchase_timestamp) AS mois, 
--extract(epoch FROM order_purchase_timestamp) AS epoch, 
customer_id AS client_id, 
SUM(op.payment_value) AS montant
FROM orders o
LEFT JOIN order_payments op
ON o.order_id = op.order_id -- utilisation du LEFT JOIN car tous les order_id n'ont pas de valeur payment_value 
GROUP BY  1
         ,2
         ,3 ORDER BY  1,2 )
,rang_commande AS
(
	-- identifions la première commande des clients 
	SELECT  *
	       ,ROW_NUMBER() over(PARTITION BY client_id ORDER BY  annee,mois) AS rang_commande
	FROM request_basis
	ORDER BY annee, mois
)
-- TABLE finale 
SELECT  rc.annee
       ,rc.mois
       ,COUNT(rc.client_id)    AS nbr_clients_acquis
       ,round(SUM(rb.montant)) AS montant_total
FROM rang_commande rc
INNER JOIN request_basis rb
ON rc.client_id = rb.client_id
WHERE rc.rang_commande = 1
GROUP BY  1
         ,2
ORDER BY  1
         ,2;

/*
Exercice 16 — Rétention à M+1
En repartant de la logique de cohorte, affiche pour chaque mois d'acquisition le nombre de clients qui ont passé au moins une commande le mois suivant (M+1).
Résultat attendu :

l'année et le mois d'acquisition
le nombre de clients acquis ce mois-là
le nombre de ces clients qui ont recommandé en M+1

Trié par année et mois croissants.
*/


-- cte d'acquision de la 1ere commande
WITH data_base AS
(
	SELECT  extract(year
	FROM o.order_purchase_timestamp) AS year, extract(month
	FROM o.order_purchase_timestamp) AS month, o.order_purchase_timestamp AS timestamp, o.order_id AS commande, c.customer_unique_id AS client_id
	--count(distinct o.customer_id) AS clients_uniques 
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	WHERE o.order_status = 'delivered'
	ORDER BY year, month 
), rang_commande AS
(
	SELECT  year
	       ,month
	       ,timestamp
	       ,client_id
	       ,ROW_NUMBER() over(PARTITION BY client_id ORDER BY  year,month) AS rang
	FROM data_base
	ORDER BY 1, 2, 3, 4
), table_all_orders AS
(
	SELECT  year
	       ,month
	       ,date_trunc('month',timestamp) + interval '1 month' AS month_plus_1
	       ,rang
	       ,client_id
	FROM rang_commande
	WHERE rang = 1 
), table_month_plus AS
(
	SELECT  year
	       ,month
	       ,client_id
	       ,date_trunc('month',timestamp) AS current_month
	FROM data_base
	GROUP BY  1
	         ,2
	         ,3
	         ,4
)
SELECT  ftc.year
       ,ftc.month
       ,COUNT(distinct ftc.client_id) AS acquisition
       ,COUNT(distinct ftm.client_id) AS month_plus
FROM table_all_orders ftc
LEFT JOIN table_month_plus ftm
ON ftm.current_month = ftc.month_plus_1 AND ftm.client_id = ftc.client_id
GROUP BY  1
         ,2
;

/*
La requête s'est construite en plusieurs étapes :
1. data_base — la fondation. Tu récupères toutes les commandes delivered avec leur date, leur order_id et customer_unique_id (après correction du problème Olist).
2. rang_commande — tu appliques ROW_NUMBER() OVER(PARTITION BY client_id ORDER BY year, month) pour numéroter les commandes de chaque client par ordre chronologique.
3. table_all_orders — tu filtres sur rang = 1 pour n'avoir que les premières commandes (mois d'acquisition), et tu calcules DATE_TRUNC('month', timestamp) + INTERVAL '1 month' pour obtenir le mois M+1 cible de chaque client.
4. table_month_plus — tu reprends data_base avec toutes les commandes et tu tronques leur date au mois avec DATE_TRUNC. C'est la table qui te dit "ce client a été actif ce mois-là".
5. SELECT final — tu jointures les deux tables sur deux conditions : current_month = month_plus_1 ET client_id = client_id. Ainsi tu ne récupères que les clients acquis en M qui ont aussi commandé en M+1. Tu agrèges avec COUNT(DISTINCT client_id) pour obtenir les deux métriques.
Le point clé de cet exercice : la jointure sur deux colonnes simultanément est ce qui garantit qu'on compte uniquement les bons clients, pas tous les actifs du mois.
*/


/*
Exercice 17 — Taux de rétention M+1
Repars de la requête de l'exercice 16 et ajoute une colonne taux de rétention exprimée en pourcentage, arrondie à 2 décimales.
Exemple : si 750 clients ont été acquis en janvier 2017 et 2 ont recommandé en M+1, le taux est 2 / 750 * 100 = 0.27%.
*/


-- cte d'acquision de la 1ere commande
WITH data_base AS (
SELECT  extract(year
FROM o.order_purchase_timestamp) AS year, extract(month
FROM o.order_purchase_timestamp) AS month, o.order_purchase_timestamp AS timestamp, o.order_id AS commande, c.customer_unique_id AS client_id
--count(distinct o.customer_id) AS clients_uniques 
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
ORDER BY year,month ), rang_commande AS (
SELECT  year
       ,month
       ,timestamp
       ,client_id
       ,ROW_NUMBER() over(PARTITION BY client_id ORDER BY  year,month) AS rang
FROM data_base ORDER BY 1,2,3,4 ), table_all_orders AS (
SELECT  year
       ,month
       ,date_trunc('month',timestamp) + interval '1 month' AS month_plus_1
       ,rang
       ,client_id
FROM rang_commande
WHERE rang = 1 ), table_month_plus AS (
SELECT  year
       ,month
       ,client_id
       ,date_trunc('month',timestamp) AS current_month
FROM data_base
GROUP BY  1
         ,2
         ,3
         ,4 )
SELECT  ftc.year
       ,ftc.month
       ,COUNT(distinct ftc.client_id)                                                                AS acquisition
       ,COUNT(distinct ftm.client_id)                                                                AS month_plus
       ,round(cast(COUNT(distinct ftm.client_id) AS numeric)/ COUNT(distinct ftc.client_id),4) * 100 AS retention_rate
FROM table_all_orders ftc
LEFT JOIN table_month_plus ftm
ON ftm.current_month = ftc.month_plus_1 AND ftm.client_id = ftc.client_id
GROUP BY  1
         ,2;

-- Ici on a du "caster" via la fonction cast() car count() renvoie un bigint et donc la division de deux chiffres
-- entiers renvoie un chiffre entier. Appliquer cast([colonne ou valeur] as numeric) sur une seule de ces valeurs va renvoyer
-- un chiffre décimal. On applique un round() pour ne pas avoir un % à rallonge



/*
Exercice 18 — Revenu cumulé par cohorte
Repars de la logique de cohorte. Pour chaque mois d'acquisition, affiche le revenu total généré mois par mois depuis l'acquisition, avec :

le mois d'acquisition
le nombre de mois écoulés depuis l'acquisition (0 = mois d'acquisition, 1 = M+1, 2 = M+2, etc.)
le CA généré par la cohorte ce mois-là
le CA cumulé depuis l'acquisition

Trié par mois d'acquisition, puis nombre de mois écoulés.
*/

--création de la TABLE cte de base
WITH data_base AS
(
	SELECT  extract('year'
	FROM o.order_purchase_timestamp) AS annee, extract('month'
	FROM o.order_purchase_timestamp) AS mois, o.order_purchase_timestamp AS timestamp, c.customer_unique_id AS client_id, o.order_id AS commandes, op.payment_value AS montant
	FROM orders o
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	ORDER BY 1, 2
), rang_window AS
(
	SELECT  *
	       ,ROW_NUMBER() over(PARTITION BY client_id ORDER BY  annee,mois) AS rang
	FROM data_base
), cte_mois_acquisition AS
(
	SELECT  *
	FROM rang_window
	WHERE rang = 1 
), mois_ecoules as(
SELECT  cma.annee  AS acquisition_annee
       ,cma.mois   AS acquisition_mois
       ,db.montant AS acquisition_montant
       ,(extract('year'FROM age(db.timestamp, cma.timestamp))*12) + 
       extract('month' FROM age (db.timestamp, cma.timestamp)) AS mois_ecoules
FROM cte_mois_acquisition cma
LEFT JOIN data_base db
ON cma.client_id = db.client_id ), ca_par_mois AS
(
	SELECT  acquisition_annee
	       ,acquisition_mois
	       ,mois_ecoules             AS mois_depuis_acquisition
	       ,SUM(acquisition_montant) AS montant_mois
	FROM mois_ecoules
	GROUP BY  1
	         ,2
	         ,3
	ORDER BY  1
	         ,2
)
SELECT  *
       ,SUM(montant_mois) over(PARTITION BY acquisition_annee,acquisition_mois ORDER BY  mois_depuis_acquisition ) AS CA_cumule
FROM ca_par_mois
ORDER BY acquisition_annee, acquisition_mois

/*
Ex 16 : rétention M+1 — double jointure sur client_id ET mois, DATE_TRUNC + INTERVAL, problème customer_id vs customer_unique_id dans Olist
Ex 17 : taux de rétention — division décimale avec CAST, ordre du calcul month_plus / acquisition * 100
Ex 18 : revenu cumulé par cohorte — AGE() pour calculer les mois écoulés, SUM() OVER(PARTITION BY cohorte ORDER BY mois_ecoules) pour le cumulatif, nécessité d'une CTE intermédiaire avant d'appliquer la window function

Point récurrent : les window functions ne peuvent pas être appliquées sur des colonnes déjà agrégées dans la même requête — il faut passer par une CTE.
*/

/*
Exercice 19 — Taille et revenu moyen par cohorte
Définis la cohorte d'un client par le mois de sa première commande (via customer_unique_id).
Objectif : pour chaque cohorte, afficher :

le mois de cohorte
le nombre de clients dans cette cohorte
le revenu total généré par ces clients sur l'ensemble de leur vie (lifetime revenue)
le revenu moyen par client

Trie par mois de cohorte croissant.
*/

WITH cte_db AS
(
	SELECT  extract('year'
	FROM o.order_purchase_timestamp) AS annee, extract('month'from o.order_purchase_timestamp) AS mois, c.customer_unique_id AS client_unique, o.order_id AS commande, SUM(op.payment_value) AS montant, o.order_purchase_timestamp AS timestamp
	FROM orders o
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY  1
	         ,2
	         ,3
	         ,4
	         ,6
	ORDER BY  1
	         ,2
), rang_commande AS
(
	SELECT  *
	       ,ROW_NUMBER() over(PARTITION BY client_unique ORDER BY  annee,mois) AS rang
	FROM cte_db
	ORDER BY 1, 2
), acquisition AS
(
	SELECT  *
	FROM rang_commande
	WHERE rang = 1 
), final_cte AS
(
	SELECT  a.annee
	       ,a.mois
	       ,a.client_unique
	       ,a.timestamp
	       ,a.commande
	       ,db.montant
	FROM acquisition a
	INNER JOIN cte_db db
	ON a.client_unique = db.client_unique
)
SELECT  annee
       ,mois
       ,COUNT(distinct client_unique)                         AS nbr_clients
       ,SUM(montant)                                          AS ca_total
       ,round(SUM(montant) / COUNT(distinct client_unique),1) AS revenu_moyen
FROM final_cte
GROUP BY  1
         ,2
ORDER BY  1
         ,2

/*

*/


-- 20
WITH cte_db AS
(
	SELECT  extract('year'
	FROM o.order_purchase_timestamp) AS annee, extract('month'from o.order_purchase_timestamp) AS mois, c.customer_unique_id AS client_unique, o.order_id AS commande, SUM(op.payment_value) AS montant, o.order_purchase_timestamp AS timestamp
	FROM orders o
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY  1
	         ,2
	         ,3
	         ,4
	         ,6
	ORDER BY  1
	         ,2
), rang_commande AS
(
	SELECT  *
	       ,ROW_NUMBER() over(PARTITION BY client_unique ORDER BY  annee,mois) AS rang
	FROM cte_db
	ORDER BY 1, 2
), acquisition AS
(
	SELECT  *
	FROM rang_commande
	WHERE rang = 1 
), final_cte AS
(
	SELECT  a.annee
	       ,a.mois
	       ,a.client_unique
	       ,a.timestamp
	       ,a.commande
	       ,db.montant
	       ,(extract('year'
	FROM age
	(db.timestamp, a.timestamp
	))*12) + extract('month'
	FROM age
	(db.timestamp, a.timestamp
	)) AS mois_écoulés
	FROM acquisition a
	INNER JOIN cte_db db
	ON a.client_unique = db.client_unique
)
SELECT  annee
       ,mois
       ,mois_écoulés
       ,COUNT(distinct client_unique)                         AS nbr_clients
       ,SUM(montant)                                          AS ca_total
       ,round(SUM(montant) / COUNT(distinct client_unique),1) AS revenu_moyen
FROM final_cte
GROUP BY  1
         ,2
         ,3
ORDER BY  1
         ,2

/*
Exercice 21 — Taux de rétention cumulatif par cohorte
Repars de la même logique. Cette fois, pour chaque cohorte et chaque mois écoulé, calcule le taux de rétention — c'est-à-dire le pourcentage de clients de la cohorte initiale qui sont encore actifs à ce mois-là.
Pour être clair :

Au mois 0, le taux est toujours 100%
Au mois 1, si 321 clients ont été acquis et 45 ont repassé commande, le taux est 45/321 = 14%
etc.

Affiche :

le mois de cohorte
le mois écoulé
le nombre de clients actifs ce mois-là
la taille initiale de la cohorte (nombre de clients au mois 0)
le taux de rétention en %

Trie par cohorte et mois écoulés.
*/

	WITH cte_db AS
(
	SELECT  extract('year'
	FROM o.order_purchase_timestamp) AS annee, extract('month'from o.order_purchase_timestamp) AS mois, c.customer_unique_id AS client_unique, o.order_id AS commande, SUM(op.payment_value) AS montant, o.order_purchase_timestamp AS timestamp
	FROM orders o
	INNER JOIN order_payments op
	ON o.order_id = op.order_id
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY  1
	         ,2
	         ,3
	         ,4
	         ,6
	ORDER BY  1
	         ,2
), rang_commande AS
(
	SELECT  *
	       ,ROW_NUMBER() over(PARTITION BY client_unique ORDER BY  annee,mois) AS rang
	FROM cte_db
	ORDER BY 1, 2
), acquisition AS
(
	SELECT  *
	FROM rang_commande
	WHERE rang = 1 
), final_cte AS
(
	SELECT  a.annee
	       ,a.mois
	       ,a.client_unique
	       ,a.timestamp
	       ,a.commande
	       ,db.montant
	       ,(extract('year'	FROM age(db.timestamp, a.timestamp))*12) 
           + extract('month'FROM age(db.timestamp, a.timestamp)) AS mois_écoulés
	FROM acquisition a
	INNER JOIN cte_db db
	ON a.client_unique = db.client_unique
), final_db AS
(
	SELECT  annee
	       ,mois
	       ,mois_écoulés
	       ,COUNT(distinct client_unique)                         AS nbr_clients
	       ,SUM(montant)                                          AS ca_total
	       ,round(SUM(montant) / COUNT(distinct client_unique),1) AS revenu_moyen
	FROM final_cte
	GROUP BY  1
	         ,2
	         ,3
	ORDER BY  1
	         ,2
), taille_cohorte AS
(  
	SELECT  fdb.annee
	       ,fdb.mois
	       ,fdb.mois_écoulés
	       ,fdb.nbr_clients
	       ,MAX(CASE WHEN mois_écoulés = 0 THEN nbr_clients END) OVER (PARTITION BY annee,mois) AS taille_cohorte
	       ,fdb.ca_total
	       ,fdb.revenu_moyen
	FROM final_db fdb
)
SELECT  *
       ,round((cast(nbr_clients AS numeric) / taille_cohorte),4) * 100 AS retention_rate
FROM taille_cohorte

/*
Exercice 22 — la suite logique : generate_series()
L'idée : générer une série complète de mois (même ceux sans données), puis faire un LEFT JOIN avec tes données réelles pour que les mois vides apparaissent avec des zéros plutôt que d'être absents.

*/

WITH cte_basis AS
(
	SELECT  date_trunc('month',o.order_purchase_timestamp) AS mois_cohorte
	       ,c.customer_unique_id                           AS client_id
	       ,o.order_id                                     AS commande
	       ,o.order_purchase_timestamp                     AS timestamp
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
), rang_commande AS
(
	SELECT  *
	       ,rank() over(PARTITION BY client_id ORDER BY  mois_cohorte) AS rang
	FROM cte_basis
), commande_une AS
(
	SELECT  *
	FROM rang_commande
	WHERE rang = 1 
), mois_ecoules AS
(
	SELECT  cu.mois_cohorte AS mois_cohorte_acquisition
	       ,cu.client_id    AS client_id_acquisition
	       ,cu.commande     AS cmd_acquisition
	       ,cu.timestamp    AS tmp_acquisition
	       ,cb.timestamp    AS tmp_toutes_cmd
	       ,(extract('year'	FROM age(cb.timestamp, cu.timestamp	))*12) + extract('month'FROM age(cb.timestamp, cu.timestamp
	)) AS mois_écoulés
	FROM commande_une cu
	INNER JOIN cte_basis cb
	ON cu.client_id = cb.client_id
), full_mois_ecoules AS
(
	SELECT  distinct mois_cohorte_acquisition
	       ,s.mois AS mois
	FROM mois_ecoules
	CROSS JOIN generate_series
	(0, 11, 1
	) AS s(mois)
	ORDER BY 1, 2
)
SELECT  fme.mois_cohorte_acquisition             AS mois_cohorte
       ,fme.mois                                 AS mois_écoulés
       ,COUNT(distinct me.client_id_acquisition) AS nbr_clients
       ,COUNT(distinct me.cmd_acquisition)       AS nbr_commandes
FROM full_mois_ecoules fme  
LEFT JOIN mois_ecoules me
ON fme.mois_cohorte_acquisition = me.mois_cohorte_acquisition AND fme.mois = me.mois_écoulés
WHERE fme.mois_cohorte_acquisition IN ( SELECT mois_cohorte_acquisition FROM mois_ecoules WHERE mois_écoulés = 0 GROUP BY 1 HAVING COUNT(distinct cmd_acquisition) > 50 )
GROUP BY  1
         ,2

/*
Exercice 23
On reste sur l'analyse de cohortes, mais on change d'angle.
Objectif : Calcule le taux de rétention par cohorte et par mois écoulé, en t'assurant que les mois sans activité affichent 0% plutôt que d'être absents.
Colonnes attendues :

mois_cohorte
mois_ecoulés (0 à 11)
nbr_clients
taux_retention (en %, arrondi à 2 décimales)

Contraintes :

Ne garde que les cohortes avec 50+ clients en mois 0
Le taux de rétention = clients actifs au mois N / clients en mois 0
Le mois 0 doit afficher 100%
*/

WITH cte_basis AS
(
	SELECT  date_trunc('month',o.order_purchase_timestamp) AS mois_cohorte
	       ,c.customer_unique_id                           AS client_id
	       ,o.order_id                                     AS commande
	       ,o.order_purchase_timestamp                     AS timestamp
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
), rang_commande AS
(
	SELECT  *
	       ,rank() over(PARTITION BY client_id ORDER BY  mois_cohorte) AS rang
	FROM cte_basis
), commande_une AS
(
	SELECT  *
	FROM rang_commande
	WHERE rang = 1 
), group_cte AS
(
	SELECT  cu.mois_cohorte
	       ,cu.client_id
	       ,cu.commande
	       ,cu.timestamp
	       ,(extract('year'
	FROM age
	(cb.timestamp, cu.timestamp
	))*12) + extract('month'
	FROM age
	(cb.timestamp, cu.timestamp
	)) AS mois_ecoules
	FROM commande_une cu
	INNER JOIN cte_basis cb
	ON cu.client_id = cb.client_id
), mois_generate AS
(
	SELECT  distinct mois_cohorte
	       ,s.mois AS mois
	FROM group_cte
	CROSS JOIN generate_series
	(0, 11, 1
	) AS s(mois)
	ORDER BY 1, 2
), group_cohorte AS
(
	SELECT  mg.mois_cohorte
	       ,mg.mois
	       ,COUNT(distinct gc.client_id) AS nbr_clients
	FROM mois_generate mg
	LEFT JOIN group_cte gc
	ON mg.mois_cohorte = gc.mois_cohorte AND mg.mois = gc.mois_ecoules
	GROUP BY  1
	         ,2
	ORDER BY  1
	         ,2
), propagation_mois AS
(
	SELECT  *
	       ,MAX(case WHEN mois = 0 THEN nbr_clients end) over(PARTITION BY mois_cohorte) AS max_retention
	FROM group_cohorte gch
), retention_rate as(
SELECT  *
       ,round((cast(nbr_clients AS numeric)/max_retention),4) * 100 AS retention_rate
FROM propagation_mois )
SELECT  mois_cohorte
       ,mois
       ,nbr_clients
       ,retention_rate
FROM retention_rate
WHERE mois_cohorte IN ( SELECT mois_cohorte FROM group_cohorte WHERE mois = 0 AND nbr_clients > 50 )

/*
Exercice 24
On change de thème — on quitte les cohortes pour travailler sur l'analyse des vendeurs.
Objectif : Identifie les vendeurs dans le top 25% en termes de chiffre d'affaires, et pour chacun d'eux affiche :

seller_id
chiffre_affaires (somme des paiements liés à leurs commandes)
quartile (1, 2, 3 ou 4)

Contraintes :

Ne garde que les vendeurs en quartile 1 (top 25%)
Utilise une window function pour calculer le quartile
*/

WITH payments AS
(
	SELECT  order_id              AS commande
	       ,SUM(op.payment_value) AS mtn_commande
	FROM order_payments op
	GROUP BY  1
	ORDER BY  2 DESC
), top25 AS
(
	SELECT  s.seller_id                                     AS vendeur
	       ,SUM(p.mtn_commande)                             AS mtn_ca
	       ,ntile(4) over(order by SUM(p.mtn_commande)desc) AS quartile
	FROM sellers s
	INNER JOIN order_items oi
	ON s.seller_id = oi.seller_id
	INNER JOIN payments p
	ON oi.order_id = p.commande
	GROUP BY  1
)
SELECT  *
FROM top25
WHERE quartile = 1

/*
Exercice 25
On reste sur l'analyse des vendeurs mais on ajoute une dimension temporelle.
Objectif : Pour chaque vendeur, calcule son chiffre d'affaires mensuel et affiche la variation en % par rapport au mois précédent.
Colonnes attendues :

seller_id
mois (ex: 2017-01-01)
ca_mensuel
ca_mois_precedent
variation_pct (arrondi à 2 décimales, en %)

Contraintes :

Ignore les vendeurs sans commandes
Le premier mois d'un vendeur aura NULL pour ca_mois_precedent et variation_pct — c'est normal
*/

WITH payments_agg AS
(
	SELECT  op.order_id            AS order_id
	       ,SUM(op.payment_value ) AS montant_commande
	FROM order_payments op
	GROUP BY  1
	ORDER BY  2 DESC
), joining_table AS
(
	SELECT  date_trunc('month',o.order_purchase_timestamp) AS date
	       ,s.seller_id                                    AS vendeur
	       ,pa.montant_commande                            AS mtn_ca
	FROM sellers s
	INNER JOIN order_items oi
	ON s.seller_id = oi.seller_id
	INNER JOIN payments_agg pa
	ON oi.order_id = pa.order_id
	INNER JOIN orders o
	ON pa.order_id = o.order_id
	ORDER BY 1
), grouping_data AS
(
	SELECT  vendeur
	       ,date
	       ,SUM(mtn_ca) AS mtn_ca
	FROM joining_table
	GROUP BY  1
	         ,2
), ca_mois_dernier AS
(
	SELECT  vendeur
	       ,date
	       ,mtn_ca
	       ,lag(mtn_ca,1,Null) over(PARTITION BY vendeur ORDER BY  date) AS ca_mois_dernier
	FROM grouping_data
	ORDER BY vendeur, date
)
SELECT  *
       ,round(((mtn_ca - ca_mois_dernier )/ ca_mois_dernier) * 100,2) AS variation_pct
FROM ca_mois_dernier

/*
Exercice 26
On reste sur l'analyse temporelle mais on change d'angle — on s'intéresse aux catégories de produits.
Objectif : Pour chaque catégorie de produit, calcule le chiffre d'affaires mensuel et identifie le mois record (CA le plus élevé) pour chaque catégorie.
Colonnes attendues :

categorie (en anglais, via category_translation)
mois
ca_mensuel
est_record (booléen ou 1/0 — vaut 1 si c'est le mois avec le CA le plus élevé pour cette catégorie)

Contraintes :

Ignore les produits sans catégorie
Ignore les catégories sans traduction anglaise

*/

WITH payments_agg AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
), cte_data_basis AS
(
	SELECT  date_trunc('month',o.order_purchase_timestamp) AS mois_achat
	       ,ct.product_category_name_english               AS categorie_anglais
	       ,p.product_id                                   AS product_id
	       ,o.order_id                                     AS order_id
	       ,pa.montant_ca                                  AS ca
	FROM products p
	INNER JOIN category_translation ct
	ON p.product_category_name = ct.product_category_name
	INNER JOIN order_items oi
	ON p.product_id = oi.product_id
	INNER JOIN orders o
	ON oi.order_id = o.order_id
	INNER JOIN payments_agg pa
	ON pa.order_id = o.order_id
), mtn_par_categorie AS
(
	SELECT  mois_achat
	       ,categorie_anglais
	       ,SUM(ca) AS montant
	FROM cte_data_basis
	GROUP BY  1
	         ,2
	ORDER BY  1
	         ,2
), rang AS
(
	SELECT  *
	       ,rank()over(PARTITION BY categorie_anglais ORDER BY  montant DESC) AS est_record
	FROM mtn_par_categorie
)
SELECT  mois_achat
       ,categorie_anglais
       ,montant
       ,CASE WHEN est_record = 1 THEN 1  ELSE 0 END AS test
FROM rang

/*
Variante du rank() pour l'exo 26 avec un boolean + cast directement sur la fonction window rank.
Morceau de code à changer dans la query globale
*/

SELECT  *
       ,rank()over(PARTITION BY categorie_anglais ORDER BY  montant DESC) AS est_record
FROM mtn_par_categorie

/*
Exercice 27
On introduit un nouveau concept : les sous-totaux et totaux avec ROLLUP.
Objectif : Calcule le chiffre d'affaires par état (customer_state) et par mois, avec une ligne de sous-total par état et une ligne de total général.
Colonnes attendues :

state (NULL pour le total général)
mois (NULL pour les sous-totaux par état et le total général)
ca

Contraintes :

Utilise GROUP BY ROLLUP
Joins les tables nécessaires pour relier les clients, commandes et paiements
syntaxe de group by roll up : group by rollup (a,b)
*/
WITH payments_agg AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
), table_agg AS
(
	SELECT  c.customer_state                               AS province
	       ,date_trunc('month',o.order_purchase_timestamp) AS mois
	       ,pa.montant_ca                                  AS montant
	FROM customers c
	INNER JOIN orders o
	ON c.customer_id = o.customer_id
	INNER JOIN payments_agg pa
	ON o.order_id = pa.order_id
)
SELECT  province
       ,mois
       ,SUM(montant) AS ca
FROM table_agg
GROUP BY  rollup(province,mois)

/*
Exercice 28
On reste sur les agrégations avancées avec un nouveau concept : GROUPING SETS.
Objectif : Calcule le chiffre d'affaires selon trois axes indépendants en une seule requête :

Par état (customer_state)
Par mois
Total général

Colonnes attendues :

state
mois
ca
*/
WITH payments_agg AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
), table_agg AS
(
	SELECT  c.customer_state                               AS province
	       ,date_trunc('month',o.order_purchase_timestamp) AS mois
	       ,pa.montant_ca                                  AS montant
	FROM customers c
	INNER JOIN orders o
	ON c.customer_id = o.customer_id
	INNER JOIN payments_agg pa
	ON o.order_id = pa.order_id
)
SELECT  province
       ,mois
       ,SUM(montant) AS ca
FROM table_agg
GROUP BY
GROUPING SETS( (province), (mois), () )
ORDER BY 1, 2
-- Pas besoin de mettre 3 dans le order by, les valeurs nulls arrivent en dernier avec PostgreSQL 

/*
Exercice 29
On introduit un nouveau concept : les vues (VIEW).
Objectif : Crée une vue appelée vue_ca_mensuel_vendeur qui encapsule le calcul du CA mensuel par vendeur (ce que tu as fait en exercice 25, sans le LAG et la variation).
Ensuite, utilise cette vue dans une requête séparée pour afficher uniquement les vendeurs dont le CA mensuel dépasse 10 000€ sur au moins un mois.
Ce qu'est une vue :
Une vue est une requête sauvegardée dans la base de données sous forme d'objet réutilisable. Tu peux l'interroger comme une table normale avec SELECT * FROM ma_vue.
*/

CREATE view vue_ca_mensuel_vendeur AS (
WITH payments_agg AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
)
SELECT  s.seller_id                                     AS vendeur
       ,date_trunc('month',o.order_purchase_timestamp ) AS mois
       ,SUM(pa.montant_ca)                              AS montant
FROM sellers s
INNER JOIN order_items oi
ON s.seller_id = oi.seller_id
INNER JOIN orders o
ON oi.order_id = o.order_id
INNER JOIN payments_agg pa
ON o.order_id = pa.order_id
GROUP BY  1
         ,2 ORDER BY  1 )
SELECT  *
FROM vue_ca_mensuel_vendeur
WHERE montant > 10000

/*
Exercice 30 — Moyenne mobile sur 3 mois
Calcule, par seller, le chiffre d'affaires mensuel ainsi qu'une moyenne mobile sur 3 mois glissants (mois courant + 2 mois précédents).
Tables utiles : order_items, orders

Filtre : ne garde que les sellers ayant au moins 5 mois d'activité

Trie : par seller_id, puis par mois croissant
*/

WITH cte_payment AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
), cte_data_basis AS
(
	SELECT  s.seller_id                                    AS vendeur
	       ,date_trunc('month',o.order_purchase_timestamp) AS mois
	       ,cp.montant_ca
	FROM sellers s
	INNER JOIN order_items oi
	ON s.seller_id = oi.seller_id
	INNER JOIN orders o
	ON oi.order_id = o.order_id
	INNER JOIN cte_payment cp
	ON o.order_id = cp.order_id
), cte_grouping AS
(
	SELECT  vendeur
	       ,mois
	       ,SUM(montant_ca) AS ca_mensuel
	FROM cte_data_basis
	GROUP BY  1
	         ,2
), cte_moyenne_mob AS
(
	SELECT  *
	       ,round(AVG(ca_mensuel) over(PARTITION BY vendeur ORDER BY  mois rows BETWEEN 2 preceding AND current row)) AS moyenne_mobile
	FROM cte_grouping
)
SELECT  vendeur
       ,mois
       ,ca_mensuel
       ,moyenne_mobile
FROM cte_moyenne_mob
WHERE vendeur IN ( SELECT vendeur FROM cte_grouping GROUP BY 1 HAVING COUNT(distinct mois) >= 5)
ORDER BY vendeur 

/*
Exercice 31 — ROWS BETWEEN : cumul avec remise à zéro
Toujours sur le même thème des window frames, mais on pousse un cran plus loin.
Calcule, par seller et par année, le CA cumulé depuis le début de l'année (un cumul qui repart à zéro chaque 1er janvier).
Colonnes attendues :

seller_id
annee
mois
ca_mensuel
ca_cumule_ytd (Year To Date)

Tables : order_items, orders, order_payments

Filtre : même que l'exercice précédent — sellers avec au moins 5 mois d'activité

Tri : par seller_id, annee, mois
*/

WITH cte_payment AS
(
	SELECT  order_id
	       ,SUM(payment_value) AS montant_ca
	FROM order_payments op
	GROUP BY  1
	ORDER BY  1
), cte_data_basis AS
(
	SELECT  s.seller_id                                    AS vendeur
	       ,date_trunc('month',o.order_purchase_timestamp) AS mois
	       ,cp.montant_ca
	FROM sellers s
	INNER JOIN order_items oi
	ON s.seller_id = oi.seller_id
	INNER JOIN orders o
	ON oi.order_id = o.order_id
	INNER JOIN cte_payment cp
	ON o.order_id = cp.order_id
), cte_grouping AS
(
	SELECT  vendeur
	       ,mois
	       ,SUM(montant_ca) AS ca_mensuel
	FROM cte_data_basis
	GROUP BY  1
	         ,2
), cte_moyenne_mob AS
(
	SELECT  *
	       ,round(AVG(ca_mensuel) over(PARTITION BY vendeur ORDER BY  mois rows BETWEEN 2 preceding AND current row)) AS moyenne_mobile
	FROM cte_grouping
)
SELECT  vendeur
       ,mois
       ,ca_mensuel
       ,moyenne_mobile
FROM cte_moyenne_mob
WHERE vendeur IN ( SELECT vendeur FROM cte_grouping GROUP BY 1 HAVING COUNT(distinct mois) >= 5)
ORDER BY vendeur

/*
Exercice 32 : Les dates
Calcule, pour chaque commande, le délai de livraison en jours entre la date d'achat et la date de livraison effective. Puis donne :

Le délai moyen de livraison par état brésilien (customer_state)
Le délai maximum
Le délai minimum
Le nombre de commandes

Filtre : uniquement les commandes avec un statut delivered

Tri : par délai moyen décroissant
Tables : orders, customers
*/

WITH cte_data_found AS
(
	SELECT  c.customer_state                AS province
	       ,o.order_id                      AS commande
	       ,o.order_purchase_timestamp      AS date_dachat
	       ,o.order_delivered_customer_date AS date_livraison
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	WHERE o.order_delivered_customer_date is not null
	AND o.order_status = 'delivered' 
), cte_livraison AS
(
	SELECT  province
	       ,commande
	       ,(date_livraison::date - date_dachat::date) AS delai_livraison
	FROM cte_data_found
)
SELECT  province
       ,COUNT(distinct commande)    AS nbr_commandes
       ,round(AVG(delai_livraison)) AS delai_moyen
       ,MIN(delai_livraison)        AS delai_min
       ,MAX(delai_livraison)        AS delai_max
FROM cte_livraison
GROUP BY  cte_livraison.province
ORDER BY  3 desc

/*
Exercice 33 — Dates : délai estimé vs réel
On reste sur les dates mais on pousse un peu plus loin.
Calcule, pour chaque commande livrée, l'écart entre la date de livraison estimée et la date de livraison réelle en jours. Un écart négatif signifie que la commande est arrivée en avance, positif qu'elle est arrivée en retard.
Puis agrège par état (customer_state) :

Nombre de commandes
Nombre de commandes en retard
Nombre de commandes en avance
Taux de commandes en retard (en %)
Écart moyen en jours (arrondi)

Tables : orders, customers

Filtre : commandes delivered uniquement

Tri : par taux de retard décroissant
*/

WITH cte_basis AS
(
	SELECT  c.customer_state                AS etat
	       ,o.order_id                      AS commande
	       ,o.order_estimated_delivery_date AS date_livraison_est
	       ,o.order_delivered_customer_date AS date_livraison
	FROM orders o
	INNER JOIN customers c
	ON o.customer_id = c.customer_id
	WHERE order_status = 'delivered' 
), cpt_jours_livraison AS
(
	SELECT  etat
	       ,commande
	       ,(date_livraison:: date - date_livraison_est::date) AS jours_livraison
	FROM cte_basis
)
SELECT  etat
       ,COUNT(distinct commande)                                                                              AS nbr_commandes
       ,SUM(case WHEN jours_livraison < 0 THEN 1 else 0 end)                                                  AS nbr_commandes_en_avance
       ,SUM(case WHEN jours_livraison > 0 THEN 1 else 0 end)                                                  AS nbr_commandes_en_retard
       ,round((SUM(case WHEN jours_livraison > 0 THEN 1 else 0 end)::float / COUNT(distinct commande)) * 100) AS pct_commandes_retard
       ,round(AVG(jours_livraison ))                                                                          AS ecart_moyen
FROM cpt_jours_livraison
GROUP BY  1
ORDER BY  pct_commandes_retard desc

/*
Exercice 34 — Nested subqueries
On change de sujet : les sous-requêtes imbriquées. Tu en as déjà utilisé une dans le WHERE ... IN (SELECT ...), mais on va aller plus loin.
Une sous-requête peut apparaître à trois endroits :

Dans le WHERE — tu connais déjà
Dans le FROM — comme une table temporaire inline
Dans le SELECT — pour calculer une valeur scalaire

Exercice :
Sans utiliser de CTE, trouve les produits dont le prix unitaire moyen est supérieur à la moyenne globale de tous les produits.
Colonnes attendues :

product_id
prix_moyen (prix moyen du produit, arrondi)
moyenne_globale (la moyenne globale, arrondie — même valeur sur toutes les lignes)

Table : order_items

Tri : par prix_moyen décroissant
*/

SELECT  product_id
       ,round(AVG(price)) AS prix_moyen
       ,(
SELECT  round(AVG(price))
FROM order_items oi) AS prix_moyen_global
FROM order_items oi
GROUP BY  1
HAVING round(AVG(price)) > (
SELECT  round(AVG(price))
FROM order_items oi)
ORDER BY 2 desc

/*
Exercice 35 — Sous-requête dans le FROM
Cette fois on utilise une sous-requête directement dans le FROM comme une table temporaire inline, sans CTE.
Exercice :
Trouve les sellers dont le CA total est supérieur à la médiane des CA de tous les sellers.
Colonnes attendues :

seller_id
ca_total (arrondi)
mediane_ca (la médiane globale, arrondie — même valeur sur toutes les lignes)

Table : order_items

Tri : par ca_total décroissant
Indice : La médiane en PostgreSQL se calcule avec PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY valeur).
*/

SELECT  seller_id     AS vendeur
       ,SUM(oi.price) AS ca
       ,(
SELECT  PERCENTILE_CONT(0.5) within group(order by ca) AS mediane
FROM
(
	SELECT  seller_id
	       ,SUM(oi.price) AS ca
	FROM order_items oi
	GROUP BY  1
) AS table_mediane) AS mediane_ca
FROM order_items oi
GROUP BY  1
HAVING SUM(oi.price) > (
SELECT  PERCENTILE_CONT(0.5) within group(order by ca) AS mediane
FROM
(
	SELECT  seller_id
	       ,SUM(oi.price) AS ca
	FROM order_items oi
	GROUP BY  1
) AS table_mediane)
ORDER BY ca desc

-- version avec la cte

WITH ca_agg AS
(
	SELECT  seller_id
	       ,SUM(oi.price) AS ca
	FROM order_items oi
	GROUP BY  1
), cte_mediane AS
(
	SELECT  PERCENTILE_CONT(0.5) within group(order by ca) AS mediane
	FROM ca_agg
)
SELECT  seller_id
       ,ca
       ,mediane
FROM ca_agg
CROSS JOIN cte_mediane
WHERE ca > mediane
ORDER BY ca desc