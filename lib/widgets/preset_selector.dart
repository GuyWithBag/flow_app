import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/ad_service.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class PresetSelector extends HookWidget {
  const PresetSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final presetProvider = Provider.of<PresetProvider>(context);
    final accentColor = Theme.of(context).colorScheme.primary;
    final adService = context.read<AdService>();
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final isActive = useState<bool>(false);

    return InkWell(
      onTap: () {
        _showPresetSelector(context, presetProvider, timerProvider, isActive);
        if (!context.read<PurchaseProvider>().isNoAds) {
          adService.maybeShowInterstitial(id: 'presets', frequency: 4);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              presetProvider.selectedPreset.name,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              !isActive.value ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 20,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetSelector(
    BuildContext context,
    PresetProvider presetProvider,
    TimerProvider timerProvider,
    ValueNotifier<bool> isActive,
  ) {
    isActive.value = !isActive.value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PresetSelectorMenu(
                  presetProvider: presetProvider,
                  timerProvider: timerProvider,
                  showAddButton: true,
                  onPresetSelected: () => Navigator.pop(context),
                  scrollController: scrollController,
                  showTitleAndHandle: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
