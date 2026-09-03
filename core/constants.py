"""Référentiel partagé pour le périmètre sous-régional CEDEAO.

Miroir Flutter : afriflotte_app/lib/constants/pays_cedeao.dart — toute
modification ici (ajout de pays, correction de devise/indicatif...) doit être
reportée là-bas à la main, aucun outillage de génération commune n'existe.
"""

# (code ISO 3166-1 alpha-2, nom affiché, code devise ISO 4217, indicatif
# téléphonique international)
PAYS_CEDEAO = (
    ("BJ", "Bénin", "XOF", "+229"),
    ("BF", "Burkina Faso", "XOF", "+226"),
    ("CV", "Cap-Vert", "CVE", "+238"),
    ("CI", "Côte d'Ivoire", "XOF", "+225"),
    ("GM", "Gambie", "GMD", "+220"),
    ("GH", "Ghana", "GHS", "+233"),
    ("GN", "Guinée", "GNF", "+224"),
    ("GW", "Guinée-Bissau", "XOF", "+245"),
    ("LR", "Liberia", "LRD", "+231"),
    ("ML", "Mali", "XOF", "+223"),
    ("NE", "Niger", "XOF", "+227"),
    ("NG", "Nigeria", "NGN", "+234"),
    ("SN", "Sénégal", "XOF", "+221"),
    ("SL", "Sierra Leone", "SLE", "+232"),
    ("TG", "Togo", "XOF", "+228"),
)

# Pour `choices=` sur un CharField : Django attend des paires (valeur, libellé).
PAYS_CEDEAO_CHOICES = tuple(
    (code, nom) for code, nom, _devise, _indicatif in PAYS_CEDEAO
)

DEVISE_PAR_PAYS = {
    code: devise for code, _nom, devise, _indicatif in PAYS_CEDEAO
}

NOM_PAR_PAYS = {
    code: nom for code, nom, _devise, _indicatif in PAYS_CEDEAO
}

INDICATIF_PAR_PAYS = {
    code: indicatif for code, _nom, _devise, indicatif in PAYS_CEDEAO
}


def devise_pour_pays(code_pays):
    """Devise ISO 4217 d'un code pays CEDEAO, ou None si le code est inconnu.

    Pas de repli silencieux sur XOF : un code invalide doit remonter comme
    une erreur exploitable plutôt que d'afficher une devise fausse.
    """
    return DEVISE_PAR_PAYS.get(code_pays)


def indicatif_pour_pays(code_pays):
    """Indicatif téléphonique international d'un code pays CEDEAO (ex. '+223'
    pour 'ML'), ou None si le code est inconnu. Même logique stricte que
    `devise_pour_pays` : pas de repli silencieux."""
    return INDICATIF_PAR_PAYS.get(code_pays)


# Centralise les choix de type de camion, jusqu'ici dupliqués indépendamment
# sur Camion.TYPE_CAMION et DemandeTransport.TYPE_CAMION.
TYPE_CAMION_CHOICES = (
    ('CITERNE', 'Camion citerne'),
    ('BENNE', 'Camion benne'),
    ('PLATEAU', 'Camion plateau'),
    ('CONTENEUR', 'Porte-conteneur'),
    ('PORTE_ENGIN', 'Porte-engin'),
)


def unite_capacite_pour_type(type_camion):
    """Unité de capacité cohérente avec le type de camion : seule une
    citerne transporte du liquide (litres), tout le reste (benne, plateau,
    conteneur, porte-engin) se mesure en tonnes. Utilisé par
    CamionSerializer pour empêcher des incohérences comme une benne
    enregistrée en litres."""
    return 'litres' if type_camion == 'CITERNE' else 'tonnes'


