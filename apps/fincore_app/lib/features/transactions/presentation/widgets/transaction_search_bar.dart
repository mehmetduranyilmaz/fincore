import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TransactionSearchBar extends ConsumerStatefulWidget {
  const TransactionSearchBar({super.key});

  @override
  ConsumerState<TransactionSearchBar> createState() =>
      _TransactionSearchBarState();
}

final class _TransactionSearchBarState
    extends ConsumerState<TransactionSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchText = ref.watch(
      transactionFilterControllerProvider.select((filter) => filter.searchText),
    );
    if (_controller.text != searchText) {
      _controller.value = TextEditingValue(
        text: searchText,
        selection: TextSelection.collapsed(offset: searchText.length),
      );
    }

    return SearchBar(
      controller: _controller,
      hintText: TransactionStrings.search,
      leading: const Icon(Icons.search),
      trailing: [
        if (searchText.isNotEmpty)
          IconButton(
            tooltip: TransactionStrings.clearSearch,
            onPressed: () {
              _controller.clear();
              ref
                  .read(transactionFilterControllerProvider.notifier)
                  .setSearchText('');
            },
            icon: const Icon(Icons.clear),
          ),
      ],
      onChanged: ref
          .read(transactionFilterControllerProvider.notifier)
          .setSearchText,
    );
  }
}
