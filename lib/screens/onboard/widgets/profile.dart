import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/helpers/color.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileWidget extends StatefulWidget {
  final VoidCallback onGetStarted;
  const ProfileWidget({super.key, required this.onGetStarted});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AppCubit>();
    _controller = TextEditingController(text: cubit.state.username);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppCubit cubit = context.read<AppCubit>();
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.account_balance_wallet, size: 70,),
              const SizedBox(height: 25,),
              Text("Hi! welcome to ${AppConstants.appName}", style: theme.textTheme.headlineMedium!.apply(color: theme.colorScheme.primary, fontWeightDelta: 1),),
              const SizedBox(height: 15,),
              Text("What should we call you?", style: theme.textTheme.bodyLarge!.apply(color: ColorHelper.darken(theme.textTheme.bodyLarge!.color ?? theme.colorScheme.onSurface), fontWeightDelta: 1),),
              const SizedBox(height: 25,),
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  prefixIcon: const Icon(Icons.account_circle),
                  hintText: "Enter your name",
                  label: const Text("Name")
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if(_controller.text.isEmpty){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name")));
          } else {
            await cubit.updateUsername(_controller.text);
            if (mounted) widget.onGetStarted();
          }
        },
        label: const Row(
          children: <Widget>[Text("Next"), SizedBox(width: 10,), Icon(Icons.arrow_forward)],
        ),
      ),
    );
  }
}