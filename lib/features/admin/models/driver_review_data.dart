import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';

class DriverReviewData {
  const DriverReviewData({
    required this.user,
    required this.driverProfile,
    this.documents = const [],
  });

  factory DriverReviewData.fromJson(Map<String, dynamic> json) {
    return DriverReviewData(
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      driverProfile: DriverProfileModel.fromJson(
        json['driver_profile'] as Map<String, dynamic>? ?? {},
      ),
      documents: (json['documents'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DocumentModel.fromJson(e as Map<String, dynamic>? ?? {}),
              )
              .toList() ??
          [],
    );
  }

  final UserModel user;
  final DriverProfileModel driverProfile;
  final List<DocumentModel> documents;

  int get pendingDocumentCount => documents
      .where((d) => d.status == DocumentStatus.pending)
      .length;

  int get approvedDocumentCount => documents
      .where((d) => d.status == DocumentStatus.approved)
      .length;

  int get rejectedDocumentCount => documents
      .where((d) => d.status == DocumentStatus.rejected)
      .length;

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'driver_profile': driverProfile.toJson(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  DriverReviewData copyWith({
    UserModel? user,
    DriverProfileModel? driverProfile,
    List<DocumentModel>? documents,
  }) {
    return DriverReviewData(
      user: user ?? this.user,
      driverProfile: driverProfile ?? this.driverProfile,
      documents: documents ?? this.documents,
    );
  }
}
