# Generated manually to preserve every existing Paiement row while extending
# the Django choice list with the Mobile Money mode.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0030_paiement_carte_metadata"),
    ]

    operations = [
        migrations.AlterField(
            model_name="paiement",
            name="mode",
            field=models.CharField(
                choices=[
                    ("CARTE", "Carte bancaire"),
                    ("MOBILE", "Mobile Money"),
                    ("MANUEL", "Manuel (main à main)"),
                ],
                max_length=10,
            ),
        ),
    ]
