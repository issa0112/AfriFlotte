"""Validation et normalisation des numéros de téléphone selon le plan de
numérotation de chaque pays CEDEAO.

Miroir Flutter : afriflotte_app/lib/utils/telephone.dart — toute modification
ici (nouveau pays, correction de longueur/préfixe...) doit être reportée
là-bas à la main, même absence d'outillage commun que constants.py.

Un numéro est toujours stocké en E.164 (`indicatif + numéro national`, sans
zéro initial, sans espace). La validation par pays (longueur + préfixes
valides) ne peut se faire que côté serializer, là où `pays` est connu — ce
module ne fait qu'exposer l'algorithme, indépendant de Django.
"""

import re

from django.db.models import Q

from .constants import INDICATIF_PAR_PAYS, NOM_PAR_PAYS

# Pour chaque pays : longueur du numéro national significatif (après
# l'indicatif, sans zéro initial) et préfixes valides pour ce numéro. Les
# préfixes peuvent faire 1 ou 2 chiffres selon le pays (ex. Mali : un seul
# chiffre 6/7 ; Togo : des blocs à 2 chiffres) — un numéro est valide s'il a
# la bonne longueur ET commence par un des préfixes listés.
#
# Source : plans de numérotation par pays (Wikipedia "Telephone numbers in
# <pays>", recoupé ITU), recherchés le 2026-09-01. Bénin et Côte d'Ivoire ont
# eu une réforme récente (10 chiffres) : ne pas revenir à 8 sans vérifier.
# Nigeria/Gambie/Liberia/Sierra Leone : préfixes larges par chiffre de tête
# plutôt qu'une liste exhaustive de blocs à 3 chiffres (marché trop mouvant,
# portabilité du numéro depuis 2013 pour le Nigeria notamment) — mieux vaut
# un contrôle un peu large qu'un rejet à tort d'un numéro réel.
REGLES_NUMEROTATION = {
    "BJ": {"longueur": 10, "prefixes": ("01",)},
    "BF": {"longueur": 8, "prefixes": ("6", "7")},
    "CV": {"longueur": 7, "prefixes": ("9",)},
    "CI": {"longueur": 10, "prefixes": ("01", "05", "07")},
    "GM": {"longueur": 7, "prefixes": ("2", "3", "4", "5", "6", "9")},
    "GH": {
        "longueur": 9,
        "prefixes": (
            "20", "23", "24", "25", "26", "27", "28",
            "50", "53", "54", "55", "56", "57", "59",
        ),
    },
    "GN": {"longueur": 9, "prefixes": ("6",)},
    "GW": {"longueur": 9, "prefixes": ("9",)},
    "LR": {"longueur": 9, "prefixes": ("5", "7", "8")},
    "ML": {"longueur": 8, "prefixes": ("6", "7")},
    "NE": {"longueur": 8, "prefixes": ("8", "9")},
    "NG": {"longueur": 10, "prefixes": ("7", "8", "9")},
    "SN": {"longueur": 9, "prefixes": ("7",)},
    "SL": {"longueur": 8, "prefixes": ("2", "3", "4", "6", "7", "8")},
    "TG": {
        "longueur": 8,
        "prefixes": (
            "70", "71", "72", "73", "78", "79",
            "90", "91", "92", "93", "96", "97", "98", "99",
        ),
    },
}

# Pays où l'usage domestique courant compose le numéro avec un zéro initial
# (ex. Ghana "0244123456") — sert uniquement à décider si `formater_local`
# doit réinsérer ce zéro pour l'affichage. Bénin/Côte d'Ivoire ont déjà leur
# "01"/"0x" comme partie fixe du numéro national, donc ils n'en ont pas
# besoin ici. La validation elle-même (`valider_et_normaliser`) n'a pas
# besoin de cette liste : elle essaie le numéro tel quel puis sans son
# premier zéro, et retient celui qui correspond au plan du pays.
PAYS_AVEC_ZERO_LOCAL = {"GH", "NG", "SL"}

_CARACTERES_A_IGNORER = re.compile(r"[\s\-().]")
_NON_CHIFFRE = re.compile(r"\D")


