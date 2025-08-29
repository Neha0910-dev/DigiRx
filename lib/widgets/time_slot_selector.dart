import 'package:flutter/material.dart';
import 'package:surebook/shared/constants/app_constants.dart';

class TimeSlotSelector extends StatelessWidget {
  final List<String> timeSlots;
  final List<String> bookedSlots;
  final String? selectedSlot;
  final Function(String) onSlotSelected;
  final String title;

  const TimeSlotSelector({
    super.key,
    required this.timeSlots,
    required this.bookedSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (timeSlots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Wrap(
          spacing: AppConstants.paddingSmall,
          runSpacing: AppConstants.paddingSmall,
          children: timeSlots.map((slot) {
            final isBooked = bookedSlots.contains(slot);
            final isSelected = selectedSlot == slot;
            
            return GestureDetector(
              onTap: isBooked ? null : () => onSlotSelected(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: AppConstants.animationShort),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall + 2,
                ),
                decoration: BoxDecoration(
                  color: isBooked
                      ? colorScheme.surfaceContainer
                      : isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                  border: Border.all(
                    color: isBooked
                        ? colorScheme.outline.withValues(alpha: 0.3)
                        : isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBooked) ...[
                      Icon(
                        Icons.block,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      slot,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isBooked
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}