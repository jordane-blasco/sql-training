CREATE TABLE departements (
    id          SERIAL PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL,
    localisation VARCHAR(100)
);

CREATE TABLE employes (
    id              SERIAL PRIMARY KEY,
    prenom          VARCHAR(50) NOT NULL,
    nom             VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    salaire         DECIMAL(10,2),
    date_embauche   DATE,
    departement_id  INT REFERENCES departements(id)
);

CREATE TABLE projets (
    id              SERIAL PRIMARY KEY,
    nom             VARCHAR(100) NOT NULL,
    budget          DECIMAL(12,2),
    date_debut      DATE,
    date_fin        DATE,
    departement_id  INT REFERENCES departements(id)
);

INSERT INTO departements (nom, localisation) VALUES
('Informatique', 'Paris'),
('Comptabilité', 'Lyon'),
('Marketing', 'Bordeaux'),
('RH', 'Marseille');

INSERT INTO employes (prenom, nom, email, salaire, date_embauche, departement_id) VALUES
('Alice', 'Martin', 'alice.martin@entreprise.fr', 3500, '2019-03-15', 1),
('Bob', 'Dupont', 'bob.dupont@entreprise.fr', 2800, '2020-07-01', 2),
('Clara', 'Leroy', 'clara.leroy@entreprise.fr', 4200, '2018-11-20', 1),
('David', 'Moreau', 'david.moreau@entreprise.fr', 3100, '2021-01-10', 3),
('Emma', 'Simon', 'emma.simon@entreprise.fr', 2600, '2022-05-23', 4),
('François', 'Laurent', 'francois.laurent@entreprise.fr', 5000, '2017-09-01', 1),
('Giulia', 'Bernard', 'giulia.bernard@entreprise.fr', 3800, '2020-02-14', 3),
('Hugo', 'Petit', 'hugo.petit@entreprise.fr', 2900, '2023-01-05', 2);

INSERT INTO projets (nom, budget, date_debut, date_fin, departement_id) VALUES
('Refonte site web', 50000, '2024-01-01', '2024-06-30', 1),
('Audit comptable', 20000, '2024-03-01', '2024-04-30', 2),
('Campagne réseaux sociaux', 35000, '2024-02-01', '2024-12-31', 3),
('Recrutement 2024', 15000, '2024-01-15', '2024-09-30', 4);