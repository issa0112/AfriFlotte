import 'dart:convert';

import '../models/admin_dashboard_model.dart';
import '../models/dashboard_client_model.dart';
import '../models/dashboard_transporteur_model.dart';
import 'api_service.dart';
import 'authenticated_http.dart';


class DashboardService {


  static Future<DashboardTransporteurModel>
  getDashboard(String token) async {

    final response = await AuthenticatedHttp.get(
      Uri.parse(
        "${ApiService.baseUrl}/transporteur/dashboard/"
      ),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if(response.statusCode == 200){

      final json =
      jsonDecode(response.body);

      return DashboardTransporteurModel
          .fromJson(json);

    }else{

      throw Exception(
          "Erreur chargement dashboard"
      );

    }

  }



  static Future<AdminDashboardModel> getAdminDashboard(String token) async {

    final response = await AuthenticatedHttp.get(
      Uri.parse("${ApiService.baseUrl}/admin/dashboard/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return AdminDashboardModel.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 403) {
      throw Exception("Accès réservé aux administrateurs.");
    }

    throw Exception("Erreur chargement dashboard admin");
  }


  static Future<DashboardClientModel> getClientDashboard(String token) async {
    final response = await AuthenticatedHttp.get(
      Uri.parse("${ApiService.baseUrl}/client/dashboard/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return DashboardClientModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Erreur chargement dashboard client");
  }

}
