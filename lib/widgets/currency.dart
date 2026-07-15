import 'package:currency_picker/currency_picker.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/helpers/currency.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrencyText extends StatelessWidget{
  final double? amount;
  final TextStyle? style;
  final TextOverflow? overflow;
  final CurrencyService currencyService = CurrencyService();

  CurrencyText(this.amount, {super.key , this.style, this. overflow});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state){
      final String currencyCode = state.currency ?? 'USD';
      Currency? currency = currencyService.findByCode(currencyCode);
      final bool privacy = state.privacyMode;
      final amountValue = amount;
      return Text(
        amountValue == null ? (currency?.symbol ?? '\$') : (privacy ? '•••' : CurrencyHelper.format(amountValue, symbol: currency?.symbol ?? '\$')),
        style: style,
        overflow: overflow,
      );
    });
  }
}

