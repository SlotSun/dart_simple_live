import 'package:material_ui/material_ui.dart';

Widget customContextMenuBuilder(
  BuildContext context,
  EditableTextState state,
  Map<String, void Function(String)?> menuActions,
) {
  var buttonItems = state.contextMenuButtonItems;
  final value = state.textEditingValue;
  final selectedText = value.selection.textInside(value.text);
  final selection = state.textEditingValue.selection;
  for (final entry in menuActions.entries) {
    final action = entry.value;
    if (action == null) continue;
    buttonItems.add(
      ContextMenuButtonItem(
        label: entry.key,
        onPressed: () {
          action(selectedText);
          state.hideToolbar();
          state.userUpdateTextEditingValue(
            state.textEditingValue.copyWith(
              selection: TextSelection.collapsed(offset: selection.end),
            ),
            SelectionChangedCause.toolbar,
          );
        },
      ),
    );
  }

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}
