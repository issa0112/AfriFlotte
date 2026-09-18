"""Contenu structuré des deux contrats légaux de la plateforme — source
unique utilisée à la fois pour l'aperçu en ligne (JSON, `core/views.py`) et
pour la génération PDF (`core/pdf_contrats.py`), afin que les deux rendus ne
puissent jamais diverger.

Un `bloc` de section est soit un paragraphe (`{"type": "paragraphe", "texte": str}`)
soit une liste à puces (`{"type": "liste", "items": [str, ...]}`) — de quoi
composer n'importe quel article juridique sans dupliquer la mise en forme
entre le rendu Flutter et le rendu PDF.

Identité de l'entreprise et siège centralisés ici : à ajuster une fois les
informations légales définitives connues (RCCM, adresse exacte du siège),
sans toucher au reste du contenu.
"""

from django.conf import settings

RAISON_SOCIALE = "AfriFlotte"
SIEGE_SOCIAL = "Bamako, République du Mali"
CONTACT_SUPPORT = "support@afriflotte.com"

# Version = date de dernière modification du texte. La faire évoluer force
# une ré-acceptation du contrat transporteur (cf. `accepter_contrat_transporteur`
# dans core/views.py, qui compare à `User.contrat_transporteur_version_acceptee`).
CONTRAT_PAIEMENT_VERSION = "2026-09-18"
CONTRAT_TRANSPORTEUR_VERSION = "2026-09-18"


def _p(texte):
    return {"type": "paragraphe", "texte": texte}


def _liste(items):
    return {"type": "liste", "items": list(items)}


def _taux_commission():
    """(seuil, taux_bas, taux_haut) formatés pour insertion directe dans le
    texte — dynamique plutôt qu'en dur, pour ne jamais désynchroniser le
    contrat de `settings.COMMISSION_AFRIFLOTTE_*` (core/services.py)."""
    seuil = settings.COMMISSION_AFRIFLOTTE_SEUIL
    taux_bas = settings.COMMISSION_AFRIFLOTTE_TAUX
    taux_haut = settings.COMMISSION_AFRIFLOTTE_TAUX_SUPERIEUR
    seuil_format = f"{seuil:,.0f}".replace(",", " ")
    return seuil_format, taux_bas, taux_haut


