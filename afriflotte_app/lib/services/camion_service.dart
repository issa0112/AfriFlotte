import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/camion.dart';
import 'api_service.dart';
import 'authenticated_http.dart';



class CamionService {


  // ==========================
  // LISTE CAMIONS
  // ==========================

  static Future<List<Camion>> getCamions(
      String token
      ) async {


    final response = await AuthenticatedHttp.get(


      Uri.parse(
          "${ApiService.baseUrl}/camions/"
      ),



      headers:{


        "Authorization":
        "Bearer $token",


        "Content-Type":
        "application/json",


      },


    );



    if(response.statusCode == 200){


      final List<dynamic> data =
      jsonDecode(response.body);



      return data.map(

              (json)=>
              Camion.fromJson(json)

      ).toList();


    }


    throw Exception(
        "Erreur récupération camions"
    );


  }





  // ==========================
  // CREATION CAMION
  // ==========================

  static Future<Camion> createCamion({

    required String token,

    required Map<String,dynamic> data,

  }) async {


    final response = await AuthenticatedHttp.post(


      Uri.parse(
          "${ApiService.baseUrl}/camions/"
      ),



      headers:{


        "Authorization":
        "Bearer $token",


        "Content-Type":
        "application/json",


      },



      body:
      jsonEncode(data),


    );




    if(response.statusCode == 201){


      return Camion.fromJson(

          jsonDecode(response.body)

      );


    }



    throw Exception(

        "Erreur création camion : ${response.body}"

    );




  }

  // ==========================
  // MODIFICATION CAMION
  // ==========================

  static Future<Camion> modifierCamion({
    required String token,
    required int camionId,
    required Map<String, dynamic> data,
  }) async {
    final response = await AuthenticatedHttp.patch(
      Uri.parse("${ApiService.baseUrl}/camions/$camionId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Camion.fromJson(jsonDecode(response.body));
    }

    throw Exception("Erreur modification camion : ${response.body}");
  }

  // ==========================
  // UPLOAD IMAGE CAMION
  // ==========================

  /// Prend un `XFile` (pas un `dart:io.File`) : sur Flutter Web il n'y a pas
  /// de vrai système de fichiers, `File.fromPath`/`MultipartFile.fromPath`
  /// y lèvent une erreur. `XFile.readAsBytes()` fonctionne sur toutes les
  /// plateformes, donc on envoie l'image en octets plutôt que par chemin.
  static Future<void> uploadImageCamion({
    required String token,
    required int camionId,
    required XFile imageFile,
  }) async {
    final octets = await imageFile.readAsBytes();

    final response = await AuthenticatedHttp.multipartPost(
      Uri.parse("${ApiService.baseUrl}/camions/images/"),
      headers: {"Authorization": "Bearer $token"},
      fields: {"camion": camionId.toString()},
      construireFichiers: () async => [
        http.MultipartFile.fromBytes(
          "image",
          octets,
          filename: imageFile.name,
        ),
      ],
    );

    if (response.statusCode != 201) {
      throw Exception(
        "Erreur upload image camion : ${response.body}",
      );
    }
  }

  // ==========================
  // SUPPRIMER UNE IMAGE
  // ==========================

  static Future<void> supprimerImageCamion({
    required String token,
    required int imageId,
  }) async {
    final response = await AuthenticatedHttp.delete(
      Uri.parse("${ApiService.baseUrl}/camions/images/$imageId/"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 204) {
      throw Exception(
        "Erreur suppression image : ${response.body}",
      );
    }
  }

  // ==========================
  // DÉFINIR LA PHOTO PRINCIPALE
  // ==========================

  static Future<void> definirImagePrincipale({
    required String token,
    required int imageId,
  }) async {
    final response = await AuthenticatedHttp.patch(
      Uri.parse("${ApiService.baseUrl}/camions/images/$imageId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"principale": true}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Erreur mise à jour photo principale : ${response.body}",
      );
    }
  }

}
