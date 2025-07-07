import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/badge.dart';
import '../services/hive_service.dart';
import '../services/encryption_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class BadgeRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;

  BadgeRepository({
    HiveService? hiveService,
    EncryptionService? encryptionService,
  }) {
    _hiveService = hiveService ?? HiveService();
  }

  // Get badges box
  Future<Box<Badge>> get _badgesBox async {
    return await _hiveService.getBox<Badge>(AppConstants.hiveBoxBadges);
  }

  // Add badge
  Future<String> addBadge(Badge badge) async {
    try {
      final box = await _badgesBox;
      final id = badge.id.isEmpty ? _uuid.v4() : badge.id;
      final now = DateTime.now();

      final newBadge = badge.copyWith(
        id: id,
        createdAt: badge.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : badge.createdAt,
      );

      await box.put(id, newBadge);
      return id;
    } catch (e) {
      throw DatabaseException(message: 'Failed to add badge: $e');
    }
  }

  // Get all badges
  Future<List<Badge>> getAllBadges() async {
    try {
      final box = await _badgesBox;
      return box.values.toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get badges: $e');
    }
  }

  // Get badge by ID
  Future<Badge?> getBadgeById(String id) async {
    try {
      final box = await _badgesBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get badge by ID: $e');
    }
  }

  // Update badge
  Future<void> updateBadge(Badge badge) async {
    try {
      final box = await _badgesBox;
      final existingBadge = box.get(badge.id);

      if (existingBadge == null) {
        throw DatabaseException(message: 'Badge not found');
      }

      await box.put(badge.id, badge);
    } catch (e) {
      throw DatabaseException(message: 'Failed to update badge: $e');
    }
  }

  // Delete badge
  Future<void> deleteBadge(String id) async {
    try {
      final box = await _badgesBox;
      await box.delete(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete badge: $e');
    }
  }

  // Get earned badges
  Future<List<Badge>> getEarnedBadges() async {
    try {
      final allBadges = await getAllBadges();
      return allBadges.where((badge) => badge.isEarned).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get earned badges: $e');
    }
  }

  // Get unearned badges
  Future<List<Badge>> getUnearnedBadges() async {
    try {
      final allBadges = await getAllBadges();
      return allBadges.where((badge) => !badge.isEarned).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get unearned badges: $e');
    }
  }

  // Get badges by category
  Future<List<Badge>> getBadgesByCategory(BadgeCategory category) async {
    try {
      final allBadges = await getAllBadges();
      return allBadges.where((badge) => badge.category == category).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get badges by category: $e');
    }
  }

  // Get badges by type
  Future<List<Badge>> getBadgesByType(BadgeType type) async {
    try {
      final allBadges = await getAllBadges();
      return allBadges.where((badge) => badge.type == type).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get badges by type: $e');
    }
  }

  // Get visible badges (not hidden)
  Future<List<Badge>> getVisibleBadges() async {
    try {
      final allBadges = await getAllBadges();
      return allBadges.where((badge) => !badge.isHidden).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get visible badges: $e');
    }
  }

  // Get badges with progress
  Future<List<Badge>> getBadgesWithProgress() async {
    try {
      final allBadges = await getAllBadges();
      return allBadges
          .where((badge) =>
              badge.targetValue != null &&
              badge.currentValue != null &&
              badge.currentValue! > 0 &&
              !badge.isEarned)
          .toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get badges with progress: $e');
    }
  }

  // Update badge progress
  Future<void> updateBadgeProgress(String badgeId, double newValue) async {
    try {
      final badge = await getBadgeById(badgeId);
      if (badge == null) {
        throw DatabaseException(message: 'Badge not found');
      }

      final updatedBadge = badge.copyWith(
        currentValue: newValue,
      );

      // Check if badge should be awarded
      if (badge.targetValue != null &&
          newValue >= badge.targetValue! &&
          !badge.isEarned) {
        await awardBadge(badgeId);
      } else {
        await updateBadge(updatedBadge);
      }
    } catch (e) {
      throw DatabaseException(message: 'Failed to update badge progress: $e');
    }
  }

  // Award badge (mark as earned)
  Future<void> awardBadge(String badgeId) async {
    try {
      final badge = await getBadgeById(badgeId);
      if (badge == null) {
        throw DatabaseException(message: 'Badge not found');
      }

      final awardedBadge = badge.copyWith(
        isEarned: true,
        earnedAt: DateTime.now(),
        currentValue: badge.targetValue, // Set current to target when earned
      );

      await updateBadge(awardedBadge);
    } catch (e) {
      throw DatabaseException(message: 'Failed to award badge: $e');
    }
  }

  // Revoke badge (mark as not earned)
  Future<void> revokeBadge(String badgeId) async {
    try {
      final badge = await getBadgeById(badgeId);
      if (badge == null) {
        throw DatabaseException(message: 'Badge not found');
      }

      final revokedBadge = badge.copyWith(
        isEarned: false,
        earnedAt: null,
      );

      await updateBadge(revokedBadge);
    } catch (e) {
      throw DatabaseException(message: 'Failed to revoke badge: $e');
    }
  }

  // Get recent badges (recently earned)
  Future<List<Badge>> getRecentBadges({int limit = 10}) async {
    try {
      final earnedBadges = await getEarnedBadges();
      earnedBadges.sort((a, b) => (b.earnedAt ?? DateTime.now())
          .compareTo(a.earnedAt ?? DateTime.now()));
      return earnedBadges.take(limit).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get recent badges: $e');
    }
  }

  // Get total points
  Future<int> getTotalPoints() async {
    try {
      final earnedBadges = await getEarnedBadges();
      return earnedBadges.fold<int>(0, (sum, badge) => sum + badge.points);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get total points: $e');
    }
  }

  // Get badges count
  Future<int> getBadgesCount() async {
    try {
      final box = await _badgesBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get badges count: $e');
    }
  }

  // Get earned badges count
  Future<int> getEarnedBadgesCount() async {
    try {
      final earnedBadges = await getEarnedBadges();
      return earnedBadges.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get earned badges count: $e');
    }
  }

  // Clear all badges
  Future<void> clearAllBadges() async {
    try {
      final box = await _badgesBox;
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear badges: $e');
    }
  }

  // Initialize default badges
  Future<void> initializeDefaultBadges() async {
    try {
      final existingCount = await getBadgesCount();
      if (existingCount > 0) {
        return; // Already initialized
      }

      final defaultBadges = _getDefaultBadges();
      await addBadgesBatch(defaultBadges);
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to initialize default badges: $e');
    }
  }

  // Batch operations
  Future<void> addBadgesBatch(List<Badge> badges) async {
    try {
      final box = await _badgesBox;
      final badgesMap = <String, Badge>{};

      for (final badge in badges) {
        final id = badge.id.isEmpty ? _uuid.v4() : badge.id;
        final now = DateTime.now();

        final newBadge = badge.copyWith(
          id: id,
          createdAt: badge.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
              ? now
              : badge.createdAt,
        );

        badgesMap[id] = newBadge;
      }

      await box.putAll(badgesMap);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add badges batch: $e');
    }
  }

  // Get default badges
  List<Badge> _getDefaultBadges() {
    final now = DateTime.now();

    return [
      // First steps badges
      Badge(
        id: '',
        name: 'First Step',
        description: 'Add your first transaction',
        iconName: 'first_step',
        color: 0xFF4CAF50,
        type: BadgeType.achievement,
        category: BadgeCategory.exploration,
        targetValue: 1,
        currentValue: 0,
        unit: 'transactions',
        difficulty: 1,
        points: 10,
        createdAt: now,
      ),
      Badge(
        id: '',
        name: 'Getting Started',
        description: 'Create your first budget',
        iconName: 'budget_start',
        color: 0xFF2196F3,
        type: BadgeType.achievement,
        category: BadgeCategory.budgeting,
        targetValue: 1,
        currentValue: 0,
        unit: 'budgets',
        difficulty: 1,
        points: 15,
        createdAt: now,
      ),
      Badge(
        id: '',
        name: 'Goal Setter',
        description: 'Set your first savings goal',
        iconName: 'goal_setter',
        color: 0xFFFF9800,
        type: BadgeType.achievement,
        category: BadgeCategory.goals,
        targetValue: 1,
        currentValue: 0,
        unit: 'goals',
        difficulty: 1,
        points: 20,
        createdAt: now,
      ),

      // Transaction milestones
      Badge(
        id: '',
        name: 'Transaction Tracker',
        description: 'Record 10 transactions',
        iconName: 'transaction_tracker',
        color: 0xFF9C27B0,
        type: BadgeType.milestone,
        category: BadgeCategory.transactions,
        targetValue: 10,
        currentValue: 0,
        unit: 'transactions',
        difficulty: 2,
        points: 25,
        createdAt: now,
      ),
      Badge(
        id: '',
        name: 'Money Manager',
        description: 'Record 100 transactions',
        iconName: 'money_manager',
        color: 0xFF673AB7,
        type: BadgeType.milestone,
        category: BadgeCategory.transactions,
        targetValue: 100,
        currentValue: 0,
        unit: 'transactions',
        difficulty: 3,
        points: 50,
        createdAt: now,
      ),

      // Savings badges
      Badge(
        id: '',
        name: 'Saver',
        description: 'Save \$100',
        iconName: 'saver',
        color: 0xFF4CAF50,
        type: BadgeType.milestone,
        category: BadgeCategory.savings,
        targetValue: 100,
        currentValue: 0,
        unit: 'dollars',
        difficulty: 2,
        points: 30,
        createdAt: now,
      ),
      Badge(
        id: '',
        name: 'Super Saver',
        description: 'Save \$1,000',
        iconName: 'super_saver',
        color: 0xFF388E3C,
        type: BadgeType.milestone,
        category: BadgeCategory.savings,
        targetValue: 1000,
        currentValue: 0,
        unit: 'dollars',
        difficulty: 4,
        points: 100,
        createdAt: now,
      ),

      // Consistency badges
      Badge(
        id: '',
        name: 'Week Warrior',
        description: 'Track expenses for 7 consecutive days',
        iconName: 'week_warrior',
        color: 0xFFFF5722,
        type: BadgeType.streak,
        category: BadgeCategory.consistency,
        targetValue: 7,
        currentValue: 0,
        unit: 'days',
        difficulty: 2,
        points: 35,
        createdAt: now,
      ),
      Badge(
        id: '',
        name: 'Month Master',
        description: 'Track expenses for 30 consecutive days',
        iconName: 'month_master',
        color: 0xFFE91E63,
        type: BadgeType.streak,
        category: BadgeCategory.consistency,
        targetValue: 30,
        currentValue: 0,
        unit: 'days',
        difficulty: 4,
        points: 75,
        createdAt: now,
      ),

      // Budget badges
      Badge(
        id: '',
        name: 'Budget Boss',
        description: 'Stay under budget for a month',
        iconName: 'budget_boss',
        color: 0xFF3F51B5,
        type: BadgeType.achievement,
        category: BadgeCategory.budgeting,
        targetValue: 1,
        currentValue: 0,
        unit: 'months',
        difficulty: 3,
        points: 40,
        createdAt: now,
      ),
    ];
  }
}
