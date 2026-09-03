from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import *


@admin.register(User)
class CustomUserAdmin(UserAdmin):

    fieldsets = UserAdmin.fieldsets + (
        (
            "Informations AfriFlotte",
            {
                "fields": (
                    "telephone",
                    "type_compte",
                    "nom_entreprise",
                    "adresse",
                )
            }
        ),
    )


    add_fieldsets = UserAdmin.add_fieldsets + (
        (
            "Informations AfriFlotte",
            {
                "fields": (
                    "telephone",
                    "type_compte",
                    "nom_entreprise",
                    "adresse",
                )
            }
        ),
    )


    list_display = (
        "username",
        "telephone",
        "type_compte",
        "nom_entreprise",
        "is_active",
    )



@admin.register(Camion)
class CamionAdmin(admin.ModelAdmin):

    list_display = (
        'immatriculation',
        'type_camion',
        'proprietaire',
        'capacite',
        'disponible'
    )

    list_filter = (
        'type_camion',
        'pays',
        'disponible'
    )


@admin.register(ImageCamion)
class ImageCamionAdmin(admin.ModelAdmin):

    list_display = (
        'camion',
        'date_ajout'
    )



@admin.register(DemandeTransport)
class DemandeTransportAdmin(admin.ModelAdmin):

    list_display = (
        'client',
        'ville_depart',
        'ville_arrivee',
        'type_camion',
        'nombre_camions',
        'statut'
    )


    list_filter = (
        'type_camion',
        'statut',
        'pays_depart',
        'pays_arrivee',
    )



@admin.register(Mission)
class MissionAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'demande',
        'transporteur',
        'camions_list',
        'statut'
    )

    list_filter = (
        'statut',
    )


    def camions_list(self, obj):

        return ", ".join(
            mission_camion.camion.immatriculation
            for mission_camion in obj.camions.select_related('camion')
        )


    camions_list.short_description = 'Camions'