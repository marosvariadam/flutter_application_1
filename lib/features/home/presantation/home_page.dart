import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selected = DateTime.now();

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
        padding: const EdgeInsets.all(DT.s5),
        child: Column(
          children: [
        //Daily challenge card
        _dailyChallangeCard(),
        //weekly list component
        _weeklyListComponent(
          selectDate: _selected,
          onDateSelected: (date)=> setState(() {
            _selected = date;
          }),)
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
                const SizedBox(height: DT.s2,),
                Row(
                  children:[
                    _userChip(imageURL: 'src'),
                    Transform.translate(
                      offset: Offset(-DT.s2, 0),
                      child: _userChip(imageURL: 'https://www.pestsolutions.co.uk/wp-content/uploads/2025/05/Pest-ZoomFeral-Cats.jpg'),
                    ),
                    Transform.translate(
                      offset: Offset(-DT.s4, 0),
                      child: _userChip(imageURL: 'src'),
                    ),
                    Transform.translate(
                      offset: Offset(-DT.s6, 0),
                      child: _userChip(imageURL: 'src'),
                    ),
                  ]
                )
              ],
            )
          ),
        ],
      )
    );
  }
}

class _userChip extends StatelessWidget {

  final String imageURL;
  const _userChip({required this.imageURL});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DT.gbWhite, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          imageURL,
          fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: DT.iconLightGrey.withOpacity(0.3),
                    child: const Icon(Icons.person, size: DT.s4, color: DT.iconLightGrey)
                  )
        )
      )
    );
  }
}

class _weeklyListComponent extends StatelessWidget {
  final DateTime selectDate;
  final Function(DateTime) onDateSelected;
  const _weeklyListComponent({required this.selectDate, required this.onDateSelected});
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract( Duration(days: now.weekday - 1));

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = date.day == selectDate.day && date.month == selectDate.month && date.year == selectDate.year;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 50,
              margin: EdgeInsets.only(right: DT.s3),             
              decoration: BoxDecoration(
                color: isSelected ? DT.gbBlack : DT.gbWhite,
                borderRadius: BorderRadius.circular(DT.rCardSmall),
                boxShadow: [
                  BoxShadow(
                    color: DT.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0,2)
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), 
                    style: TextStyle(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