# Format/gabarit du camion — précision supplémentaire par rapport au type
# seul (2026-08-27), pour un matching demande<->camion plus fin : deux
# porte-conteneurs peuvent être un "20 pieds" et un "40 pieds", deux
# citernes peuvent être une 20 000L et une 40 000L. Un seul référentiel
# plat (comme TYPE_CAMION_CHOICES) plutôt qu'un champ par type : simplifie
# le modèle (une seule colonne `format_camion`) au prix de valeurs qui ne
# concernent chacune qu'un sous-ensemble de types — c'est `FORMATS_PAR_TYPE`
# ci-dessous qui restreint quelles valeurs sont valides pour quel type.
#
# Classes de citerne fournies directement par l'utilisateur (2026-08-27,
# terrain) — remplace une première liste inventée (5 000/10 000/30 000 L)
# puis une deuxième sourcée par recherche web générique
# (15 000-55 000 L) : les deux étaient moins fiables que la donnée réelle.
FORMAT_CAMION_CHOICES = (
    ('20_PIEDS', '20 pieds'),
    ('40_PIEDS', '40 pieds'),
    ('20_40_PIEDS', '20/40 pieds'),
    ('45_PIEDS', '45 pieds'),
    ('CITERNE_10000L', '10 000 L'),
    ('CITERNE_15000L', '15 000 L'),
    ('CITERNE_20000L', '20 000 L'),
    ('CITERNE_25000L', '25 000 L'),
    ('CITERNE_30000L', '30 000 L'),
    ('CITERNE_35000L', '35 000 L'),
    ('CITERNE_40000L', '40 000 L'),
    ('CITERNE_43000L', '43 000 L'),
    ('CITERNE_45000L', '45 000 L'),
    ('CITERNE_50000L', '50 000 L'),
    # Configuration d'essieux d'une benne (2026-08-27, terrain) : c'est ce
    # qui définit sa capacité dans la région, pas un gabarit en pieds ou en
    # litres. Notation "config essieux — nombre de roues" fournie par
    # l'utilisateur (8×4 = 2 essieux avant simples + 2 essieux arrière
    # jumelés = 12 roues) ; 4×2/6×4 dérivés de la même logique (roues
    # jumelées uniquement sur les essieux moteurs arrière).
    ('BENNE_4X2', '4×2 — 6 roues'),
    ('BENNE_6X4', '6×4 — 10 roues'),
    ('BENNE_8X4', '8×4 — 12 roues'),
    ('AUTRE', 'Autre'),
)

# Formats valides par type de camion. PORTE_ENGIN n'apparaît pas ici : aucun
# format standard demandé pour lui, le champ reste vide/non proposé plutôt
# que d'imposer un "Autre" dont personne n'a besoin.
FORMATS_PAR_TYPE = {
    'PLATEAU': ('20_PIEDS', '40_PIEDS', '20_40_PIEDS', '45_PIEDS', 'AUTRE'),
    'CONTENEUR': ('20_PIEDS', '40_PIEDS', '20_40_PIEDS', '45_PIEDS', 'AUTRE'),
    'CITERNE': (
        'CITERNE_10000L', 'CITERNE_15000L', 'CITERNE_20000L',
        'CITERNE_25000L', 'CITERNE_30000L', 'CITERNE_35000L',
        'CITERNE_40000L', 'CITERNE_43000L', 'CITERNE_45000L',
        'CITERNE_50000L', 'AUTRE',
    ),
    'BENNE': ('BENNE_4X2', 'BENNE_6X4', 'BENNE_8X4', 'AUTRE'),
}


def formats_valides_pour_type(type_camion):
    """Codes `format_camion` valides pour un type donné, ou tuple vide si ce
    type ne supporte pas de format (PORTE_ENGIN ou type inconnu)."""
    return FORMATS_PAR_TYPE.get(type_camion, ())


# Certains formats encodent déjà une valeur numérique qui existe aussi comme
# champ séparé sur Camion (`capacite` pour une citerne, `essieux` pour une
# benne) : sans lien entre les deux, rien n'empêche d'enregistrer
# "CITERNE_43000L" avec `capacite=20000`, ou "BENNE_8X4" avec `essieux=2`.
# Ces tables permettent à CamionSerializer de dériver/imposer la valeur
# numérique cohérente avec le format choisi plutôt que de faire confiance à
# une deuxième saisie manuelle qui peut diverger.
CAPACITE_PAR_FORMAT_CITERNE = {
    'CITERNE_10000L': 10000,
    'CITERNE_15000L': 15000,
    'CITERNE_20000L': 20000,
    'CITERNE_25000L': 25000,
    'CITERNE_30000L': 30000,
    'CITERNE_35000L': 35000,
    'CITERNE_40000L': 40000,
    'CITERNE_43000L': 43000,
    'CITERNE_45000L': 45000,
    'CITERNE_50000L': 50000,
}

ESSIEUX_PAR_FORMAT_BENNE = {
    'BENNE_4X2': 2,
    'BENNE_6X4': 3,
    'BENNE_8X4': 4,
}
