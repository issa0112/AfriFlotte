"""Textes bilingues (FR/EN) de la page vitrine.

Pas de framework i18n Django ici (gettext/`compilemessages` demande des
outils GNU gettext absents de cette machine Windows) — un simple
dictionnaire par langue, choisi via `?lang=` ou un cookie (voir
`vitrine.views.landing`)."""

LANGUES_DISPONIBLES = ("fr", "en")
LANGUE_PAR_DEFAUT = "fr"

TEXTES = {
    "fr": {
        # SEO / meta
        "meta_titre": "AfriFlotte — Transport de marchandises en Afrique de l'Ouest",
        "meta_description": (
            "AfriFlotte connecte entreprises et transporteurs en Afrique de "
            "l'Ouest : publiez une demande de transport, comparez les "
            "propositions, suivez vos missions et sécurisez vos paiements."
        ),
        "og_description": (
            "Publiez une demande, comparez les propositions de transporteurs, "
            "suivez vos missions et payez en toute sécurité — partout en "
            "Afrique de l'Ouest."
        ),
        "og_locale": "fr_FR",
        "jsonld_description": (
            "Plateforme de mise en relation et de gestion du transport de "
            "marchandises en Afrique de l'Ouest."
        ),
        # Navigation / en-tête
        "nav_comment": "Comment ça marche",
        "nav_entreprises": "Entreprises",
        "nav_transporteurs": "Transporteurs",
        "nav_couverture": "Couverture",
        "nav_securite": "Sécurité",
        "btn_connexion": "Se connecter",
        "btn_inscription": "Créer un compte",
        # Bouton de téléchargement (badge)
        "telecharger_sur": "Télécharger sur",
        "bientot_sur": "Bientôt sur",
        "telecharger_aria": "Télécharger l'application Android",
        "telecharger_aria_bientot": "Télécharger l'application Android — bientôt disponible",
        "telecharger_titre_desactive": "Application bientôt disponible",
        # Hero
        "hero_eyebrow": "Transport & logistique — Afrique de l'Ouest",
        "hero_accroche": "Connectez vos besoins de transport aux meilleurs transporteurs.",
        "hero_texte": (
            "AfriFlotte met en relation entreprises et transporteurs à "
            "travers l'Afrique de l'Ouest : publiez une demande, comparez "
            "les propositions, suivez chaque mission en temps réel et payez "
            "en toute sécurité, du premier kilomètre à la livraison."
        ),
        "hero_visuel_alt": "AfriFlotte — réseau de transport en Afrique de l'Ouest",
        # Comment ça marche
        "cc_titre": "Comment ça marche ?",
        "cc_soustitre": (
            "De la demande à la livraison, six étapes suffisent pour "
            "sécuriser un transport de bout en bout."
        ),
        "etape1_titre": "Publier une demande",
        "etape1_texte": "Le client décrit son besoin : trajet, type de marchandise, camion recherché.",
        "etape2_titre": "Recevoir des propositions",
        "etape2_texte": "Les transporteurs disponibles proposent leurs véhicules et leur prix.",
        "etape3_titre": "Choisir une proposition",
        "etape3_texte": "Le client compare et sélectionne l'offre la plus adaptée.",
        "etape4_titre": "Mission confirmée",
        "etape4_texte": "Le transporteur et le chauffeur affecté sont notifiés, la mission démarre.",
        "etape5_titre": "Suivi jusqu'à la livraison",
        "etape5_texte": "Le trajet est suivi en direct jusqu'à la confirmation de livraison.",
        "etape6_titre": "Paiement sécurisé",
        "etape6_texte": "Les fonds sont libérés au transporteur selon les conditions de la mission.",
        # Pour les entreprises
        "entreprises_titre": "Pour les entreprises",
        "entreprises_soustitre": "Trouvez le bon camion, au bon moment, sans multiplier les appels.",
        "entreprises_li1": "Trouver rapidement des camions disponibles",
        "entreprises_li2": "Publier des demandes de transport",
        "entreprises_li3": "Comparer les propositions des transporteurs",
        "entreprises_li4": "Suivre les missions en temps réel",
        "entreprises_li5": "Centraliser toutes les opérations de transport",
        "entreprises_li6": "Sécuriser les paiements",
        "entreprises_li7": "Réduire les délais de recherche de véhicules",
        "entreprises_carte_legende1": "Un tableau de bord unique",
        "entreprises_carte_legende2": "des opérations de transport centralisées",
        "entreprises_carte_legende3": "Demandes, propositions, missions et paiements suivis au même endroit.",
        # Pour les transporteurs
        "transporteurs_titre": "Pour les transporteurs",
        "transporteurs_soustitre": "Gardez vos camions en mouvement et développez votre activité.",
        "transporteurs_li1": "Trouver de nouvelles missions",
        "transporteurs_li2": "Présenter leurs camions",
        "transporteurs_li3": "Recevoir des demandes de transport",
        "transporteurs_li4": "Gérer leurs missions",
        "transporteurs_li5": "Développer leur activité",
        "transporteurs_li6": "Améliorer le taux d'utilisation de leurs véhicules",
        "transporteurs_carte_legende1": "Moins de trajets à vide",
        "transporteurs_carte_legende2": "de missions grâce à un flux constant de demandes",
        "transporteurs_carte_legende3": "Chaque camion, chaque chauffeur, suivi en un coup d'œil.",
        # Types de transport
        "camions_titre": "Types de transport",
        "camions_soustitre": "Tous les gabarits nécessaires au transport de marchandises, quelle que soit la cargaison.",
        "camion_citerne": "Camion-citerne",
        "camion_benne": "Benne",
        "camion_plateau": "Plateau",
        "camion_conteneur": "Porte-char",
        "camion_6roues": "Camion 6 roues",
        "camion_10roues": "Camion 10 roues",
        "camion_12roues": "Camion 12 roues",
        "camion_semi": "Semi-remorque",
        "camion_autres": "Et d'autres catégories",
        # Couverture
        "couverture_titre": "Une couverture Afrique de l'Ouest",
        "couverture_soustitre": (
            "AfriFlotte n'est pas limité à un seul pays : la plateforme est "
            "conçue pour couvrir l'ensemble de la sous-région, avec une "
            "architecture pensée pour accueillir facilement de nouveaux pays."
        ),
        # Sécurité / paiement
        "securite_titre": "Paiements sécurisés",
        "securite_soustitre": (
            "AfriFlotte retient les fonds jusqu'à ce que les conditions de "
            "la mission soient remplies, avant de les verser au transporteur."
        ),
        "securite_carte1_titre": "Paiement par carte",
        "securite_carte1_texte": (
            "Le client règle la mission par carte bancaire ; AfriFlotte "
            "sécurise les fonds jusqu'à la confirmation de la livraison, "
            "puis les libère au transporteur, commission déduite."
        ),
        "securite_carte2_titre": "Paiement assisté (espèces)",
        "securite_carte2_texte": (
            "Pas de carte bancaire ou de compte en ligne ? Un agent "
            "AfriFlotte peut encaisser le paiement en espèces et le faire "
            "suivre dans le même circuit sécurisé."
        ),
        # Téléchargement
        "telechargement_titre": "Téléchargez l'application AfriFlotte",
        "telechargement_texte": "Emportez AfriFlotte partout avec vous.",
        "telechargement_bientot": "Bientôt disponible · Android",
        "telechargement_version_label": "Version",
        # CTA final
        "cta_titre": "Transportez plus. Trouvez plus. Développez plus.",
        # Pied de page
        "footer_region": "Afrique de l'Ouest",
    },
    "en": {
        # SEO / meta
        "meta_titre": "AfriFlotte — Freight Transport Across West Africa",
        "meta_description": (
            "AfriFlotte connects businesses and carriers across West "
            "Africa: post a transport request, compare offers, track your "
            "missions and secure your payments."
        ),
        "og_description": (
            "Post a request, compare carrier offers, track your missions "
            "and pay securely — anywhere in West Africa."
        ),
        "og_locale": "en_US",
        "jsonld_description": (
            "A platform connecting and managing freight transport across "
            "West Africa."
        ),
        # Navigation / header
        "nav_comment": "How it works",
        "nav_entreprises": "Businesses",
        "nav_transporteurs": "Carriers",
        "nav_couverture": "Coverage",
        "nav_securite": "Security",
        "btn_connexion": "Log in",
        "btn_inscription": "Create an account",
        # Download button (badge)
        "telecharger_sur": "Download on",
        "bientot_sur": "Coming soon on",
        "telecharger_aria": "Download the Android app",
        "telecharger_aria_bientot": "Download the Android app — coming soon",
        "telecharger_titre_desactive": "App coming soon",
        # Hero
        "hero_eyebrow": "Transport & logistics — West Africa",
        "hero_accroche": "Connect your transport needs to the best carriers.",
        "hero_texte": (
            "AfriFlotte connects businesses and carriers across West "
            "Africa: post a request, compare offers, track every mission "
            "in real time and pay securely, from the first mile to delivery."
        ),
        "hero_visuel_alt": "AfriFlotte — transport network across West Africa",
        # How it works
        "cc_titre": "How does it work?",
        "cc_soustitre": (
            "From request to delivery, six steps are all it takes to "
            "secure end-to-end transport."
        ),
        "etape1_titre": "Post a request",
        "etape1_texte": "The client describes their need: route, type of goods, truck required.",
        "etape2_titre": "Receive offers",
        "etape2_texte": "Available carriers offer their vehicles and their price.",
        "etape3_titre": "Choose an offer",
        "etape3_texte": "The client compares and selects the best-suited offer.",
        "etape4_titre": "Mission confirmed",
        "etape4_texte": "The carrier and the assigned driver are notified, the mission begins.",
        "etape5_titre": "Tracking through to delivery",
        "etape5_texte": "The route is tracked live until delivery is confirmed.",
        "etape6_titre": "Secure payment",
        "etape6_texte": "Funds are released to the carrier according to the mission's terms.",
        # For businesses
        "entreprises_titre": "For businesses",
        "entreprises_soustitre": "Find the right truck, at the right time, without endless phone calls.",
        "entreprises_li1": "Quickly find available trucks",
        "entreprises_li2": "Post transport requests",
        "entreprises_li3": "Compare carrier offers",
        "entreprises_li4": "Track missions in real time",
        "entreprises_li5": "Centralize all transport operations",
        "entreprises_li6": "Secure payments",
        "entreprises_li7": "Cut down vehicle search times",
        "entreprises_carte_legende1": "One single dashboard",
        "entreprises_carte_legende2": "of transport operations centralized",
        "entreprises_carte_legende3": "Requests, offers, missions and payments tracked in one place.",
        # For carriers
        "transporteurs_titre": "For carriers",
        "transporteurs_soustitre": "Keep your trucks moving and grow your business.",
        "transporteurs_li1": "Find new missions",
        "transporteurs_li2": "Showcase their trucks",
        "transporteurs_li3": "Receive transport requests",
        "transporteurs_li4": "Manage their missions",
        "transporteurs_li5": "Grow their business",
        "transporteurs_li6": "Improve their vehicle utilization rate",
        "transporteurs_carte_legende1": "Fewer empty trips",
        "transporteurs_carte_legende2": "more missions thanks to a steady flow of requests",
        "transporteurs_carte_legende3": "Every truck, every driver, tracked at a glance.",
        # Types of transport
        "camions_titre": "Types of transport",
        "camions_soustitre": "Every truck size needed to move goods, whatever the cargo.",
        "camion_citerne": "Tanker truck",
        "camion_benne": "Dump truck",
        "camion_plateau": "Flatbed",
        "camion_conteneur": "Container carrier",
        "camion_6roues": "6-wheel truck",
        "camion_10roues": "10-wheel truck",
        "camion_12roues": "12-wheel truck",
        "camion_semi": "Semi-trailer",
        "camion_autres": "And other categories",
        # Coverage
        "couverture_titre": "Coverage across West Africa",
        "couverture_soustitre": (
            "AfriFlotte isn't limited to a single country: the platform is "
            "built to cover the whole sub-region, with an architecture "
            "designed to easily welcome new countries."
        ),
        # Security / payment
        "securite_titre": "Secure payments",
        "securite_soustitre": (
            "AfriFlotte holds the funds until the mission's conditions are "
            "met, before releasing them to the carrier."
        ),
        "securite_carte1_titre": "Card payment",
        "securite_carte1_texte": (
            "The client pays for the mission by card; AfriFlotte holds the "
            "funds securely until delivery is confirmed, then releases "
            "them to the carrier, minus commission."
        ),
        "securite_carte2_titre": "Assisted payment (cash)",
        "securite_carte2_texte": (
            "No bank card or online account? An AfriFlotte agent can "
            "collect the payment in cash and route it through the same "
            "secure process."
        ),
        # Download
        "telechargement_titre": "Download the AfriFlotte app",
        "telechargement_texte": "Take AfriFlotte with you everywhere.",
        "telechargement_bientot": "Coming soon · Android",
        "telechargement_version_label": "Version",
        # Final CTA
        "cta_titre": "Move more. Find more. Grow more.",
        # Footer
        "footer_region": "West Africa",
    },
}


def resoudre_langue(request):
    """Langue active : `?lang=` (prioritaire, persistée en cookie) puis
    cookie `afriflotte_lang`, sinon `LANGUE_PAR_DEFAUT`."""
    depuis_query = request.GET.get("lang")
    if depuis_query in LANGUES_DISPONIBLES:
        return depuis_query, depuis_query

    depuis_cookie = request.COOKIES.get("afriflotte_lang")
    if depuis_cookie in LANGUES_DISPONIBLES:
        return depuis_cookie, None

    return LANGUE_PAR_DEFAUT, None
