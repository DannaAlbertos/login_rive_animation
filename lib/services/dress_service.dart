import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dress.dart';

class ApiConfig {
  /// Cambia esta URL cuando conectes con tu backend (puerto 8090 en tu caso).
  static const baseUrl = 'http://10.0.2.2:8090';

  /// true = usa datos de ejemplo (sin backend). Ponlo en false al conectar.
  static const useMock = false;
}

class DressService {
  Future<List<Dress>> getAll() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return _mock;
    }
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/dresses'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al cargar el catálogo');
    }
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) => Dress.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Convierte "/images/abc.jpg" en "http://localhost:8090/images/abc.jpg".
  static String resolveImage(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.baseUrl}$url';
  }

  static const _mock = [
    Dress(id: 1, name: 'Vestido Rosa Floral', description: 'Vestido midi con estampado floral, ideal para primavera.', category: 'Casual', size: 'M', color: 'Rosa', price: 899, stock: 10, imageUrl: '', available: true),
    Dress(id: 2, name: 'Vestido Negro Elegante', description: 'Vestido largo de noche con espalda descubierta.', category: 'Fiesta', size: 'S', color: 'Negro', price: 1850, stock: 4, imageUrl: '', available: true),
    Dress(id: 3, name: 'Vestido Rojo Cocktail', description: 'Vestido corto entallado para eventos.', category: 'Cocktail', size: 'L', color: 'Rojo', price: 1290.5, stock: 6, imageUrl: '', available: true),
    Dress(id: 4, name: 'Vestido Negro Satinado', description: 'Vestido corto de satín con tirantes finos y corte entallado.', category: 'Cocktail', size: 'XS', color: 'Negro', price: 1350, stock: 3, imageUrl: '', available: true),
    Dress(id: 5, name: 'Vestido Azul Marino', description: 'Vestido largo con corte sirena.', category: 'Fiesta', size: 'M', color: 'Azul', price: 1499.9, stock: 0, imageUrl: '', available: true),
    Dress(id: 6, name: 'Vestido Blanco Lino', description: 'Vestido fresco de lino para el día.', category: 'Casual', size: 'S', color: 'Blanco', price: 780, stock: 8, imageUrl: '', available: true),
  ];
}
