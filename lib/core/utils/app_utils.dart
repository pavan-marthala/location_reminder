import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:reminders/core/theme/app_theme.dart';
import 'package:reminders/core/utils/app_button.dart';
// import 'package:lottie/lottie.dart';

/// Bump version suffix if legal text changes materially and you need to re-prompt.
const kLegalConsentAcceptedKey = 'legal_consent_accepted_v1';

String formatTimeOfDay(String time24) {
  try {
    final date = DateFormat("HH:mm:ss").parse(time24);
    return DateFormat("h:mm a").format(date);
  } catch (e) {
    return time24;
  }
}

String formatDate(String date) {
  try {
    final d = DateTime.parse(date);
    return DateFormat("MMM dd").format(d);
  } catch (e) {
    return date;
  }
}

/// Converts time format HH:MM:SS to decimal hours
double durationToHours(String hhmmss) {
  final parts = hhmmss.split(':').map(int.parse).toList();
  return parts[0] + (parts[1] / 60) + (parts[2] / 3600);
}

// Future<LottieComposition?> customDecoder(List<int> bytes) {
//   return LottieComposition.decodeZip(
//     bytes,
//     filePicker: (files) {
//       return files.firstWhereOrNull(
//         (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
//       );
//     },
//   );
// }

void showDeleteDialog(
  BuildContext context,
  String deleteFor,
  Function() onYesPressed,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (popContext) {
      final colors = context.theme.appColors;
      return Dialog(
        constraints: BoxConstraints(maxWidth: 500),
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border, width: 1),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: ShapeDecoration(
                        color: colors.card,
                        shape: OvalBorder(),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: colors.textPrimary),
                    ),
                  ),
                ),
                // Lottie.asset(
                //   "Assets.lottieDelete",
                //   decoder: customDecoder,
                //   height: 130,
                //   width: 130,
                // ),
                Text(
                  "Are you sure you want to delete this $deleteFor?",
                  style: context.theme.appTypography.labelLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 16,
                  children: [
                    Expanded(
                      child: AppButton(
                        text: "Yes",
                        color: colors.error,
                        onPressed: onYesPressed,
                      ),
                    ),
                    Expanded(
                      child: AppButton(
                        text: "Cancel",
                        color: colors.primary,
                        onPressed: () {
                          context.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
