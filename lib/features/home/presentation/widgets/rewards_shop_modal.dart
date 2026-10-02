import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../rewards/domain/entities/reward_item.dart';
import '../../../subjects/presentation/bloc/subjects_bloc.dart';
import '../../../subjects/presentation/bloc/subjects_event.dart';
import '../../../subjects/presentation/bloc/subjects_state.dart';

class RewardsShopModal extends StatefulWidget {
  const RewardsShopModal({super.key});

  static void show(BuildContext context) {
    try {
      AnalyticsService.capture('reward_shop_opened');
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const RewardsShopModal(),
    );
  }

  @override
  State<RewardsShopModal> createState() => _RewardsShopModalState();
}

class _RewardsShopModalState extends State<RewardsShopModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        final coins = state.coins;
        final unlockedIds = state.unlockedRewardIds;
        final activeBadgeId = state.activeBadgeId;
        final activeThemeId = state.activeThemeId;

        final themeRewards = RewardItem.catalog
            .where((r) => r.category == RewardCategory.theme)
            .toList();
        final badgeRewards = RewardItem.catalog
            .where((r) => r.category == RewardCategory.badge)
            .toList();
        final aiRewards = RewardItem.catalog
            .where((r) => r.category == RewardCategory.aiCredit)
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151433) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Pull Handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Shop Header & Coin balance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD043).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🛍️', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rewards Shop',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),
                          Text(
                            'Unlock themes, badges & AI credits',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    // Coins Display Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD043).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '$coins',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: const Color(0xFFFFD043),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: const [
                  Tab(text: 'Themes 🎨'),
                  Tab(text: 'Badges 🏅'),
                  Tab(text: 'AI Credits ⚡'),
                ],
              ),
              const Divider(height: 1),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRewardList(
                      context,
                      themeRewards,
                      unlockedIds,
                      coins,
                      isDark,
                      activeId: activeThemeId,
                      onEquip: (id) {
                        context.read<SubjectsBloc>().add(
                            SelectActiveThemeEvent(
                                activeThemeId == id ? null : id));
                      },
                    ),
                    _buildRewardList(
                      context,
                      badgeRewards,
                      unlockedIds,
                      coins,
                      isDark,
                      activeId: activeBadgeId,
                      onEquip: (id) {
                        context.read<SubjectsBloc>().add(
                            SelectActiveBadgeEvent(
                                activeBadgeId == id ? null : id));
                      },
                    ),
                    _buildRewardList(
                      context,
                      aiRewards,
                      unlockedIds,
                      coins,
                      isDark,
                      onEquip: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardList(
    BuildContext context,
    List<RewardItem> items,
    List<String> unlockedIds,
    int coins,
    bool isDark, {
    String? activeId,
    Function(String)? onEquip,
  }) {
    final themePrimary = Theme.of(context).primaryColor;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnlocked = unlockedIds.contains(item.id);
        final isActive = activeId == item.id;
        final canAfford = coins >= item.cost;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBg
                : AppColors.lightCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? themePrimary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isActive ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (item.color ?? themePrimary)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Desc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: themePrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Equipped',
                              style: TextStyle(
                                color: themePrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Button
              if (isUnlocked) ...[
                if (onEquip != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive
                          ? Colors.grey
                          : themePrimary,
                      side: BorderSide(
                        color: isActive
                            ? Colors.grey.withValues(alpha: 0.5)
                            : themePrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => onEquip(item.id),
                    child: Text(isActive ? 'Unequip' : 'Equip'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.subjectGreen.withValues(alpha: 0.2),
                      foregroundColor: AppColors.subjectGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      context.read<SubjectsBloc>().add(
                            UnlockRewardEvent(
                                rewardId: item.id, cost: item.cost),
                          );
                      AppSnackbar.show(
                        context,
                        type: SnackbarType.success,
                        title: 'Bonus Applied!',
                        message: 'Granted ${item.title}',
                      );
                    },
                    child: const Text('Use Credit'),
                  )
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? themePrimary
                        : (isDark ? Colors.grey[800] : Colors.grey[300]),
                    foregroundColor: canAfford ? Colors.white : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: canAfford
                      ? () {
                          context.read<SubjectsBloc>().add(
                                UnlockRewardEvent(
                                    rewardId: item.id, cost: item.cost),
                              );
                          AppSnackbar.show(
                            context,
                            type: SnackbarType.success,
                            title: 'Reward Unlocked! 🎉',
                            message: 'You unlocked ${item.title}!',
                          );
                        }
                      : () {
                          AppSnackbar.show(
                            context,
                            type: SnackbarType.warning,
                            title: 'Not Enough Coins',
                            message:
                                'Complete daily sessions to earn more coins!',
                          );
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙 ', style: TextStyle(fontSize: 12)),
                      Text(
                        '${item.cost}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
