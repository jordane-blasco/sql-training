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
         ,3 ORDER BY  1
         ,2 )
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