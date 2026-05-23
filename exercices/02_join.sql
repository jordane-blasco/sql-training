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

select
cl.nom,
count(distinct cd.id) as cmd,
sum(cd.montant) as montant_total
from clients cl
inner join commandes cd on cl.id = cd.client_id
inner join produits_commande pc on cd.id = pc.commande_id
group by 1
having sum(cd.montant) > 200 and count(distinct cd.id) >= 2