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
