CREATE table if not exists clients (
    id INT PRIMARY KEY,
    nom VARCHAR(100),
    email VARCHAR(100)
);

-- Table COMMANDES
CREATE TABLE if not exists commandes (
    id INT PRIMARY KEY,
    client_id INT,
    date_commande DATE,
    montant DECIMAL(10, 2),
    FOREIGN KEY (client_id) REFERENCES clients(id)
);

-- Table PRODUITS_COMMANDE
CREATE TABLE if not exists produits_commande (
    id INT PRIMARY KEY,
    commande_id INT,
    produit_nom VARCHAR(100),
    quantite INT,
    prix_unitaire DECIMAL(10, 2),
    FOREIGN KEY (commande_id) REFERENCES commandes(id)
);

INSERT INTO clients VALUES (1, 'Alice Dupont', 'alice@example.com');
INSERT INTO clients VALUES (2, 'Bob Martin', 'bob@example.com');
INSERT INTO clients VALUES (3, 'Claire Leblanc', 'claire@example.com');

INSERT INTO commandes VALUES (101, 1, '2025-01-15', 250.00);
INSERT INTO commandes VALUES (102, 1, '2025-02-10', 180.50);
INSERT INTO commandes VALUES (103, 2, '2025-01-20', 320.75);
INSERT INTO commandes VALUES (104, 3, '2025-02-05', 95.25);

INSERT INTO produits_commande VALUES (1, 101, 'Laptop', 1, 800.00);
INSERT INTO produits_commande VALUES (2, 101, 'Souris', 2, 25.00);
INSERT INTO produits_commande VALUES (3, 102, 'Clavier', 1, 150.00);
INSERT INTO produits_commande VALUES (4, 103, 'Moniteur', 2, 160.00);
INSERT INTO produits_commande VALUES (5, 104, 'Câble USB', 5, 19.00);

select cl.nom,
cd.id,
pc.produit_nom,
pc.quantite,
pc.quantite * pc.prix_unitaire as prix_total
from clients cl
inner join commandes cd on cl.id = cd.client_id
inner join produits_commande pc on cd.id = pc.commande_id


select cl.nom,

from clients cl
inner join commandes cd on cl.id = cd.client_id
inner join produits_commande pc on cd.id = pc.commande_id
group by cl.nom;

select
cl.id as client_id,
cl.nom,
count(distinct cd.id) as cmd,
count(distinct pc.produit_nom) as produit_distinct,
sum(cd.montant) as montant_total
from clients cl
inner join commandes cd on cl.id = cd.client_id
inner join produits_commande pc on cd.id = pc.commande_id
group by 1,2

-- Requête avec la sous-requête dans le Select
select 
	cl.id,
	sum(cm.montant) as montant_total,
	(select avg(montant) from commandes) as montant_moyen,
	sum(cm.montant) - (select avg(montant) from commandes) as difference
from clients cl
inner join commandes cm on cl.id = cm.client_id
group by cl.id


-- Requête avec la sous-requete dans le from
select 
	cl.id,
from clients cl
inner join commandes cm on cl.id = cm.client_id
group by cl.id


-- Utilisation du cross join afin d'établir un produit cartésien.
-- Cela signifie que la colonne batie par le cross join verra sa valeur attribuée à chaque ligne.
select 
	cl.id,
	round(moyenne.montant_moyen) as avg_amount,
	sum(cm.montant) as montant_total,
	sum(cm.montant) - (select avg(montant) from commandes) as difference
from clients cl
inner join commandes cm on cl.id = cm.client_id
cross join (select avg(montant) as montant_moyen from commandes) as moyenne
group by 1,2;

-- Modèle de sous-requête corrélée.
-- Tout se joue au niveau du where à l'intérieur de la sous-requête
-- Par convention on met la colonne de la table référencée (dans le where) en premier.
select
cl.id,
(select max(montant) from commandes where client_id = cl.id) as max_com_mont,
(select min(montant) from commandes where client_id = cl.id) as min_com_mont
from clients cl;

-- Utilisation d'un union pour fusionner les deux tables client et produit_commandes
-- par leurs colonnes de nom clients et nom produit.
-- l'union se met entre les deux tables. (un union all prend également en compte les doublons)

select c.nom,
'Client' as type
from clients c 
union
select pc.produit_nom,
'Produit' as type
from produits_commande pc
order by 1;

-- Window function : permet au contraire du groupe by de conserver toutes les lignes et d'ajouter une nouvelle colonne
-- Exemple ci-dessous : on peut voir le cumul dans la colonne "total"
-- Syntaxe de la WF : fonction agg over(partition by .... order by ....) as 
-- Row_number() permet d'attribuer un numéro de ligne. Syntaxe : row_number () over(order by)
-- elle existe aussi avec partition : row_number() over(partition by ... order by ...). Rang par la colonne partitionnée

select
c.nom,
c2.montant,
c2.date_commande,
sum(montant) over(partition by c.nom order by c2.date_commande) as total_montant,
row_number() over(partition by c.nom order by c2.date_commande) as rank
from clients c 
inner join commandes c2 on c.id = c2.client_id 