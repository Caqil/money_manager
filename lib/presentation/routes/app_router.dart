import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import your pages here (you'll need to create these)
// import '../../presentation/pages/auth/splash_page.dart';
// import '../../presentation/pages/auth/onboarding_page.dart';
// import '../../presentation/pages/auth/login_page.dart';
// import '../../presentation/pages/auth/register_page.dart';
// import '../../presentation/pages/main/home_page.dart';
// import '../../presentation/pages/main/main_wrapper.dart';
// ... import other pages

import '../pages/main/main_layout.dart';
import '../screens/error/error_page.dart';
import 'route_names.dart';

class AppRouter {
  static late final GoRouter router;

  static void initialize() {
    router = GoRouter(
      initialLocation: RouteNames.splash,
      debugLogDiagnostics: true,
      routes: [
        // Auth routes
        GoRoute(
          path: RouteNames.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: RouteNames.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteNames.register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordPage(),
        ),

        // Main app shell with bottom navigation
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            // Home
            GoRoute(
              path: RouteNames.home,
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),

            // Accounts section
            GoRoute(
              path: RouteNames.accounts,
              name: 'accounts',
              builder: (context, state) => const AccountsPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addAccount',
                  builder: (context, state) => const AddAccountPage(),
                ),
                GoRoute(
                  path: ':accountId',
                  name: 'accountDetails',
                  builder: (context, state) => AccountDetailsPage(
                    accountId: state.pathParameters['accountId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'editAccount',
                      builder: (context, state) => EditAccountPage(
                        accountId: state.pathParameters['accountId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'transactions',
                      name: 'accountTransactions',
                      builder: (context, state) => AccountTransactionsPage(
                        accountId: state.pathParameters['accountId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'transfer',
                  name: 'transferFunds',
                  builder: (context, state) => const TransferFundsPage(),
                ),
              ],
            ),

            // Transactions section
            GoRoute(
              path: RouteNames.transactions,
              name: 'transactions',
              builder: (context, state) => const TransactionsPage(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addTransaction',
                  builder: (context, state) => const AddTransactionPage(),
                  routes: [
                    GoRoute(
                      path: 'income',
                      name: 'addIncome',
                      builder: (context, state) => const AddIncomePage(),
                    ),
                    GoRoute(
                      path: 'expense',
                      name: 'addExpense',
                      builder: (context, state) => const AddExpensePage(),
                    ),
                    GoRoute(
                      path: 'transfer',
                      name: 'addTransfer',
                      builder: (context, state) => const AddTransferPage(),
                    ),
                  ],
                ),
                GoRoute(
                  path: ':transactionId',
                  name: 'transactionDetails',
                  builder: (context, state) => TransactionDetailsPage(
                    transactionId: state.pathParameters['transactionId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'editTransaction',
                      builder: (context, state) => EditTransactionPage(
                        transactionId: state.pathParameters['transactionId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'duplicate',
                      name: 'duplicateTransaction',
                      builder: (context, state) => DuplicateTransactionPage(
                        transactionId: state.pathParameters['transactionId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'receipt',
                      name: 'receiptView',
                      builder: (context, state) => ReceiptViewPage(
                        transactionId: state.pathParameters['transactionId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'voice-input',
                  name: 'voiceInput',
                  builder: (context, state) => const VoiceInputPage(),
                ),
              ],
            ),

            // Analytics section
            GoRoute(
              path: RouteNames.analytics,
              name: 'analytics',
              builder: (context, state) => const AnalyticsPage(),
              routes: [
                GoRoute(
                  path: 'income-expense',
                  name: 'incomeExpenseAnalytics',
                  builder: (context, state) =>
                      const IncomeExpenseAnalyticsPage(),
                ),
                GoRoute(
                  path: 'categories',
                  name: 'categoryAnalytics',
                  builder: (context, state) => const CategoryAnalyticsPage(),
                ),
                GoRoute(
                  path: 'monthly',
                  name: 'monthlyAnalytics',
                  builder: (context, state) => const MonthlyAnalyticsPage(),
                ),
                GoRoute(
                  path: 'yearly',
                  name: 'yearlyAnalytics',
                  builder: (context, state) => const YearlyAnalyticsPage(),
                ),
                GoRoute(
                  path: 'financial-health',
                  name: 'financialHealth',
                  builder: (context, state) => const FinancialHealthPage(),
                ),
                GoRoute(
                  path: 'export',
                  name: 'exportData',
                  builder: (context, state) => const ExportDataPage(),
                ),
              ],
            ),

            // More section
            GoRoute(
              path: RouteNames.more,
              name: 'more',
              builder: (context, state) => const MorePage(),
            ),
          ],
        ),

        // Categories (can be accessed from multiple places)
        GoRoute(
          path: RouteNames.categories,
          name: 'categories',
          builder: (context, state) => const CategoriesPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addCategory',
              builder: (context, state) => const AddCategoryPage(),
            ),
            GoRoute(
              path: ':categoryId',
              name: 'categoryDetails',
              builder: (context, state) => CategoryDetailsPage(
                categoryId: state.pathParameters['categoryId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editCategory',
                  builder: (context, state) => EditCategoryPage(
                    categoryId: state.pathParameters['categoryId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Budgets
        GoRoute(
          path: RouteNames.budgets,
          name: 'budgets',
          builder: (context, state) => const BudgetsPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addBudget',
              builder: (context, state) => const AddBudgetPage(),
            ),
            GoRoute(
              path: ':budgetId',
              name: 'budgetDetails',
              builder: (context, state) => BudgetDetailsPage(
                budgetId: state.pathParameters['budgetId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editBudget',
                  builder: (context, state) => EditBudgetPage(
                    budgetId: state.pathParameters['budgetId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Goals
        GoRoute(
          path: RouteNames.goals,
          name: 'goals',
          builder: (context, state) => const GoalsPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addGoal',
              builder: (context, state) => const AddGoalPage(),
            ),
            GoRoute(
              path: ':goalId',
              name: 'goalDetails',
              builder: (context, state) => GoalDetailsPage(
                goalId: state.pathParameters['goalId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editGoal',
                  builder: (context, state) => EditGoalPage(
                    goalId: state.pathParameters['goalId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Achievements
        GoRoute(
          path: RouteNames.achievements,
          name: 'achievements',
          builder: (context, state) => const AchievementsPage(),
          routes: [
            GoRoute(
              path: ':achievementId',
              name: 'achievementDetails',
              builder: (context, state) => AchievementDetailsPage(
                achievementId: state.pathParameters['achievementId']!,
              ),
            ),
          ],
        ),

        // Split expenses
        GoRoute(
          path: RouteNames.splitExpenses,
          name: 'splitExpenses',
          builder: (context, state) => const SplitExpensesPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addSplitExpense',
              builder: (context, state) => const AddSplitExpensePage(),
            ),
            GoRoute(
              path: ':expenseId',
              name: 'splitExpenseDetails',
              builder: (context, state) => SplitExpenseDetailsPage(
                expenseId: state.pathParameters['expenseId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editSplitExpense',
                  builder: (context, state) => EditSplitExpensePage(
                    expenseId: state.pathParameters['expenseId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Recurring transactions
        GoRoute(
          path: RouteNames.recurringTransactions,
          name: 'recurringTransactions',
          builder: (context, state) => const RecurringTransactionsPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addRecurringTransaction',
              builder: (context, state) => const AddRecurringTransactionPage(),
            ),
            GoRoute(
              path: ':recurringId',
              name: 'recurringTransactionDetails',
              builder: (context, state) => RecurringTransactionDetailsPage(
                recurringId: state.pathParameters['recurringId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editRecurringTransaction',
                  builder: (context, state) => EditRecurringTransactionPage(
                    recurringId: state.pathParameters['recurringId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Settings
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'security',
              name: 'securitySettings',
              builder: (context, state) => const SecuritySettingsPage(),
            ),
            GoRoute(
              path: 'notifications',
              name: 'notificationSettings',
              builder: (context, state) => const NotificationSettingsPage(),
            ),
            GoRoute(
              path: 'currency',
              name: 'currencySettings',
              builder: (context, state) => const CurrencySettingsPage(),
            ),
            GoRoute(
              path: 'theme',
              name: 'themeSettings',
              builder: (context, state) => const ThemeSettingsPage(),
            ),
            GoRoute(
              path: 'language',
              name: 'languageSettings',
              builder: (context, state) => const LanguageSettingsPage(),
            ),
            GoRoute(
              path: 'data',
              name: 'dataSettings',
              builder: (context, state) => const DataSettingsPage(),
            ),
            GoRoute(
              path: 'about',
              name: 'aboutApp',
              builder: (context, state) => const AboutAppPage(),
            ),
            GoRoute(
              path: 'privacy',
              name: 'privacyPolicy',
              builder: (context, state) => const PrivacyPolicyPage(),
            ),
            GoRoute(
              path: 'terms',
              name: 'termsOfService',
              builder: (context, state) => const TermsOfServicePage(),
            ),
          ],
        ),

        // Profile
        GoRoute(
          path: RouteNames.profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'editProfile',
              builder: (context, state) => const EditProfilePage(),
            ),
            GoRoute(
              path: 'change-password',
              name: 'changePassword',
              builder: (context, state) => const ChangePasswordPage(),
            ),
          ],
        ),

        // Backup
        GoRoute(
          path: RouteNames.backup,
          name: 'backup',
          builder: (context, state) => const BackupPage(),
          routes: [
            GoRoute(
              path: 'restore',
              name: 'backupRestore',
              builder: (context, state) => const BackupRestorePage(),
            ),
            GoRoute(
              path: 'history',
              name: 'backupHistory',
              builder: (context, state) => const BackupHistoryPage(),
            ),
            GoRoute(
              path: 'export',
              name: 'dataExport',
              builder: (context, state) => const DataExportPage(),
            ),
            GoRoute(
              path: 'import',
              name: 'dataImport',
              builder: (context, state) => const DataImportPage(),
            ),
          ],
        ),

        // Help
        GoRoute(
          path: RouteNames.help,
          name: 'help',
          builder: (context, state) => const HelpPage(),
          routes: [
            GoRoute(
              path: ':topicId',
              name: 'helpTopic',
              builder: (context, state) => HelpTopicPage(
                topicId: state.pathParameters['topicId']!,
              ),
            ),
            GoRoute(
              path: 'contact',
              name: 'contact',
              builder: (context, state) => const ContactPage(),
            ),
            GoRoute(
              path: 'feedback',
              name: 'feedback',
              builder: (context, state) => const FeedbackPage(),
            ),
          ],
        ),

        // Modal routes
        GoRoute(
          path: RouteNames.quickAdd,
          name: 'quickAdd',
          builder: (context, state) => const QuickAddPage(),
        ),
        GoRoute(
          path: RouteNames.calculator,
          name: 'calculator',
          builder: (context, state) => const CalculatorPage(),
        ),
        GoRoute(
          path: RouteNames.currencyConverter,
          name: 'currencyConverter',
          builder: (context, state) => const CurrencyConverterPage(),
        ),
        GoRoute(
          path: RouteNames.scanner,
          name: 'scanner',
          builder: (context, state) => const ScannerPage(),
        ),

        // Error routes
        GoRoute(
          path: RouteNames.notFound,
          name: 'notFound',
          builder: (context, state) => const NotFoundPage(),
        ),
        GoRoute(
          path: RouteNames.error,
          name: 'error',
          builder: (context, state) => const ErrorPage(),
        ),
      ],
      errorBuilder: (context, state) => ErrorPage(error: state.error),
      redirect: (context, state) {
        // Add your auth logic here
        // For example:
        // if (!AuthService.isLoggedIn && state.location != RouteNames.login) {
        //   return RouteNames.login;
        // }
        return null;
      },
    );
  }
}
