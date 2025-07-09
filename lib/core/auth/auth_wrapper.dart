import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../widgets/connectivity_status_widget.dart';
import '../../injection_container.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
      child: ConnectivityStatusWidget(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (state is AuthAuthenticated) {
              return const MainPage();
            }
            
            // Default to auth page for unauthenticated and error states
            // App can still work offline for local features
            return const AuthPage();
          },
        ),
      ),
    );
  }
}
