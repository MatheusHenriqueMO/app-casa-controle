import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/house.dart';
import '../models/expense.dart';
import '../models/balance_summary.dart';
import 'auth_service.dart';

class ApiService {
  // Troque pela URL do seu servidor em produção
  static const String baseUrl = 'https://app-casa-controle-production.up.railway.app/api'; // Railway
  // static const String baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:8080/api'; // iOS simulator

  final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  // ── Houses ──────────────────────────────────────────────────────────────────

  Future<House> createHouse(String name) async {
    final res = await _dio.post('/houses', data: {'name': name});
    return House.fromJson(res.data);
  }

  Future<House> joinHouse(String inviteCode) async {
    final res = await _dio.post('/houses/join', data: {'inviteCode': inviteCode});
    return House.fromJson(res.data);
  }

  Future<House> getHouse(String houseId) async {
    final res = await _dio.get('/houses/$houseId');
    return House.fromJson(res.data);
  }

  // ── Expenses ─────────────────────────────────────────────────────────────────

  Future<Expense> createExpense({
    required String houseId,
    required String description,
    required double amount,
    required String category,
    List<String>? splitWith,
    DateTime? date,
    bool isFixed = false,
  }) async {
    final res = await _dio.post('/houses/$houseId/expenses', data: {
      'description': description,
      'amount': amount,
      'category': category,
      'isFixed': isFixed,
      if (splitWith != null) 'splitWith': splitWith,
      if (date != null) 'date': date.toUtc().toIso8601String(),
    });
    return Expense.fromJson(res.data);
  }

  Future<List<Expense>> listExpenses(String houseId, {int? year, int? month}) async {
    final res = await _dio.get('/houses/$houseId/expenses', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return (res.data as List).map((e) => Expense.fromJson(e)).toList();
  }

  Future<void> deleteExpense(String houseId, String expenseId) async {
    await _dio.delete('/houses/$houseId/expenses/$expenseId');
  }

  Future<BalanceSummary> getSummary(String houseId, {int? year, int? month}) async {
    final now = DateTime.now();
    final res = await _dio.get('/houses/$houseId/expenses/summary', queryParameters: {
      'year': year ?? now.year,
      'month': month ?? now.month,
    });
    return BalanceSummary.fromJson(res.data);
  }
}
