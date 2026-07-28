import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ExpressionPanel extends StatefulWidget {
  final TextEditingController controller;

  const ExpressionPanel({
    super.key,
    required this.controller,
  });

  @override
  State<ExpressionPanel> createState() => _ExpressionPanelState();
}

class _ExpressionPanelState extends State<ExpressionPanel> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _tab(
                    icon: Icons.sentiment_satisfied_alt_outlined,
                    index: 0,
                  ),
                  _tabText(
                    text: "GIF",
                    index: 1,
                  ),
                  _tab(
                    icon: Icons.sticky_note_2_outlined,
                    index: 2,
                  ),
                ],
              )),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                EmojiPicker(
                  textEditingController: widget.controller,
                  config: const Config(),
                ),
                const Center(
                  child: Text(
                    "GIFs coming soon",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Stickers coming soon",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required IconData icon,
    required int index,
  }) {
    final selected = selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        width: 64,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 26 : 0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabText({
    required String text,
    required int index,
  }) {
    final selected = selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        width: 70,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 28 : 0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
