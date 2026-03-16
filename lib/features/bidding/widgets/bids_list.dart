import 'package:biko/core/models/bid_model.dart';
import 'package:biko/features/bidding/widgets/bid_card.dart';
import 'package:biko/features/bidding/widgets/no_bids_yet.dart';
import 'package:flutter/material.dart';

/// Animated list of incoming driver bids.
///
/// Shows [NoBidsYet] when empty, otherwise renders [BidCard] items.
class BidsList extends StatelessWidget {
  const BidsList({
    required this.bids,
    required this.onAccept,
    required this.onReject,
    this.isAccepting = false,
    super.key,
  });

  final List<BidModel> bids;
  final void Function(BidModel) onAccept;
  final void Function(BidModel) onReject;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return const NoBidsYet();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: bids.length,
      itemBuilder: (context, index) {
        final bid = bids[index];
        return BidCard(
          bid: bid,
          onAccept: () => onAccept(bid),
          onReject: () => onReject(bid),
          isAccepting: isAccepting,
        );
      },
    );
  }
}
