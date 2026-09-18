"""Rendu PDF des contrats définis dans `core/contrats.py` — même contenu
structuré que l'aperçu JSON servi à Flutter, mis en forme avec reportlab
(pure Python, sans dépendance système, donc sans risque au déploiement
Railway contrairement à un moteur HTML->PDF comme WeasyPrint)."""

import io
import os

import reportlab
from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Flowable,
    Frame,
    ListFlowable,
    ListItem,
    PageTemplate,
    Paragraph,
    Spacer,
)

# Les polices standard (Helvetica...) de reportlab utilisent l'encodage
# StandardEncoding d'Adobe, qui n'a PAS les caractères accentués français —
# "é"/"è"/"à"... ressortaient en caractères de remplacement dans le PDF
# généré. Vera (Bitstream Vera Sans) est une police TrueType Unicode fournie
# à l'intérieur du paquet reportlab lui-même (`reportlab/fonts/`, licence
# Bitstream Vera) : l'enregistrer une fois au chargement du module évite
# d'ajouter un fichier de police au dépôt tout en garantissant un rendu
# identique en dev et sur Railway (le paquet pip embarque son dossier
# `fonts/` partout où reportlab est installé).
_POLICES_DIR = os.path.join(os.path.dirname(reportlab.__file__), "fonts")
pdfmetrics.registerFont(TTFont("Vera", os.path.join(_POLICES_DIR, "Vera.ttf")))
pdfmetrics.registerFont(TTFont("Vera-Bold", os.path.join(_POLICES_DIR, "VeraBd.ttf")))

# Palette alignée sur l'identité visuelle de l'app Flutter (bleu nuit/accent,
# cf. afriflotte_app/lib/screens/dashboard_admin.dart).
_BLEU_NUIT = colors.HexColor("#102C5C")
_BLEU_ACCENT = colors.HexColor("#2563EB")
_GRIS_TEXTE = colors.HexColor("#374151")
_GRIS_CLAIR = colors.HexColor("#6B7280")


class _TraitSepareur(Flowable):
    """Simple ligne horizontale fine, utilisée sous le titre du document."""

    def __init__(self, largeur, couleur=_BLEU_ACCENT, epaisseur=1.4):
        super().__init__()
        self.largeur = largeur
        self.couleur = couleur
        self.epaisseur = epaisseur

    def draw(self):
        self.canv.setStrokeColor(self.couleur)
        self.canv.setLineWidth(self.epaisseur)
        self.canv.line(0, 0, self.largeur, 0)


def _styles():
    base = getSampleStyleSheet()
    return {
        "titre": ParagraphStyle(
            "TitreContrat",
            parent=base["Title"],
            fontName="Vera-Bold",
            fontSize=20,
            textColor=_BLEU_NUIT,
            spaceAfter=4,
        ),
        "sous_titre": ParagraphStyle(
            "SousTitreContrat",
            parent=base["Normal"],
            fontName="Vera",
            fontSize=9.5,
            textColor=_GRIS_CLAIR,
            spaceAfter=14,
        ),
        "section": ParagraphStyle(
            "TitreSection",
            parent=base["Heading2"],
            fontName="Vera-Bold",
            fontSize=12.5,
            textColor=_BLEU_ACCENT,
            spaceBefore=16,
            spaceAfter=6,
        ),
        "paragraphe": ParagraphStyle(
            "Paragraphe",
            parent=base["Normal"],
            fontName="Vera",
            fontSize=10,
            leading=15,
            textColor=_GRIS_TEXTE,
            spaceAfter=6,
            alignment=4,  # justifié
        ),
        "puce": ParagraphStyle(
            "Puce",
            parent=base["Normal"],
            fontName="Vera",
            fontSize=10,
            leading=14,
            textColor=_GRIS_TEXTE,
            alignment=4,
        ),
    }


def _en_tete_pied(canvas, doc, titre_document):
    canvas.saveState()

    # En-tête : bandeau de marque, discret, répété sur chaque page.
    canvas.setFillColor(_BLEU_NUIT)
    canvas.rect(0, A4[1] - 14 * mm, A4[0], 14 * mm, stroke=0, fill=1)
    canvas.setFillColor(colors.white)
    canvas.setFont("Vera-Bold", 11)
    canvas.drawString(20 * mm, A4[1] - 9.5 * mm, "AfriFlotte")
    canvas.setFont("Vera", 8.5)
    canvas.drawRightString(A4[0] - 20 * mm, A4[1] - 9.5 * mm, titre_document)

    # Pied de page : pagination.
    canvas.setFillColor(_GRIS_CLAIR)
    canvas.setFont("Vera", 8)
    canvas.drawCentredString(
        A4[0] / 2, 12 * mm, f"Page {doc.page}"
    )
    canvas.restoreState()


def generer_pdf_contrat(contrat):
    """`contrat` : structure renvoyée par `contrats.contrat_paiement()` ou
    `contrats.contrat_transporteur()`. Retourne les octets du PDF."""
    tampon = io.BytesIO()
    styles = _styles()

    marge = 20 * mm
    largeur_page, hauteur_page = A4

    document = BaseDocTemplate(
        tampon,
        pagesize=A4,
        leftMargin=marge,
        rightMargin=marge,
        topMargin=22 * mm,
        bottomMargin=18 * mm,
        title=contrat["titre"],
        author="AfriFlotte",
    )
    cadre = Frame(
        marge,
        18 * mm,
        largeur_page - 2 * marge,
        hauteur_page - 22 * mm - 18 * mm,
        id="corps",
    )
    document.addPageTemplates([
        PageTemplate(
            id="page",
            frames=[cadre],
            onPage=lambda canvas, doc: _en_tete_pied(canvas, doc, contrat["titre"]),
        )
    ])

    elements = [
        Paragraph(contrat["titre"], styles["titre"]),
        _TraitSepareur(largeur_page - 2 * marge),
        Spacer(1, 6),
        Paragraph(
            f"Version du {contrat['version']} — document généré le "
            f"{timezone.now().strftime('%d/%m/%Y')}",
            styles["sous_titre"],
        ),
    ]

    for section in contrat["sections"]:
        elements.append(Paragraph(section["titre"], styles["section"]))
        for bloc in section["blocs"]:
            if bloc["type"] == "paragraphe":
                elements.append(Paragraph(bloc["texte"], styles["paragraphe"]))
            elif bloc["type"] == "liste":
                elements.append(
                    ListFlowable(
                        [
                            ListItem(Paragraph(item, styles["puce"]))
                            for item in bloc["items"]
                        ],
                        bulletType="bullet",
                        bulletColor=_BLEU_ACCENT,
                        leftIndent=14,
                        spaceBefore=2,
                        spaceAfter=8,
                    )
                )

    document.build(elements)
    return tampon.getvalue()
