import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/transport_repository.dart';
import 'bloc/routes_bloc.dart';
import '../../theme/app_theme.dart';

// هذا الجزء يبقى كما هو، مسؤول عن توفير الـ BLoC
class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoutesBloc(repository: context.read<TransportRepository>())
            ..add(LoadRoutes()),
      child: const RoutesView(), // الواجهة الفعلية تأتي من هنا
    );
  }
}

// --- هنا قمنا بتطبيق كل التعديلات على تصميم الواجهة ---
class RoutesView extends StatelessWidget {
  const RoutesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesBloc, RoutesState>(
      builder: (context, state) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 120.0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'خطوط النقل',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16.0),
                ),
                backgroundColor: AppColors.surface,
                elevation: 0.5,
                iconTheme: IconThemeData(color: AppColors.textPrimary),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [AppShadows.small],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // عرض المحتوى بناءً على الحالة
              _buildSliverContent(context, state),
            ],
          ),
        );
      },
    );
  }

  // دالة مساعدة جديدة لعرض المحتوى داخل CustomScrollView
  Widget _buildSliverContent(BuildContext context, RoutesState state) {
    if (state is RoutesInitial) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is RoutesLoadSuccess) {
      final busLines = state.busLines;

      if (busLines.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  'لا توجد خطوط متاحة حاليًا',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final line = busLines[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppBorders.medium,
                boxShadow: AppShadows.card,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppBorders.small,
                  ),
                  child: Icon(Icons.route, color: AppColors.accent, size: 24),
                ),
                title: Text(
                  line.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    line.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                onTap: null, // إلغاء فتح الخريطة
              ),
            );
          }, childCount: busLines.length),
        ),
      );
    }

    if (state is RoutesLoadFailure) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'فشل تحميل الخطوط',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<RoutesBloc>().add(LoadRoutes());
                },
                icon: const Icon(Icons.refresh),
                label: Text('إعادة المحاولة', style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ غير متوقع',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

