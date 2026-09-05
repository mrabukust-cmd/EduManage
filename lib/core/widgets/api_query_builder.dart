import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_empty_state.dart';
import 'app_error_state.dart';
import 'loading_widget.dart';

/// Standard widget to bind an AsyncValue from API providers to UI with
/// loading, error, empty states, and optional pull-to-refresh.
class ApiQueryBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final String? loadingMessage;

  const ApiQueryBuilder({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.onRefresh,
    this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'No data available',
    this.emptySubtitle,
    this.emptyIcon = Icons.inbox_outlined,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          final emptyWidget = AppEmptyState(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: emptyIcon,
            actionLabel: onRetry != null ? 'Refresh' : null,
            onAction: onRetry,
          );
          if (onRefresh != null) {
            return RefreshIndicator(
              onRefresh: onRefresh!,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: emptyWidget,
                ),
              ),
            );
          }
          return emptyWidget;
        }

        final content = builder(context, data);
        if (onRefresh != null) {
          return RefreshIndicator(
            onRefresh: onRefresh!,
            child: content,
          );
        }
        return content;
      },
      loading: () => LoadingWidget(message: loadingMessage),
      error: (err, stack) {
        final errorWidget = AppErrorState(
          title: 'Failed to load data',
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: onRetry,
        );
        if (onRefresh != null) {
          return RefreshIndicator(
            onRefresh: onRefresh!,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: errorWidget,
              ),
            ),
          );
        }
        return errorWidget;
      },
    );
  }
}
