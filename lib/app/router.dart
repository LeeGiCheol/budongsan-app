import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budongsan_app/features/home/screens/home_screen.dart';
import 'package:budongsan_app/features/loan_calculator/screens/loan_calculator_screen.dart';
import 'package:budongsan_app/features/acquisition_tax/screens/acquisition_tax_screen.dart';
import 'package:budongsan_app/features/monthly_expense/screens/monthly_expense_screen.dart';
import 'package:budongsan_app/features/cash_flow/screens/cash_flow_screen.dart';
import 'package:budongsan_app/features/dsr/screens/dsr_screen.dart';
import 'package:budongsan_app/features/checklist/screens/checklist_screen.dart';
import 'package:budongsan_app/features/comparison/screens/comparison_screen.dart';
import 'package:budongsan_app/features/saved_calculations/screens/saved_calculations_screen.dart';
import 'package:budongsan_app/features/settings/screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/loan-calculator',
        name: 'loanCalculator',
        builder: (context, state) => const LoanCalculatorScreen(),
      ),
      GoRoute(
        path: '/acquisition-tax',
        name: 'acquisitionTax',
        builder: (context, state) => const AcquisitionTaxScreen(),
      ),
      GoRoute(
        path: '/monthly-expense',
        name: 'monthlyExpense',
        builder: (context, state) => const MonthlyExpenseScreen(),
      ),
      GoRoute(
        path: '/cash-flow',
        name: 'cashFlow',
        builder: (context, state) => const CashFlowScreen(),
      ),
      GoRoute(
        path: '/dsr',
        name: 'dsr',
        builder: (context, state) => const DsrScreen(),
      ),
      GoRoute(
        path: '/checklist',
        name: 'checklist',
        builder: (context, state) => const ChecklistScreen(),
      ),
      GoRoute(
        path: '/comparison',
        name: 'comparison',
        builder: (context, state) => const ComparisonScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'savedCalculations',
        builder: (context, state) => const SavedCalculationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
