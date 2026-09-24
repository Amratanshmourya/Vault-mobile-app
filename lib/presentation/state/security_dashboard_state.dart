import 'package:flutter/material.dart';
import '../../data/models/security_audit_result.dart';
import '../../data/models/vault_item.dart';

enum SecurityFilterType {
  all,
  weak,
  reused,
  old,
  missing2fa,
  passkeyOpportunities,
}

class SecurityDashboardState extends ChangeNotifier {
  SecurityAuditResult? _auditResult;
  SecurityFilterType _selectedFilter = SecurityFilterType.all;

  SecurityAuditResult? get auditResult => _auditResult;
  SecurityFilterType get selectedFilter => _selectedFilter;

  void analyze(List<VaultItem> items) {
    _auditResult = SecurityAuditResult.analyze(items);
    notifyListeners();
  }

  void setFilter(SecurityFilterType filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
}
