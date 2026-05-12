import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int pages;
  final void Function(int page) onPageSelected;

  const PaginationBar({
    super.key,
    required this.page,
    required this.pages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox.shrink();

    final items = _buildPageItems(page, pages);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _navButton(
            label: 'Previous',
            enabled: page > 1,
            onTap: () => onPageSelected(page - 1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items) ...[
                    if (item is int)
                      _pageButton(context, item, selected: item == page)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          item.toString(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _navButton(
            label: 'Next',
            enabled: page < pages,
            onTap: () => onPageSelected(page + 1),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageButton(BuildContext context, int p, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onPageSelected(p),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : AppColors.border.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            p.toString(),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  List<Object> _buildPageItems(int current, int totalPages) {
    final set = <int>{
      1,
      2,
      3,
      current - 1,
      current,
      current + 1,
      totalPages - 2,
      totalPages - 1,
      totalPages,
    };

    final pages = set
        .where((p) => p >= 1 && p <= totalPages)
        .toList()
      ..sort();

    final out = <Object>[];
    int? prev;
    for (final p in pages) {
      if (prev != null && p - prev > 1) {
        out.add('…');
      }
      out.add(p);
      prev = p;
    }
    return out;
  }
}
