from django.db import migrations


def corriger_unite_capacite(apps, schema_editor):
    # Corrige les camions déjà enregistrés avant que CamionSerializer
    # n'impose la cohérence type_camion <-> unite_capacite (ex: une benne
    # enregistrée en "litres" au lieu de "tonnes").
    Camion = apps.get_model('core', 'Camion')

    Camion.objects.filter(type_camion='CITERNE').exclude(
        unite_capacite='litres'
    ).update(unite_capacite='litres')

    Camion.objects.exclude(type_camion='CITERNE').exclude(
        unite_capacite='tonnes'
    ).update(unite_capacite='tonnes')


def inverser(apps, schema_editor):
    # Pas de retour en arrière significatif : les valeurs d'origine
    # incohérentes ne sont pas conservées.
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0022_alter_notification_type_notification'),
    ]

    operations = [
        migrations.RunPython(corriger_unite_capacite, inverser),
    ]
