import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/ticket_model.dart';
import '../responsive_layout.dart';
import 'admin_e_ticket_dialog.dart';

class AdminDirectoryTab extends StatefulWidget {
  final List<TicketModel> allTickets;

  const AdminDirectoryTab({
    super.key,
    required this.allTickets,
  });

  @override
  State<AdminDirectoryTab> createState() => _AdminDirectoryTabState();
}

class _AdminDirectoryTabState extends State<AdminDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = widget.allTickets.where((t) {
      bool matchesQuery = _searchQuery.isEmpty ||
          t.passengerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.passengerPhone.contains(_searchQuery) ||
          t.trxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.ticketId ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = _statusFilter == 'ALL' || t.status == _statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        maxWidth: 1250,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header & Search Control Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'টিকিট ডিরেক্টরি (Ticket Directory)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'যাত্রীর নাম, ফোন নম্বর, TrxID বা টিকিট আইডি দিয়ে সহজেই সার্চ করুন',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'মোট ${filteredTickets.length} টি ফলাফল',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Search Input Field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'যাত্রীর নাম, মোবাইল নম্বর বা TrxID দিয়ে খুঁজুন...',
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.primaryRed),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Status Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('সবগুলো (ALL)', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('পেন্ডিং (PENDING)', 'PENDING'),
                        const SizedBox(width: 8),
                        _buildFilterChip('অনুমোদিত (CONFIRMED)', 'CONFIRMED'),
                        const SizedBox(width: 8),
                        _buildFilterChip('বাতিল (REJECTED)', 'REJECTED'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Filtered Tickets Results Container
            filteredTickets.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'কোনো টিকিট খুঁজে পাওয়া যায়নি'
                          : 'কোনো ডাটা পাওয়া যায়নি',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14.5),
                    ),
                  )
                : (isDesktop
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTickets.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 185,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          final ticket = filteredTickets[index];
                          return _buildDirectoryCard(ticket);
                        },
                      )
                    : Column(
                        children: List.generate(filteredTickets.length, (index) {
                          final ticket = filteredTickets[index];
                          return _buildDirectoryCard(ticket);
                        }),
                      )),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryCard(TicketModel ticket) {
    final bool isConfirmed = ticket.status == 'CONFIRMED';
    final bool isPending = ticket.status == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isConfirmed
              ? AppColors.primaryGreen.withAlpha(60)
              : (isPending
                  ? Colors.orange.shade300
                  : AppColors.primaryRed.withAlpha(60)),
          width: 1.2,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${ticket.ticketId ?? "TKT"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryRed,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppColors.primaryGreen.withAlpha(20)
                        : (isPending
                            ? Colors.orange.shade100
                            : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isConfirmed
                          ? AppColors.primaryGreen
                          : (isPending
                              ? Colors.orange.shade900
                              : AppColors.primaryRed),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${ticket.passengerName} (${ticket.passengerPhone})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            Text(
              '${ticket.busName} • সিট: ${ticket.selectedSeats.join(", ")}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'তারিখ: ${ticket.journeyDate} • ৳ ${ticket.totalAmount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('ই-টিকিট ভিউ',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                  ),
                  onPressed: () => AdminETicketDialog.show(context, ticket),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _statusFilter == value;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryRed,
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = value;
          });
        }
      },
    );
  }
}
