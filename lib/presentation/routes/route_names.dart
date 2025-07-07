class RouteNames {
  RouteNames._();

  // Root routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main app routes (bottom navigation)
  static const String home = '/';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String analytics = '/analytics';
  static const String more = '/more';

  // Account sub-routes
  static const String accountDetails = '/accounts/:accountId';
  static const String addAccount = '/accounts/add';
  static const String editAccount = '/accounts/:accountId/edit';
  static const String accountTransactions = '/accounts/:accountId/transactions';
  static const String transferFunds = '/accounts/transfer';

  // Transaction sub-routes
  static const String transactionDetails = '/transactions/:transactionId';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/:transactionId/edit';
  static const String addIncome = '/transactions/add/income';
  static const String addExpense = '/transactions/add/expense';
  static const String addTransfer = '/transactions/add/transfer';
  static const String duplicateTransaction = '/transactions/:transactionId/duplicate';
  static const String receiptView = '/transactions/:transactionId/receipt';
  static const String voiceInput = '/transactions/voice-input';

  // Category routes
  static const String categories = '/categories';
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/:categoryId/edit';
  static const String categoryDetails = '/categories/:categoryId';

  // Budget routes
  static const String budgets = '/budgets';
  static const String budgetDetails = '/budgets/:budgetId';
  static const String addBudget = '/budgets/add';
  static const String editBudget = '/budgets/:budgetId/edit';

  // Goal routes
  static const String goals = '/goals';
  static const String goalDetails = '/goals/:goalId';
  static const String addGoal = '/goals/add';
  static const String editGoal = '/goals/:goalId/edit';

  // Analytics sub-routes
  static const String incomeExpenseAnalytics = '/analytics/income-expense';
  static const String categoryAnalytics = '/analytics/categories';
  static const String monthlyAnalytics = '/analytics/monthly';
  static const String yearlyAnalytics = '/analytics/yearly';
  static const String customAnalytics = '/analytics/custom';
  static const String financialHealth = '/analytics/financial-health';
  static const String exportData = '/analytics/export';

  // Achievements routes
  static const String achievements = '/achievements';
  static const String achievementDetails = '/achievements/:achievementId';

  // Split expenses routes
  static const String splitExpenses = '/split-expenses';
  static const String splitExpenseDetails = '/split-expenses/:expenseId';
  static const String addSplitExpense = '/split-expenses/add';
  static const String editSplitExpense = '/split-expenses/:expenseId/edit';

  // Recurring transactions routes
  static const String recurringTransactions = '/recurring';
  static const String addRecurringTransaction = '/recurring/add';
  static const String editRecurringTransaction = '/recurring/:recurringId/edit';
  static const String recurringTransactionDetails = '/recurring/:recurringId';

  // Settings and profile routes
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String securitySettings = '/settings/security';
  static const String notificationSettings = '/settings/notifications';
  static const String currencySettings = '/settings/currency';
  static const String themeSettings = '/settings/theme';
  static const String languageSettings = '/settings/language';
  static const String dataSettings = '/settings/data';
  static const String aboutApp = '/settings/about';
  static const String privacyPolicy = '/settings/privacy';
  static const String termsOfService = '/settings/terms';

  // Backup and data routes
  static const String backup = '/backup';
  static const String backupRestore = '/backup/restore';
  static const String backupHistory = '/backup/history';
  static const String dataExport = '/backup/export';
  static const String dataImport = '/backup/import';

  // Help and support routes
  static const String help = '/help';
  static const String helpTopic = '/help/:topicId';
  static const String contact = '/help/contact';
  static const String feedback = '/help/feedback';

  // Error routes
  static const String notFound = '/404';
  static const String error = '/error';

  // Modal routes (for overlays)
  static const String quickAdd = '/quick-add';
  static const String calculator = '/calculator';
  static const String currencyConverter = '/currency-converter';
  static const String scanner = '/scanner';
}
