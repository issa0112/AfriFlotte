"""
URL configuration for AfriFlotte project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include, re_path
from django.views.static import serve as servir_fichier_statique

from rest_framework_simplejwt.views import TokenRefreshView
from core.views import LoginView


urlpatterns = [

    path('', include('vitrine.urls')),

    path('admin/', admin.site.urls),

    path(
        'api/',
        include('core.urls')
    ),

    path(
        'api/login/',
        LoginView.as_view(),
        name='token_obtain_pair'
    ),

    path(
        'api/token/refresh/',
        TokenRefreshView.as_view(),
        name='token_refresh'
    ),

]
urlpatterns += static(
    settings.MEDIA_URL,
    document_root=settings.MEDIA_ROOT
)

# Sert le build Flutter Web (`flutter build web --base-href=/app/`) à
# `/app/` — nécessaire aussi bien en dev qu'en production tant qu'un seul
# service Railway héberge vitrine + API + app web : c'est ce build qui
# fournit les écrans de connexion/inscription liés depuis la vitrine (voir
# vitrine/views.py, FLUTTER_APP_URL) et le script de la vitrine qui lit
# `localStorage` exige la même origine, donc pas de CDN séparé pour l'instant.
# Gardé derrière une simple vérification d'existence du dossier (et non plus
# `if settings.DEBUG`) pour ne pas planter tant qu'aucun build n'a encore été
# déposé à cet endroit — à réévaluer si le trafic justifie un vrai CDN.
_dossier_app_flutter = settings.BASE_DIR / 'afriflotte_app' / 'build' / 'web'
if _dossier_app_flutter.is_dir():
    urlpatterns += [
        path(
            'app/',
            servir_fichier_statique,
            {'document_root': _dossier_app_flutter, 'path': 'index.html'},
        ),
        re_path(
            r'^app/(?P<path>.*)$',
            servir_fichier_statique,
            {'document_root': _dossier_app_flutter},
        ),
    ]