class TelephoneInvalide(ValueError):
    """Le numéro fourni ne correspond pas au plan de numérotation du pays."""


def _regle_pour_pays(code_pays):
    regle = REGLES_NUMEROTATION.get(code_pays)
    if regle is None:
        raise TelephoneInvalide(f"Pays inconnu pour la validation du téléphone : {code_pays}")
    return regle


def _correspond(numero_national, regle):
    return (
        len(numero_national) == regle["longueur"]
        and numero_national.startswith(regle["prefixes"])
    )


def valider_et_normaliser(code_pays, telephone_brut):
    """Valide `telephone_brut` (numéro local seul, ou déjà préfixé de
    l'indicatif) pour le plan de numérotation de `code_pays`, et renvoie la
    forme E.164 normalisée (`indicatif + numéro national`, sans zéro initial
    ni espace).

    Lève `TelephoneInvalide` si le numéro ne correspond à aucune forme valide
    (ni tel quel, ni sans son premier zéro) pour ce pays.
    """
    indicatif = INDICATIF_PAR_PAYS.get(code_pays)
    if indicatif is None:
        raise TelephoneInvalide(f"Pays inconnu pour la validation du téléphone : {code_pays}")

    regle = _regle_pour_pays(code_pays)

    brut = _CARACTERES_A_IGNORER.sub("", (telephone_brut or "").strip())

    # Tolère un numéro déjà composé (indicatif+local) ou seulement local :
    # dans les deux cas on retombe sur le numéro local brut ci-dessous.
    if brut.startswith(indicatif):
        brut = brut[len(indicatif):]
    elif brut.startswith(indicatif.lstrip("+")):
        brut = brut[len(indicatif) - 1:]

    numero = _NON_CHIFFRE.sub("", brut)

    candidats = [numero]
    if numero.startswith("0") and len(numero) > 1:
        candidats.append(numero[1:])

    for candidat in candidats:
        if _correspond(candidat, regle):
            return f"{indicatif}{candidat}"

    nom = NOM_PAR_PAYS.get(code_pays, code_pays)
    prefixes_lisibles = "/".join(regle["prefixes"])
    raise TelephoneInvalide(
        f"Numéro invalide pour {nom} : {regle['longueur']} chiffres attendus "
        f"après l'indicatif {indicatif} (préfixe valide : {prefixes_lisibles})."
    )


def candidats_suffixe_telephone(telephone_saisi):
    """`Q` object pour retrouver un compte à partir du seul numéro local
    saisi à la connexion (sans indicatif) : le numéro stocké est en E.164
    (indicatif+local), donc on cherche par suffixe plutôt que par égalité.
    Tente aussi la variante sans le premier zéro, au cas où l'utilisateur
    compose son numéro comme il le ferait en local (ex. Ghana
    "0244123456"). Renvoie `None` si `telephone_saisi` ne contient aucun
    chiffre (rien à chercher)."""
    chiffres = _NON_CHIFFRE.sub("", telephone_saisi or "")
    if not chiffres:
        return None

    candidats = {chiffres}
    if chiffres.startswith("0") and len(chiffres) > 1:
        candidats.add(chiffres[1:])

    q = Q()
    for candidat in candidats:
        q |= Q(telephone__endswith=candidat)
    return q


def formater_local(telephone_e164, code_pays):
    """Numéro en format d'affichage local : indicatif retiré, zéro
    domestique ré-ajouté pour les pays qui l'utilisent en usage courant
    (`PAYS_AVEC_ZERO_LOCAL`). Renvoie `telephone_e164` tel quel si le pays
    est inconnu ou si le numéro ne commence pas par son indicatif (donnée pas
    encore migrée au format international) — un numéro doit toujours
    afficher quelque chose, même dégradé."""
    if not telephone_e164:
        return telephone_e164

    indicatif = INDICATIF_PAR_PAYS.get(code_pays)
    if not indicatif or not telephone_e164.startswith(indicatif):
        return telephone_e164

    local = telephone_e164[len(indicatif):]
    if code_pays in PAYS_AVEC_ZERO_LOCAL:
        local = f"0{local}"
    return local
