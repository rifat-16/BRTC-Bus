import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/ticket_model.dart';
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

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'যাত্রীর নাম, মোবাইল নম্বর বা TrxID দিয়ে খুঁজুন...',
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
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter Chips
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

          const SizedBox(height: 14),

          // Ticket List
          Expanded(
            child: filteredTickets.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'কোনো টিকিট খুঁজে পাওয়া যায়নি'
                          : 'কোনো ডাটা পাওয়া যায়নি',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      final bool isConfirmed = ticket.status == 'CONFIRMED';
                      final bool isPending = ticket.status == 'PENDING';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isConfirmed
                                          ? AppColors.primaryGreen.withAlpha(20)
                                          : (isPending
                                              ? Colors.orange.shade100
                                              : Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(8),
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
                              const SizedBox(height: 8),
                              Text(
                                '${ticket.passengerName} (${ticket.passengerPhone})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ticket.busName} • সিট: ${ticket.selectedSeats.join(", ")}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'তারিখ: ${ticket.journeyDate} • ৳ ${ticket.totalAmount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 16),
                                    label: const Text('ই-টিকিট ভিউ',
                                        style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryGreen,
                                    ),
                                    onPressed: () => AdminETicketDialog.show(
                                        context, ticket),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
      backgroundColor: Colors.white,
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
