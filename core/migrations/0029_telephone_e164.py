from django.db import migrations

# Copie figée de INDICATIF_PAR_PAYS (core/constants.py) au moment de cette
# migration — par convention Django, une migration de données ne doit pas
# dépendre du code "vivant" de l'app (qui peut changer sous elle plus tard).
INDICATIF_PAR_PAYS = {
    "BJ": "+229",
    "BF": "+226",
    "CV": "+238",
    "CI": "+225",
    "GM": "+220",
    "GH": "+233",
    "GN": "+224",
    "GW": "+245",
    "LR": "+231",
    "ML": "+223",
    "NE": "+227",
    "NG": "+234",
    "SN": "+221",
    "SL": "+232",
    "TG": "+228",
}


def normaliser_telephones(apps, schema_editor):
    """Préfixe l'indicatif du pays de chaque ligne aux numéros pas encore au
    format international (comptes créés avant le passage E.164) — comptes de
    démo/test locaux, aucune validation stricte ici pour ne jamais faire
    échouer la migration sur une donnée farfelue, juste un préfixage."""
    for nom_modele in ("User", "Chauffeur"):
        Modele = apps.get_model("core", nom_modele)
        queryset = Modele.objects.exclude(telephone__isnull=True).exclude(telephone="")
        for obj in queryset:
            if obj.telephone.startswith("+"):
                continue
            indicatif = INDICATIF_PAR_PAYS.get(obj.pays, "+223")
            obj.telephone = f"{indicatif}{obj.telephone}"
            obj.save(update_fields=["telephone"])


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0028_alter_notification_type_notification_and_more'),
    ]

    operations = [
        migrations.RunPython(normaliser_telephones, migrations.RunPython.noop),
    ]
