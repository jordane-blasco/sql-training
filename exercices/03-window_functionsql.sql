/* Exercice 1 — Remise en jambes (JOIN + agrégat) Affiche le nom de chaque client avec le nombre de commandes qu'il a passées et le montant total de ses commandes. Trie par montant total décroissant. */
SELECT  c.nom            AS nom_client
       ,COUNT(cmd.id)    AS nbr_commandes
       ,SUM(cmd.montant) AS montant_total
FROM clients c
INNER JOIN commandes cmd
ON c.id = cmd.client_id
GROUP BY  1
ORDER BY  3 desc; /*Exercice 2 —
HAVING + filtre Même logique, mais cette fois affiche uniquement les clients qui ont passé plus d'une commande et dont le montant total dépasse 500.*/
SELECT  c.nom            AS nom_client
       ,COUNT(cmd.id)    AS nbr_commandes
       ,SUM(cmd.montant) AS montant_total
FROM clients c
INNER JOIN commandes cmd
ON c.id = cmd.client_id
GROUP BY  c.nom
HAVING COUNT(cmd.id) > 1 AND SUM(cmd.montant) > 500
ORDER BY montant_total desc; /* Exercice 3 — Window function
ON monte d'un cran. Affiche toutes les commandes avec : le nom du client la date_commande le montant de la commande le total cumulé du montant des commandes par client, dans l'ordre chronologique */
SELECT  c.nom
       ,cmd.date_commande
       ,cmd.montant
       ,SUM(cmd.montant) over(PARTITION BY c.nom ORDER BY  cmd.date_commande ASC) AS total_cumule
FROM clients c
INNER JOIN commandes cmd
ON c.id = cmd.client_id; /* Exercice 4 — Window function + rang Affiche pour chaque commande : le nom du client la date_commande le montant le rang de cette commande parmi toutes les commandes du client, du montant le plus élevé au plus bas */
WITH cteTest AS
(
	SELECT  c.nom
	       ,cmd.date_commande
	       ,cmd.montant
	       ,rank() over(PARTITION BY c.nom ORDER BY  cmd.montant DESC) AS total_cumule
	FROM clients c
	INNER JOIN commandes cmd
	ON c.id = cmd.client_id
)
SELECT  *
FROM cteTest
WHERE total_cumule = 1;
-- ou deuxième solution 
SELECT  *
FROM
(
	SELECT  c.nom
	       ,cmd.date_commande
	       ,cmd.montant
	       ,rank() over(PARTITION BY c.nom ORDER BY  cmd.montant DESC) AS rang
	FROM clients c
	INNER JOIN commandes cmd
	ON c.id = cmd.client_id
) AS sous_requête
WHERE rang = 1 /* Exercice 5 — CTEs chaînées Écris une requête avec deux CTEs chaînées : CTE 1 : calcule pour chaque client son nombre de commandes et son montant total CTE 2 : à partir de la CTE 1, garde uniquement les clients dont le montant total est supérieur à la moyenne de tous les montants totaux Affiche le nom du client, son nombre de commandes et son montant total, trié par montant total décroissant. */ 
WITH cte1 AS
(
	SELECT  c.nom            AS clients
	       ,COUNT(cmd.id)    AS nombre_commandes
	       ,SUM(cmd.montant) AS montant_total
	FROM clients c
	INNER JOIN commandes cmd
	ON c.id = cmd.client_id
	GROUP BY  c.nom
), cte2 as(
SELECT  cte1.clients
       ,cte1.nombre_commandes
       ,cte1.montant_total
FROM cte1
WHERE cte1.montant_total > (
SELECT  AVG(montant_total )
FROM cte1) )
SELECT  *
FROM cte2
ORDER BY clients
;

/* Exercice 6 — CTE + Window function combinées
ON monte encore d'un cran. Écris une requête qui affiche pour chaque produit : le produit_nom le chiffre d'affaires total de ce produit (quantite * prix_unitaire sommé sur toutes les commandes) sa part en pourcentage du chiffre d'affaires total de tous les produits (arrondi à 2 décimales) Trié par chiffre d'affaires décroissant. */
WITH cte1 AS
(
	SELECT  pc.produit_nom
	       ,pc.commande_id
	       ,pc.quantite * pc.prix_unitaire AS CA
	FROM produits_commande pc
), cte2 AS
(
	SELECT  produit_nom
	       ,SUM(CA) AS ca_total
	FROM cte1
	GROUP BY  cte1.produit_nom
)
SELECT  *
       ,round(cte2.ca_total / SUM(cte2.ca_total) over(),2) * 100 AS pourcentage
FROM cte2
ORDER BY cte2.produit_nom