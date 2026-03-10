import 'package:flutter/material.dart';
import 'package:car_sync/core/constants/app_colors.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I book a service?',
      'answer':
          'To book a service, go to the Home tab and tap on "Book a Service". Select your vehicle, choose a workshop, pick your preferred date and time, then confirm your booking.',
    },
    {
      'question': 'How can I track my service progress?',
      'answer':
          'Once your service is confirmed, you can track its progress in the Bookings tab. Tap on your active booking to see real-time updates and communicate with the workshop.',
    },
    {
      'question': 'How do I add a new vehicle?',
      'answer':
          'Go to the Vehicles tab and tap the "+" button. Fill in your vehicle details including make, model, year, and license plate. You can also add a photo of your vehicle.',
    },
    {
      'question': 'Can I cancel a booking?',
      'answer':
          'Yes, you can cancel a booking before it starts. Go to Bookings, select the booking you want to cancel, and tap "Cancel Booking". Please note cancellation policies may apply.',
    },
    {
      'question': 'How do I update my profile information?',
      'answer':
          'Go to Profile tab and tap "Edit Profile". You can update your name, phone number, date of birth, and profile picture.',
    },
    {
      'question': 'How do I enquire about spare parts?',
      'answer':
          'Go to Spare Parts from the Profile menu. Browse or search for parts, then tap "Enquire Now" on any part you\'re interested in. Fill in the quantity and any notes, then submit your enquiry.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) {
      return _allFaqs;
    }
    final query = _searchQuery.toLowerCase();
    return _allFaqs.where((faq) {
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search for answers or browse FAQs below',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search FAQs...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          '${_filteredFaqs.length} results',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_filteredFaqs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results found for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords or contact us directly',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredFaqs
                        .map((faq) => _buildFaqItem(
                              faq['question']!,
                              faq['answer']!,
                            ))
                        ,
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