def contrat_paiement():
    """Conditions Générales de Paiement — consultables par tout utilisateur,
    sans acceptation explicite requise (document d'information sur le
    fonctionnement du séquestre, pas un contrat d'adhésion)."""
    seuil, taux_bas, taux_haut = _taux_commission()

    sections = [
        {
            "titre": "1. Objet",
            "blocs": [
                _p(
                    f"Les présentes Conditions Générales de Paiement (\"CGP\") "
                    f"décrivent le fonctionnement des paiements effectués sur la "
                    f"plateforme {RAISON_SOCIALE} entre un client (particulier ou "
                    f"entreprise) et un transporteur partenaire, à l'occasion "
                    f"d'une mission de transport de marchandises. Elles "
                    f"s'appliquent à tout paiement initié depuis l'application, "
                    f"quel que soit le pays de l'espace CEDEAO concerné."
                ),
            ],
        },
        {
            "titre": "2. Rôle d'AfriFlotte",
            "blocs": [
                _p(
                    f"{RAISON_SOCIALE} agit exclusivement comme intermédiaire "
                    f"technique de mise en relation et comme tiers de confiance "
                    f"pour la sécurisation des fonds (séquestre). "
                    f"{RAISON_SOCIALE} n'est ni transporteur, ni transitaire, ni "
                    f"partie au contrat de transport lui-même : ce contrat se "
                    f"forme directement entre le client et le transporteur au "
                    f"moment de l'acceptation d'une proposition."
                ),
            ],
        },
        {
            "titre": "3. Modes de paiement acceptés",
            "blocs": [
                _p(
                    "Le client règle le prix convenu d'une mission par l'un des "
                    "moyens suivants :"
                ),
                _liste([
                    "Carte bancaire ou Mobile Money, via le prestataire de "
                    "paiement PayDunya — paiement en ligne intégré à l'application ;",
                    "Paiement manuel (espèces remises en main propre à un agent "
                    f"{RAISON_SOCIALE}), qui délivre un reçu et enregistre "
                    "l'encaissement dans l'application.",
                ]),
                _p(
                    "Le choix du mode de paiement disponible dépend du pays et "
                    "des opérateurs Mobile Money activés sur ce pays au moment de "
                    "la transaction."
                ),
            ],
        },
        {
            "titre": "4. Devise et conversion",
            "blocs": [
                _p(
                    "Le prix d'une mission est affiché et facturé dans la devise "
                    "officielle du pays de départ de la marchandise. Lorsque le "
                    "paiement en ligne est traité par PayDunya — qui ne règle "
                    "qu'en francs CFA (XOF) — et que cette devise n'est pas déjà "
                    "le XOF, le montant est converti en XOF au taux en vigueur au "
                    "moment de la transaction, uniquement pour les besoins de "
                    "l'encaissement technique. Le montant affiché au client et "
                    "au transporteur, ainsi que celui d'un éventuel "
                    "remboursement, reste toujours exprimé dans la devise "
                    "d'origine de la mission."
                ),
            ],
        },
        {
            "titre": "5. Séquestre des fonds",
            "blocs": [
                _p(
                    "Le paiement d'une mission n'est jamais versé directement au "
                    "transporteur. Il transite par un compte de séquestre géré "
                    f"par {RAISON_SOCIALE}, selon les étapes suivantes :"
                ),
                _liste([
                    "En attente — la mission a un prix, le paiement n'a pas "
                    "encore été initié ;",
                    "Encaissé — les fonds ont été reçus (confirmation du "
                    "prestataire de paiement ou de l'agent) ;",
                    "Sécurisé — les fonds sont conservés en séquestre pendant "
                    "l'exécution de la mission ;",
                    "Libéré — la mission est terminée sans litige actif, les "
                    "fonds sont validés pour versement au transporteur ;",
                    "Versé — le virement (Mobile Money ou bancaire) au "
                    "transporteur a été effectué ;",
                    "Remboursé — en cas d'annulation ou de litige résolu en "
                    "faveur du client, tout ou partie des fonds lui est restitué.",
                ]),
            ],
        },
        {
            "titre": "6. Commission de la plateforme",
            "blocs": [
                _p(
                    f"{RAISON_SOCIALE} prélève une commission sur le montant de "
                    f"chaque mission payée, exclusivement à la charge de la part "
                    f"reversée au transporteur — jamais en supplément du prix "
                    f"payé par le client. Le taux appliqué est de {taux_bas} % "
                    f"jusqu'à {seuil} (dans la devise de la mission) inclus, et "
                    f"de {taux_haut} % au-delà de ce seuil. Le taux applicable "
                    "est figé au moment de la création du paiement et ne varie "
                    "plus ensuite, même si le barème change par la suite."
                ),
            ],
        },
        {
            "titre": "7. Libération et versement des fonds",
            "blocs": [
                _p(
                    "Les fonds sécurisés sont libérés automatiquement à la "
                    "clôture de la mission par le transporteur ou son chauffeur, "
                    "à condition qu'aucun litige ne soit ouvert sur ce paiement. "
                    f"Le versement effectif au transporteur est ensuite "
                    f"réalisé par {RAISON_SOCIALE} par virement Mobile Money ou "
                    "bancaire, dans les meilleurs délais suivant la libération. "
                    "Ce versement n'est pas automatisé techniquement : il est "
                    "exécuté manuellement, sans qu'un délai fixe puisse être "
                    "garanti contractuellement, mais dans un objectif de "
                    "diligence raisonnable."
                ),
            ],
        },
        {
            "titre": "8. Remboursement",
            "blocs": [
                _p("Un remboursement au client intervient dans deux cas :"),
                _liste([
                    "annulation d'une mission dont le paiement a déjà été "
                    "encaissé, avant sa clôture ;",
                    "litige résolu en faveur du client (cf. article 9).",
                ]),
                _p(
                    "Pour un paiement par carte, le remboursement est déclenché "
                    "automatiquement auprès du prestataire de paiement lorsque "
                    "celui-ci le permet techniquement. À défaut d'API de "
                    "remboursement disponible chez ce prestataire pour cette "
                    f"transaction, {RAISON_SOCIALE} procède au remboursement "
                    "manuellement, par le même canal que le versement "
                    "transporteur. Un paiement déjà versé au transporteur ne "
                    "peut plus être remboursé par une simple annulation : seule "
                    "l'issue d'un litige peut alors en décider autrement."
                ),
            ],
        },
        {
            "titre": "9. Litiges de paiement",
            "blocs": [
                _p(
                    "Le client ou le transporteur peut ouvrir un litige sur un "
                    "paiement sécurisé ou déjà libéré, en indiquant un motif. "
                    f"Tant qu'un litige est ouvert ou en examen, {RAISON_SOCIALE} "
                    "suspend toute libération ou versement des fonds concernés. "
                    "Le litige est examiné puis tranché par un administrateur de "
                    "la plateforme, avec l'une des issues suivantes : résolution "
                    "en faveur du client (remboursement), résolution en faveur "
                    "du transporteur (libération des fonds) ou rejet du litige."
                ),
            ],
        },
        {
            "titre": "10. Justificatifs et preuves",
            "blocs": [
                _p(
                    "Selon le mode de paiement et l'issue du dossier, "
                    f"{RAISON_SOCIALE} peut conserver et présenter à chaque "
                    "partie les justificatifs suivants : reçu d'espèces, "
                    "signature du client, capture de confirmation du "
                    "prestataire de paiement, justificatif de virement au "
                    "transporteur ou justificatif de remboursement."
                ),
            ],
        },
        {
            "titre": "11. Sécurité des données de paiement",
            "blocs": [
                _p(
                    "Aucun numéro complet de carte bancaire ni cryptogramme "
                    f"visuel ne transite ou n'est stocké par {RAISON_SOCIALE} : "
                    "leur saisie et leur traitement relèvent exclusivement du "
                    "prestataire de paiement. Seules des métadonnées d'affichage "
                    "non sensibles (marque de la carte, quatre derniers "
                    "chiffres, mois/année d'expiration) sont conservées pour "
                    "l'historique du client."
                ),
            ],
        },
        {
            "titre": "12. Limitation de responsabilité",
            "blocs": [
                _p(
                    f"{RAISON_SOCIALE} ne saurait être tenue responsable d'un "
                    "retard ou d'un incident imputable au prestataire de "
                    "paiement, à un opérateur Mobile Money, à une banque, ou à "
                    "une interruption du réseau de télécommunication. En cas "
                    "d'indisponibilité prolongée du prestataire de paiement, "
                    f"{RAISON_SOCIALE} propose au client le mode de paiement "
                    "manuel comme alternative."
                ),
            ],
        },
        {
            "titre": "13. Modification des présentes conditions",
            "blocs": [
                _p(
                    "Les présentes CGP peuvent être mises à jour ; la version en "
                    "vigueur est celle affichée dans l'application au moment du "
                    "paiement, identifiée par sa date de version."
                ),
            ],
        },
        {
            "titre": "14. Droit applicable",
            "blocs": [
                _p(
                    f"Les présentes CGP sont régies par le droit en vigueur au "
                    f"siège social d'{RAISON_SOCIALE} ({SIEGE_SOCIAL}). Tout "
                    "différend est d'abord soumis à la procédure de litige "
                    "interne décrite à l'article 9 ; à défaut de résolution, les "
                    "juridictions compétentes du siège social sont seules "
                    "habilitées à en connaître."
                ),
            ],
        },
        {
            "titre": "15. Contact",
            "blocs": [
                _p(
                    f"Pour toute question relative à un paiement, le support "
                    f"{RAISON_SOCIALE} est joignable à l'adresse "
                    f"{CONTACT_SUPPORT}."
                ),
            ],
        },
    ]

    return {
        "type": "PAIEMENT",
        "titre": "Conditions Générales de Paiement",
        "version": CONTRAT_PAIEMENT_VERSION,
        "sections": sections,
    }


