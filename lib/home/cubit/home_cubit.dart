import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_text_improver_app/data/repositories/repositories.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String resultText;
  final String errorText;
  final String apiKey;

  const HomeState({
    this.status = HomeStatus.initial,
    this.resultText = '',
    this.errorText = '',
    this.apiKey = '',
  });

  HomeState copyWith({
    HomeStatus? status,
    String? resultText,
    String? errorText,
    String? apiKey,
  }) {
    return HomeState(
      status: status ?? this.status,
      resultText: resultText ?? this.resultText,
      errorText: errorText ?? this.errorText,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  List<Object> get props => [
        status,
        resultText,
        errorText,
        apiKey,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  late final StreamSubscription<Setting> _settingsSubscription;
  late final StreamSubscription<String> _gptSubscription;
  final SettingsRepository _settingsRepository;
  final GPTRepository _gptRepository;

  @override
  Future<void> close() {
    _gptSubscription.cancel();
    _settingsSubscription.cancel();
    return super.close();
  }

  HomeCubit({
    required SettingsRepository settingsRepository,
  })  : _settingsRepository = settingsRepository,
        _gptRepository = GPTRepository(),
        super(const HomeState()) {
    _init();
  }

  Future<void> _init() async {
    emit(state.copyWith(status: HomeStatus.success));
    _subscribe();
  }

  void _subscribe() {
    _settingsSubscription = _settingsRepository.settingsStream.listen((setting) {
      switch (setting.name) {
        case SettingName.apiKey:
          emit(state.copyWith(apiKey: setting.stringValue));
          break;
        default:
          throw Exception('Unknown setting name: ${setting.name}');
      }
    });

    _gptSubscription = _gptRepository.gptResponseStream.listen((response) {
      emit(
        state.copyWith(
          status: HomeStatus.success,
          resultText: response,
          errorText: '',
        ),
      );
    });
  }

  Future<void> improve({
    required String userMessage,
    required double formalValue,
    required double assertiveValue,
    required double expandValue,
  }) async {
    emit(state.copyWith(status: HomeStatus.loading));

    List<String> tones = [];

    const double lowerThreshold = 0.3;
    const double upperThreshold = 0.7;

    if (formalValue < lowerThreshold) {
      tones.add('casual');
    } else if (formalValue > upperThreshold) {
      tones.add('formal');
    }

    if (assertiveValue < lowerThreshold) {
      tones.add('friendly');
    } else if (assertiveValue > upperThreshold) {
      tones.add('assertive');
    }

    AnswerLength answerLength = AnswerLength.same;

    if (expandValue < lowerThreshold) {
      answerLength = AnswerLength.shorten;
    } else if (expandValue > upperThreshold) {
      answerLength = AnswerLength.expand;
    }

    try {
      await _gptRepository.sendRequest(
        apiKey: state.apiKey,
        userMessage: userMessage,
        answerLength: answerLength,
        tones: tones,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.success,
          resultText: '',
          errorText: 'Failed to improve. Error:\n$e',
        ),
      );
    }
  }

  void reset() {
    emit(state.copyWith(
      status: HomeStatus.success,
      resultText: '',
      errorText: '',
    ));
  }

  void setApiKey(String apiKey) => _settingsRepository.setApiKey(apiKey);
}
