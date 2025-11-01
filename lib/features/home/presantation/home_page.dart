import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/app/shared/widgets/_dailyChallangeCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        backgroundColor: DT.bg,
        elevation: 0,
        toolbarHeight: 100,
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: DT.gbWhite, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DT.shadowMedium,
                    blurRadius: 10,
                    offset: const Offset(0,2)
                  ),
                ]
                
              ),
              child: ClipOval(
                child: Image.network(
                  'src',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: DT.iconLightGrey.withOpacity(0.3),
                    child: const Icon(Icons.person, color: DT.iconLightGrey)
                  )
                )
              )
            ),
            const SizedBox(width: DT.s4,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Helo, szia vagyok',
                  style: TextStyle(
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w600,
                    color: DT.textPrimary
                  ),
                  ),
                  const SizedBox(height: DT.s1,),
                  Text(
                    'Mai nap: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: DT.s4,
                      color: DT.textSecondary
                    ),
                  ),
                ],
              )
              ),
            Container(
              width: 40,
              height: 40,
              decoration:  BoxDecoration(
                color: DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [
                  BoxShadow(
                    color: DT.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0,2)
                  ),
                ],
              ),
              child: const Icon(
                Icons.search, 
                color: DT.iconLightGrey
              ),
            ),
          ],
        )
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
        //Daily challenge card
        _dailyChallangeCard(),
        //weekly list component
        //_weeklyListComponent(),
        //your plan section
          ],
        ),
      )
    );
  }
}


class _dailyChallangeCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DT.challangeCardGradientStart, DT.challangeCardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DT.rCard),
          boxShadow: [
            BoxShadow(
              color: DT.shadowLight,
              blurRadius: 20,
              offset: const Offset(0,4)
            )
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Napi kihívás',
                  style: TextStyle(
                    fontSize: DT.s5,
                    fontWeight: FontWeight.w700,
                    color: DT.textPrimary
                  ),
                ),
                const SizedBox(height: DT.s2,),
                const Text('Csinálj meg mindent 9:00 előtt',
                  style: TextStyle(
                    fontSize: DT.s4,
                    color: DT.textSecondary
                  ),
                ),
              ],
            )
          ),
        ],
      )
    );
  }
}