def contrat_transporteur():
    """Contrat de Partenariat Transporteur — acceptation obligatoire à
    l'inscription (cf. `UserSerializer.validate`, core/serializers.py)."""
    seuil, taux_bas, taux_haut = _taux_commission()

    sections = [
        {
            "titre": "1. Objet et acceptation",
            "blocs": [
                _p(
                    f"Le présent contrat définit les conditions dans lesquelles "
                    f"un transporteur devient partenaire de la plateforme "
                    f"{RAISON_SOCIALE} et propose ses véhicules pour l'exécution "
                    f"de missions de transport de marchandises. Son acceptation, "
                    f"matérialisée par la case cochée à l'inscription (valant "
                    f"signature électronique), est une condition obligatoire et "
                    f"préalable à l'utilisation de la plateforme en tant que "
                    f"transporteur."
                ),
            ],
        },
        {
            "titre": "2. Qualité des parties",
            "blocs": [
                _p(
                    f"{RAISON_SOCIALE} exploite une plateforme numérique "
                    "d'intermédiation entre des clients ayant des marchandises à "
                    "transporter et des transporteurs indépendants. Le "
                    "transporteur agit en son nom propre, comme partenaire "
                    f"commercial indépendant : il n'est ni salarié, ni mandataire, "
                    f"ni préposé d'{RAISON_SOCIALE}, et conserve l'entière "
                    "maîtrise de l'organisation de son activité, de ses "
                    "véhicules et de son personnel."
                ),
            ],
        },
        {
            "titre": "3. Inscription et exactitude des informations",
            "blocs": [
                _p(
                    "Le transporteur garantit l'exactitude des informations "
                    "fournies lors de son inscription et de l'ajout de ses "
                    "véhicules et chauffeurs (identité, coordonnées, "
                    "caractéristiques des camions, documents de circulation). "
                    "Il s'engage à maintenir ces informations à jour, "
                    "notamment la disponibilité de ses véhicules et leur "
                    "localisation."
                ),
            ],
        },
        {
            "titre": "4. Obligations du transporteur",
            "blocs": [
                _p("Le transporteur s'engage à :"),
                _liste([
                    "ne proposer que des véhicules en état de circuler et "
                    "conformes à la réglementation de transport de "
                    "marchandises applicable dans les pays traversés ;",
                    "ne confier l'exécution d'une mission qu'à un chauffeur "
                    "habilité, muni de son code d'accès personnel, et garder ce "
                    "code confidentiel — il tient lieu d'identification du "
                    "chauffeur pour toute action sensible dans l'application ;",
                    "exécuter les missions acceptées avec diligence, dans les "
                    "délais annoncés au client, et informer sans délai de tout "
                    "empêchement ;",
                    "actualiser le statut de la mission (départ, arrivée, "
                    "clôture) au fil de son exécution.",
                ]),
            ],
        },
        {
            "titre": "5. Géolocalisation",
            "blocs": [
                _p(
                    "Le transporteur autorise le partage de la position GPS de "
                    "ses chauffeurs pendant qu'un véhicule est déclaré "
                    "disponible ou en cours de mission. Cette localisation sert "
                    "exclusivement à permettre aux clients de trouver un "
                    "véhicule disponible à proximité et à suivre l'avancement "
                    "d'une mission en cours ; elle cesse d'être transmise en "
                    "dehors de ces situations."
                ),
            ],
        },
        {
            "titre": "6. Tarification et propositions",
            "blocs": [
                _p(
                    "Le transporteur détermine librement le prix qu'il propose "
                    "pour chaque demande de transport. Une proposition acceptée "
                    "par le client forme un engagement ferme entre eux sur ce "
                    "prix, la commission de la plateforme (article 7) étant "
                    "calculée sur ce montant sans le modifier pour le client."
                ),
            ],
        },
        {
            "titre": "7. Paiement, commission et versement",
            "blocs": [
                _p(
                    "Le prix de la mission est encaissé par "
                    f"{RAISON_SOCIALE} et conservé en séquestre jusqu'à la "
                    "clôture de la mission (cf. Conditions Générales de "
                    "Paiement). Une commission de plateforme de "
                    f"{taux_bas} % (ou {taux_haut} % au-delà de {seuil} dans la "
                    "devise de la mission) est déduite du montant dû au "
                    "transporteur. Le solde net lui est ensuite versé par "
                    "virement Mobile Money ou bancaire, une fois les fonds "
                    "libérés — ce versement, effectué manuellement, l'est dans "
                    "les meilleurs délais, sans qu'un délai fixe ne soit "
                    "garanti contractuellement."
                ),
            ],
        },
        {
            "titre": "8. Annulation et litiges",
            "blocs": [
                _p(
                    "Une mission peut être annulée avant sa clôture ; si un "
                    "paiement a déjà été encaissé, il est alors remboursé au "
                    "client sans versement au transporteur. Le transporteur "
                    "peut ouvrir un litige sur un paiement sécurisé s'il "
                    "estime que le client n'a pas respecté ses engagements ; "
                    "réciproquement, le client peut ouvrir un litige contre "
                    "lui. Chaque litige est examiné par un administrateur de "
                    "la plateforme, qui tranche en faveur de l'une des parties "
                    "ou rejette le litige."
                ),
            ],
        },
        {
            "titre": "9. Responsabilité du transporteur",
            "blocs": [
                _p(
                    "Le transporteur est seul responsable de l'exécution "
                    "matérielle du transport : état et conformité de son "
                    "véhicule, comportement de son chauffeur, prise en charge, "
                    "conservation et livraison de la marchandise. "
                    f"{RAISON_SOCIALE}, simple intermédiaire technique, n'est "
                    "partie ni au contrat de transport ni responsable d'un "
                    "dommage, retard, perte ou vol survenant pendant son "
                    "exécution."
                ),
            ],
        },
        {
            "titre": "10. Assurance",
            "blocs": [
                _p(
                    "Le transporteur déclare disposer, ou s'engage à souscrire, "
                    "les couvertures d'assurance requises par la réglementation "
                    "applicable à son activité de transport de marchandises "
                    "dans son pays d'exercice (véhicule, marchandises "
                    "transportées, responsabilité civile)."
                ),
            ],
        },
        {
            "titre": "11. Confidentialité et données personnelles",
            "blocs": [
                _p(
                    "Les informations transmises par le client (coordonnées, "
                    "détails de la marchandise) ne peuvent être utilisées par "
                    "le transporteur qu'aux fins de l'exécution de la mission "
                    "concernée, à l'exclusion de toute autre finalité "
                    "commerciale."
                ),
            ],
        },
        {
            "titre": "12. Durée, suspension et résiliation",
            "blocs": [
                _p(
                    "Le présent contrat prend effet à son acceptation et reste "
                    "en vigueur tant que le compte transporteur est actif. "
                    f"{RAISON_SOCIALE} peut suspendre ou clôturer un compte en "
                    "cas de manquement grave ou répété aux présentes "
                    "obligations (fraude, véhicule non conforme, "
                    "non-exécution répétée de missions acceptées). Le "
                    "transporteur peut à tout moment cesser son activité sur "
                    "la plateforme ; la résiliation, dans un sens comme dans "
                    "l'autre, est sans effet sur les missions déjà en cours ou "
                    "sur les paiements déjà engagés à cette date."
                ),
            ],
        },
        {
            "titre": "13. Modification du contrat",
            "blocs": [
                _p(
                    "En cas de modification substantielle du présent contrat, "
                    "une nouvelle acceptation sera demandée au transporteur "
                    "avant de pouvoir continuer à utiliser la plateforme ; "
                    "la version alors en vigueur est identifiée par sa date de "
                    "version."
                ),
            ],
        },
        {
            "titre": "14. Droit applicable",
            "blocs": [
                _p(
                    f"Le présent contrat est régi par le droit en vigueur au "
                    f"siège social d'{RAISON_SOCIALE} ({SIEGE_SOCIAL}). Tout "
                    "différend est d'abord soumis à la procédure de litige "
                    "interne décrite à l'article 8 ; à défaut de résolution, "
                    "les juridictions compétentes du siège social sont seules "
                    "habilitées à en connaître."
                ),
            ],
        },
    ]

    return {
        "type": "TRANSPORTEUR",
        "titre": "Contrat de Partenariat Transporteur",
        "version": CONTRAT_TRANSPORTEUR_VERSION,
        "sections": sections,
    }
