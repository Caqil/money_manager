import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/badge.dart';
import '../../data/repositories/badge_repository.dart';

// Repository provider
final badgeRepositoryProvider = Provider<BadgeRepository>(
  (ref) => BadgeRepository(),
);

// Badge list provider
final badgeListProvider =
    StateNotifierProvider<BadgeNotifier, AsyncValue<List<Badge>>>(
  (ref) => BadgeNotifier(ref.read(badgeRepositoryProvider)),
);

// Earned badges provider
final earnedBadgesProvider = Provider<AsyncValue<List<Badge>>>(
  (ref) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) =>
          AsyncValue.data(list.where((badge) => badge.isEarned).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Unearned badges provider
final unearnedBadgesProvider = Provider<AsyncValue<List<Badge>>>(
  (ref) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) =>
          AsyncValue.data(list.where((badge) => !badge.isEarned).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Visible badges provider (not hidden)
final visibleBadgesProvider = Provider<AsyncValue<List<Badge>>>(
  (ref) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) =>
          AsyncValue.data(list.where((badge) => !badge.isHidden).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Badges by category provider
final badgesByCategoryProvider =
    Provider.family<AsyncValue<List<Badge>>, BadgeCategory>(
  (ref, category) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) => AsyncValue.data(
          list.where((badge) => badge.category == category).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Badges by type provider
final badgesByTypeProvider =
    Provider.family<AsyncValue<List<Badge>>, BadgeType>(
  (ref, type) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) =>
          AsyncValue.data(list.where((badge) => badge.type == type).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Single badge provider
final badgeProvider = Provider.family<AsyncValue<Badge?>, String>(
  (ref, badgeId) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) {
        try {
          final badge = list.firstWhere((badge) => badge.id == badgeId);
          return AsyncValue.data(badge);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Recent badges provider
final recentBadgesProvider = Provider.family<AsyncValue<List<Badge>>, int>(
  (ref, limit) {
    final earnedBadges = ref.watch(earnedBadgesProvider);
    return earnedBadges.when(
      data: (list) {
        final sortedList = List<Badge>.from(list);
        sortedList.sort((a, b) => (b.earnedAt ?? DateTime.now())
            .compareTo(a.earnedAt ?? DateTime.now()));
        return AsyncValue.data(sortedList.take(limit).toList());
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Badge progress provider (in progress badges with progress > 0)
final inProgressBadgesProvider = Provider<AsyncValue<List<Badge>>>(
  (ref) {
    final badges = ref.watch(unearnedBadgesProvider);
    return badges.when(
      data: (list) => AsyncValue.data(list
          .where((badge) =>
              badge.targetValue != null &&
              badge.currentValue != null &&
              badge.currentValue! > 0)
          .toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Badge statistics provider
final badgeStatsProvider = Provider<AsyncValue<BadgeStats>>(
  (ref) {
    final badges = ref.watch(badgeListProvider);
    return badges.when(
      data: (list) {
        final earnedBadges = list.where((b) => b.isEarned).toList();
        final totalPoints =
            earnedBadges.fold<int>(0, (sum, b) => sum + b.points);
        final avgDifficulty = earnedBadges.isNotEmpty
            ? earnedBadges.fold<double>(0, (sum, b) => sum + b.difficulty) /
                earnedBadges.length
            : 0.0;

        return AsyncValue.data(BadgeStats(
          totalBadges: list.length,
          earnedBadges: earnedBadges.length,
          totalPoints: totalPoints,
          averageDifficulty: avgDifficulty,
          completionRate:
              list.isNotEmpty ? earnedBadges.length / list.length : 0.0,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Badge operations state
class BadgeNotifier extends StateNotifier<AsyncValue<List<Badge>>> {
  final BadgeRepository _repository;

  BadgeNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBadges();
  }

  // Load all badges
  Future<void> loadBadges() async {
    try {
      state = const AsyncValue.loading();
      final badges = await _repository.getAllBadges();
      state = AsyncValue.data(badges);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Initialize default badges
  Future<void> initializeDefaultBadges() async {
    try {
      await _repository.initializeDefaultBadges();
      await loadBadges(); // Refresh list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add badge
  Future<String?> addBadge(Badge badge) async {
    try {
      final id = await _repository.addBadge(badge);
      await loadBadges(); // Refresh list
      return id;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Update badge
  Future<bool> updateBadge(Badge badge) async {
    try {
      await _repository.updateBadge(badge);
      await loadBadges(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Delete badge
  Future<bool> deleteBadge(String id) async {
    try {
      await _repository.deleteBadge(id);
      await loadBadges(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Update badge progress
  Future<bool> updateBadgeProgress(String badgeId, double newValue) async {
    try {
      await _repository.updateBadgeProgress(badgeId, newValue);
      await loadBadges(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Award badge (mark as earned)
  Future<bool> awardBadge(String badgeId) async {
    try {
      await _repository.awardBadge(badgeId);
      await loadBadges(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Revoke badge (mark as not earned)
  Future<bool> revokeBadge(String badgeId) async {
    try {
      await _repository.revokeBadge(badgeId);
      await loadBadges(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Refresh badges
  Future<void> refresh() async {
    await loadBadges();
  }
}

// Badge statistics data class
class BadgeStats {
  final int totalBadges;
  final int earnedBadges;
  final int totalPoints;
  final double averageDifficulty;
  final double completionRate;

  const BadgeStats({
    required this.totalBadges,
    required this.earnedBadges,
    required this.totalPoints,
    required this.averageDifficulty,
    required this.completionRate,
  });

  int get unearnedBadges => totalBadges - earnedBadges;

  String get completionPercentage =>
      '${(completionRate * 100).toStringAsFixed(1)}%';
}
