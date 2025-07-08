/// Crisis Event Model
class CrisisEvent {
  final String id;
  final String userId;
  final String crisisLevel;
  final String triggerSource;
  final String detectedKeywords;
  final String? userMessage;
  final bool interventionProvided;
  final String? interventionType;
  final String? resourcesProvided;
  final bool professionalContactMade;
  final DateTime? interventionTimestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrisisEvent({
    required this.id,
    required this.userId,
    required this.crisisLevel,
    required this.triggerSource,
    required this.detectedKeywords,
    this.userMessage,
    required this.interventionProvided,
    this.interventionType,
    this.resourcesProvided,
    required this.professionalContactMade,
    this.interventionTimestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrisisEvent.fromJson(Map<String, dynamic> json) {
    return CrisisEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      crisisLevel: json['crisisLevel'] as String,
      triggerSource: json['triggerSource'] as String,
      detectedKeywords: json['detectedKeywords'] as String,
      userMessage: json['userMessage'] as String?,
      interventionProvided: json['interventionProvided'] as bool,
      interventionType: json['interventionType'] as String?,
      resourcesProvided: json['resourcesProvided'] as String?,
      professionalContactMade: json['professionalContactMade'] as bool,
      interventionTimestamp: json['interventionTimestamp'] != null
          ? DateTime.parse(json['interventionTimestamp'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'crisisLevel': crisisLevel,
      'triggerSource': triggerSource,
      'detectedKeywords': detectedKeywords,
      'userMessage': userMessage,
      'interventionProvided': interventionProvided,
      'interventionType': interventionType,
      'resourcesProvided': resourcesProvided,
      'professionalContactMade': professionalContactMade,
      'interventionTimestamp': interventionTimestamp?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Crisis Resources Model
class CrisisResources {
  final List<CrisisHotline> hotlines;
  final List<EmergencyContact> emergencyContacts;
  final List<MentalHealthResource> mentalHealthResources;
  final List<SelfCareGuide> selfCareGuides;

  const CrisisResources({
    required this.hotlines,
    required this.emergencyContacts,
    required this.mentalHealthResources,
    required this.selfCareGuides,
  });

  factory CrisisResources.fromJson(Map<String, dynamic> json) {
    return CrisisResources(
      hotlines: (json['hotlines'] as List<dynamic>)
          .map((e) => CrisisHotline.fromJson(e as Map<String, dynamic>))
          .toList(),
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      mentalHealthResources: (json['mentalHealthResources'] as List<dynamic>)
          .map((e) => MentalHealthResource.fromJson(e as Map<String, dynamic>))
          .toList(),
      selfCareGuides: (json['selfCareGuides'] as List<dynamic>)
          .map((e) => SelfCareGuide.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotlines': hotlines.map((e) => e.toJson()).toList(),
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'mentalHealthResources': mentalHealthResources.map((e) => e.toJson()).toList(),
      'selfCareGuides': selfCareGuides.map((e) => e.toJson()).toList(),
    };
  }
}

/// Crisis Hotline Model
class CrisisHotline {
  final String name;
  final String number;
  final String description;
  final String available;

  const CrisisHotline({
    required this.name,
    required this.number,
    required this.description,
    required this.available,
  });

  factory CrisisHotline.fromJson(Map<String, dynamic> json) {
    return CrisisHotline(
      name: json['name'] as String,
      number: json['number'] as String,
      description: json['description'] as String,
      available: json['available'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'description': description,
      'available': available,
    };
  }
}

/// Emergency Contact Model
class EmergencyContact {
  final String name;
  final String number;
  final String description;

  const EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      number: json['number'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'description': description,
    };
  }
}

/// Mental Health Resource Model
class MentalHealthResource {
  final String name;
  final String url;
  final String description;

  const MentalHealthResource({
    required this.name,
    required this.url,
    required this.description,
  });

  factory MentalHealthResource.fromJson(Map<String, dynamic> json) {
    return MentalHealthResource(
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'description': description,
    };
  }
}

/// Self Care Guide Model
class SelfCareGuide {
  final String title;
  final String description;
  final List<String> steps;

  const SelfCareGuide({
    required this.title,
    required this.description,
    required this.steps,
  });

  factory SelfCareGuide.fromJson(Map<String, dynamic> json) {
    return SelfCareGuide(
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'steps': steps,
    };
  }
}
