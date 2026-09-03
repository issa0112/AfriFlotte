from django.contrib.auth.hashers import PBKDF2PasswordHasher


class FastDebugPBKDF2Hasher(PBKDF2PasswordHasher):
    """PBKDF2 avec peu d'itérations — utilisé uniquement quand DEBUG=True
    (cf. `PASSWORD_HASHERS` dans settings.py), jamais en production.

    Le hasher par défaut de Django (1 200 000 itérations) est volontairement
    coûteux en CPU pour résister au brute-force ; sur du matériel de dev
    modeste ça peut prendre plusieurs secondes par connexion, au point de
    dépasser le timeout client de l'app. En le mettant en tête de
    `PASSWORD_HASHERS`, Django l'utilise pour tout nouveau mot de passe
    (inscription, réinitialisation) et rehache automatiquement avec celui-ci
    dès la prochaine connexion réussie d'un compte existant (mécanisme
    standard `check_password(..., setter=...)` de Django) — aucune migration
    de données à faire à la main.
    """

    iterations = 20000
