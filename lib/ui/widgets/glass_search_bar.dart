import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../models/models.dart';
import '../fg_icons.dart';
import 'glass_card.dart';

/// Floating glass search bar. The leading icon morphs with the detected
/// input type (mail / user / phone) and the submit orb glows emerald.
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final InputKind kind;
  final S s;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.kind,
    required this.s,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
  });

  IconData get _icon {
    switch (kind) {
      case InputKind.email:
        return FGI.mail;
      case InputKind.phone:
        return FGI.phone;
      case InputKind.username:
        return FGI.atSign;
      case InputKind.unknown:
        return FGI.search;
    }
  }

  String get _kindLabel {
    switch (kind) {
      case InputKind.email:
        return s.inputEmail;
      case InputKind.phone:
        return s.inputPhone;
      case InputKind.username:
        return s.inputUsername;
      case InputKind.unknown:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      fillColor: const Color(0x1AFFFFFF),
      child: Row(
        children: [
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(_icon,
                key: ValueKey(kind), size: 19, color: FGColors.emerald),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: FGColors.textHi,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: s.searchHint,
                hintStyle:
                    const TextStyle(fontSize: 14, color: FGColors.textLow),
              ),
            ),
          ),
          if (_kindLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlassChip(label: _kindLabel, color: FGColors.emeraldDim),
            ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: busy ? null : onSubmit,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [FGColors.emerald, FGColors.emeraldDim],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FGColors.emerald.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(FGI.crosshair, size: 19, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
