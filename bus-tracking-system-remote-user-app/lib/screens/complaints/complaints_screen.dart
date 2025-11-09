// lib/screens/complaints/complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/complaints_bloc.dart';
import '../../theme/app_theme.dart';

// هذا الكلاس يبقى كما هو، مسؤول عن توفير الـ BLoC
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ComplaintsBloc(),
      child: const ComplaintsView(),
    );
  }
}

// هذا الكلاس يبقى كما هو، مسؤول عن إنشاء الحالة
class ComplaintsView extends StatefulWidget {
  const ComplaintsView({super.key});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

// --- هنا قمنا بإعادة كتابة وتصحيح كل شيء ---
class _ComplaintsViewState extends State<ComplaintsView> {
  // كل المتغيرات والدوال الأصلية تبقى كما هي
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _busInfoController = TextEditingController();
  final _contactInfoController = TextEditingController();

  String? _selectedComplaintType;

  final List<String> _complaintTypes = [
    'سلوك السائق',
    'تأخر الحافلة',
    'نظافة الحافلة',
    'قيادة متهورة',
    'مشكلة في مسار الخط',
    'أخرى',
  ];

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ComplaintsBloc>().add(
      ComplaintSubmitted(
        type: _selectedComplaintType!,
        details: _detailsController.text,
        busInfo: _busInfoController.text,
        contactInfo: _contactInfoController.text,
      ),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _busInfoController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener يبقى في الخارج للتعامل مع الأحداث
    return BlocListener<ComplaintsBloc, ComplaintsState>(
      listener: (context, state) {
        if (state is ComplaintSubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('شكرًا لك، تم استلام ملاحظتك بنجاح.'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
        if (state is ComplaintSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // الـ AppBar الديناميكي مع التصميم الجديد
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 120.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'تقديم شكوى',
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

            // محتوى النموذج
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // كل حقول النموذج مع التصميم الجديد
                      DropdownButtonFormField<String>(
                        initialValue: _selectedComplaintType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          labelText: 'اختر نوع الشكوى',
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: _complaintTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedComplaintType = value),
                        validator: (value) =>
                            value == null ? 'الرجاء اختيار نوع الشكوى' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _detailsController,
                        decoration: InputDecoration(
                          labelText: 'تفاصيل الشكوى',
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'الرجاء وصف المشكلة بالتفصيل...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        style: AppTextStyles.bodyMedium,
                        maxLines: 5,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'هذا الحقل مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _busInfoController,
                        decoration: InputDecoration(
                          labelText: 'معلومات الحافلة / الخط (اختياري)',
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'مثال: خط الجامعة، حافلة رقم 5',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactInfoController,
                        decoration: InputDecoration(
                          labelText: 'معلومات التواصل (اختياري)',
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'رقم هاتف أو بريد إلكتروني',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppBorders.medium,
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<ComplaintsBloc, ComplaintsState>(
                        builder: (context, state) {
                          if (state is ComplaintSubmissionInProgress) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          return ElevatedButton.icon(
                            onPressed: _submitComplaint,
                            icon: const Icon(Icons.send),
                            label: Text('إرسال', style: AppTextStyles.button),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppBorders.medium,
                              ),
                              elevation: 2,
                              shadowColor: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

