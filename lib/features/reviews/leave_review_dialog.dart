import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../repositories/bookings_repository.dart';
import '../../repositories/trust_repository.dart';
import '../../theme/app_theme.dart';

class LeaveReviewDialog extends ConsumerStatefulWidget {
  const LeaveReviewDialog({
    super.key,
    required this.bookingId,
    required this.companionName,
  });

  final String bookingId;
  final String companionName;

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    required String companionName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LeaveReviewDialog(
        bookingId: bookingId,
        companionName: companionName,
      ),
    );
  }

  @override
  ConsumerState<LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends ConsumerState<LeaveReviewDialog> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  final List<String> _tags = [
    'Punctual ⏰',
    'Polite & Respectful 🤝',
    'Great Conversation 💬',
    'Helpful Guide 🗺️',
    'Felt Very Safe 🛡️',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);

    String finalComment = _commentCtrl.text.trim();
    if (_selectedTags.isNotEmpty) {
      final tagsStr = _selectedTags.join(', ');
      finalComment = finalComment.isNotEmpty ? '$tagsStr\n\n$finalComment' : tagsStr;
    }

    try {
      await ref.read(trustRepositoryProvider).submitReview(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: finalComment.isNotEmpty ? finalComment : null,
          );

      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Review submitted! Thank you for supporting the Saathira community.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              Text(
                'Rate your experience with ${widget.companionName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your honest feedback helps maintain safety and quality across Saathira.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 20),

              // Star Rating Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _rating = starNum),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Highlight Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    backgroundColor: AppColors.bg,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Comment Box
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share more about your experience...',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('btn_submit_review'),
                      onPressed: _submitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
