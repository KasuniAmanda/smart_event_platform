import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import '../providers/event_provider.dart';
import '../../domain/entities/event.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;
  bool _isFeatured = false; 

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute
          );
        });
      }
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;

    final newEvent = Event(
      id: '', 
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDateTime,
      location: _locationController.text.trim(),
      totalSeats: int.parse(_seatsController.text),
      availableSeats: int.parse(_seatsController.text),
      organizerId: user?.uid ?? 'unknown',
      isFeatured: _isFeatured, 
    );

    try {
      await ref.read(eventServiceProvider).createEvent(newEvent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Event published successfully! 🚀"), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Publish New Event", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Closes keyboard on tap outside
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildHeader("Event Details"),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _titleController,
                    label: "Event Title",
                    icon: Icons.title_rounded,
                    hint: "Enter event name",
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _locationController,
                    label: "Location",
                    icon: Icons.location_on_rounded,
                    hint: "Venue or City",
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _seatsController,
                    label: "Total Capacity",
                    icon: Icons.groups_rounded,
                    isNumber: true,
                    hint: "Number of available seats",
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _descriptionController,
                    label: "Description",
                    icon: Icons.description_rounded,
                    maxLines: 4,
                    hint: "Tell attendees what to expect...",
                  ),
                  const SizedBox(height: 20),

                  // 🌟 Styled Featured Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.shade200, width: 1.5),
                    ),
                    child: CheckboxListTile(
                      title: const Text("Feature this event?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Promote to the top highlights section", style: TextStyle(fontSize: 11)),
                      value: _isFeatured,
                      activeColor: Colors.amber.shade800,
                      checkColor: Colors.white,
                      secondary: Icon(Icons.stars_rounded, color: Colors.amber.shade800, size: 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      onChanged: (val) => setState(() => _isFeatured = val!),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildHeader("Schedule"),
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 0,
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
                      ),
                      title: Text(
                        DateFormat('EEEE, MMM dd').format(_selectedDateTime),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        DateFormat('hh:mm a').format(_selectedDateTime),
                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _pickDateTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo,
                          elevation: 0,
                          side: const BorderSide(color: Colors.indigo),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("EDIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      shadowColor: Colors.indigo.withOpacity(0.4),
                    ),
                    onPressed: _saveEvent, 
                    child: const Text(
                      "PUBLISH EVENT",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0), // Aligns icon to top for multi-line
          child: Icon(icon, size: 22, color: Colors.indigo),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "This field is required";
        if (isNumber && (int.tryParse(val) ?? 0) <= 0) return "Enter a valid number";
        return null;
      },
    );
  }
}