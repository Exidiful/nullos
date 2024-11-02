import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomCodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  
  CustomCodeBlockBuilder(this.context);
  
  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            element.textContent,
            style: preferredStyle?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Tooltip(
            message: 'Copy code to clipboard',
            child: IconButton(
              icon: Icon(
                Icons.copy,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: element.textContent));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard'))
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
