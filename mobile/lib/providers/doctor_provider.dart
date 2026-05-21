import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor.dart';
import '../core/network/api_client.dart';

class DoctorState {
  final List<DoctorModel> doctors;
  final DoctorModel? selectedDoctor;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedSpecialty;
  final List<String> specialties;

  const DoctorState({
    this.doctors = const [],
    this.selectedDoctor,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedSpecialty = '',
    this.specialties = const [],
  });

  DoctorState copyWith({
    List<DoctorModel>? doctors,
    DoctorModel? selectedDoctor,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedSpecialty,
    List<String>? specialties,
  }) {
    return DoctorState(
      doctors: doctors ?? this.doctors,
      selectedDoctor: selectedDoctor ?? this.selectedDoctor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      specialties: specialties ?? this.specialties,
    );
  }
}

class DoctorNotifier extends StateNotifier<DoctorState> {
  final ApiClient _apiClient;

  DoctorNotifier(this._apiClient) : super(const DoctorState());

  Future<void> fetchDoctors({String? specialty}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(
        '/doctors',
        query: specialty != null && specialty.isNotEmpty ? {'specialty': specialty} : null,
      );
      final List<dynamic> data = response.data['doctors'] ?? response.data;
      state = state.copyWith(
        doctors: data.map((e) => DoctorModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load doctors');
    }
  }

  Future<void> fetchDoctorById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/doctors/$id');
      final doctor = DoctorModel.fromJson(response.data);
      state = state.copyWith(selectedDoctor: doctor, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load doctor profile');
    }
  }

  Future<void> searchDoctors(String query) async {
    state = state.copyWith(isLoading: true, searchQuery: query, error: null);
    try {
      final response = await _apiClient.get(
        '/doctors/search',
        query: {'q': query, 'specialty': state.selectedSpecialty},
      );
      final List<dynamic> data = response.data['doctors'] ?? response.data;
      state = state.copyWith(
        doctors: data.map((e) => DoctorModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Search failed');
    }
  }

  Future<void> fetchSpecialties() async {
    try {
      final response = await _apiClient.get('/doctors/specialties');
      final List<dynamic> data = response.data['specialties'] ?? response.data;
      state = state.copyWith(
        specialties: data.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  void setSpecialty(String specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
    fetchDoctors(specialty: specialty.isEmpty ? null : specialty);
  }

  void clearSelection() {
    state = state.copyWith(selectedDoctor: null);
  }
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoctorNotifier(apiClient);
});
