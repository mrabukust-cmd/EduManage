import 'package:flutter/material.dart';
import 'package:school_management_system/features/admin/admin_dashboard_screen.dart';

/// This file intentionally re-exports AdminDashboardScreen (defined in
/// admin_dashboard_screen.dart, which already pulls real counts and recent
/// notices from Firestore) so any import of
/// `features/admin/dashboard_screen.dart` keeps working without duplicating
/// the widget tree in two places.
export 'package:school_management_system/features/admin/admin_dashboard_screen.dart'
    show AdminDashboardScreen;

typedef AdminDashboard = AdminDashboardScreen;