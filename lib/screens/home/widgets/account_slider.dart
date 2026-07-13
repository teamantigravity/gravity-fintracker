import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';

class AccountsSlider extends StatefulWidget{
  final List<Account> accounts;
  const AccountsSlider({super.key, required this.accounts});
  @override
  State<StatefulWidget> createState()=>_AccountSlider();
}

class _AccountSlider extends State<AccountsSlider>{
  final PageController _pageController = PageController();
  int _selected = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 180,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.accounts.length,
            controller: _pageController,
            onPageChanged: (int index){
              setState(() {
                _selected = index;
              });
            },
            itemBuilder : (BuildContext builder, int index) {
              Account account = widget.accounts[index];
              return FractionallySizedBox(
                widthFactor: 1 / _pageController.viewportFraction,
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            account.color.withOpacity(0.85),
                            account.color.withOpacity(0.45),
                          ]
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: account.color.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -40,
                            top: -40,
                            child: CircleAvatar(
                              radius: 90,
                              backgroundColor: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -60,
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CurrencyText(account.balance ?? 0, style: Theme.of(context).textTheme.headlineSmall?.merge(
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700
                                  ),
                                )),
                                Text("Balance", style: Theme.of(context).textTheme.bodyMedium?.apply(color: Colors.white.withOpacity(0.85)),),
                                const Expanded(child: SizedBox()),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(account.holderName, style: Theme.of(context).textTheme.bodyLarge?.apply(color: Colors.white.withOpacity(1), fontWeightDelta: 2),),
                                        Text(account.name, style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center,),
                                      ],
                                    ),
                                    const Expanded(child:SizedBox()),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(account.icon, color: Colors.white, size: 22),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                ),
              );
            },
          ),
        ),
        if(widget.accounts.length > 1) const SizedBox(height: 10,),
        if(widget.accounts.length > 1) SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.accounts.length, (index) {
              return AnimatedContainer(
                curve: Curves.ease,
                height: 6,
                duration: const Duration(milliseconds: 200),
                width: _selected == index? 20: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(_selected == index? 1:0.5),
                    borderRadius: BorderRadius.circular(60)
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}

