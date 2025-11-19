import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart' as RV;


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
              margin: const EdgeInsets.only(right: DT.s2),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: DT.bg, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DT.shadowMedium,
                    blurRadius: 10,
                    offset: const Offset(0,2)
                  ),
                ]
                
              ),
              child: GestureDetector(
                onTap: ()=>{context.go('/profile')},
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
              )
            ),
            const SizedBox(height: DT.s4,),
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
                  const SizedBox(width: DT.s2,),
                  Text(
                    'Mai nap: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: DT.s3,
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
            const SizedBox(height: DT.s4,),
            
            const SizedBox(height: 100,),
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
          }),),
          const SizedBox(width: DT.s4,),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: _PlanCard(
                    color: DT.cardBlue,
                    difficulty: 'Közepes',
                    title: 'Full Body Workout',
                    date: '2025.11.15',
                    time: '10:00 - 11:00',
                    room: 'Terem A',
                    trainer: 'Bajnok',
                    trainerImageURL: 'https://scontent.fbud4-1.fna.fbcdn.net/v/t39.30808-6/362927839_1006694723692724_8650338579843640853_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=LQawp4fwan8Q7kNvwGBCdf_&_nc_oc=AdkX2k_-Flb8Iwtulqj4xbejIEpupjXYmqdltJQN8JD25dPbh3No9IpEhvoY2Xyurnc&_nc_zt=23&_nc_ht=scontent.fbud4-1.fna&_nc_gid=78rE59wKzei5cRqi2XhazA&oh=00_Afgd6dVnaJ9oTi3WhMdXnSFlWjiWhE6msEYy5g8PHT22Dg&oe=690ED035',
                    isLeft: true,
                    onTap: ()=>context.go('/sessionDetail'),
                  ),
                ),
                const SizedBox(width: DT.s4,),
                Expanded(
                  child: _PlanCard(
                    color: DT.cardTeal,
                    difficulty: 'Könnyű',
                    title: 'Full Body Workout',
                    date: '2025.11.16',
                    time: '10:00 - 11:00',
                    room: 'Terem A',
                    trainer: 'Bajnok',
                    trainerImageURL: 'https://scontent.fbud4-1.fna.fbcdn.net/v/t39.30808-6/362927839_1006694723692724_8650338579843640853_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=LQawp4fwan8Q7kNvwGBCdf_&_nc_oc=AdkX2k_-Flb8Iwtulqj4xbejIEpupjXYmqdltJQN8JD25dPbh3No9IpEhvoY2Xyurnc&_nc_zt=23&_nc_ht=scontent.fbud4-1.fna&_nc_gid=78rE59wKzei5cRqi2XhazA&oh=00_Afgd6dVnaJ9oTi3WhMdXnSFlWjiWhE6msEYy5g8PHT22Dg&oe=690ED035',
                    isLeft: false,
                    onTap: ()=>context.go('/sessionDetail'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DT.s4,),
          _socialMediaCard(),
          const SizedBox(width: DT.s4,),
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
      margin: const EdgeInsets.only(bottom: DT.s6),
      decoration: BoxDecoration(
        color: DT.gbWhite,
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
        padding: EdgeInsets.all(DT.s2),
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
                    blurRadius: 8,
                    offset: const Offset(0,2)
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), 
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: isSelected ? DT.gbWhite : DT.textPrimary,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date), 
                    style: TextStyle(
                      fontSize: DT.s4,
                      color: isSelected ? DT.gbWhite : DT.textPrimary,
                      fontWeight: FontWeight.w500
                    ),
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

class _PlanCard extends StatelessWidget {
  final Color color;
  final String difficulty;
  final String title;
  final String date;
  final String time;
  final String room;
  final String trainer;
  final String trainerImageURL;
  final bool isLeft;
  final VoidCallback onTap;

  const _PlanCard({super.key, required this.color, required this.difficulty, required this.title, required this.date, required this.time, required this.room, required this.trainer, required this.trainerImageURL, this.isLeft = true, required this.onTap});  

  


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DT.s4),
        margin: EdgeInsets.only( top: DT.s4),
        decoration: BoxDecoration(
          color: color,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DT.s3, vertical: DT.s1),
              decoration: BoxDecoration(
                color: DT.gbWhite.withOpacity(0.5),
                borderRadius: BorderRadius.circular(DT.s2)
              ),
              child: Text(
                difficulty,
                style: const TextStyle(
                  fontSize: DT.s3,
                  fontWeight: FontWeight.w500,
                  color: DT.textPrimary
                ),
              ),
            ),
            const SizedBox(height: DT.s3,),
            Text(
              date,
              style: const TextStyle(
                fontSize: DT.s3,
                color: DT.textSecondary
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: DT.s3,
                color: DT.textSecondary
              ),
            ),
            Text(
              room,
              style: const TextStyle(
                fontSize: DT.s3,
                color: DT.textSecondary
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if(isLeft)...[
                  CircleAvatar(
                    radius: DT.s3,
                    backgroundImage: NetworkImage(trainerImageURL),
                  ),
                  const SizedBox(width: DT.s2,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edző:',
                        style: TextStyle(
                          fontSize: DT.s2,
                          color: DT.textSecondary
                        ),
                      ),
                      Text(
                        trainer,
                        style: const TextStyle(
                          fontSize: DT.s3,
                          color: DT.textPrimary
                        ),
                      ),
                    ],
                  )
                ]
                else ... [
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DT.iconLightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(DT.s2),
                    ),
                    child: const Icon(
                      Icons.extension, 
                      color: DT.iconLightGrey,
                      size: DT.s5,
                    ),
                  )
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _socialMediaCard extends StatelessWidget {
  const _socialMediaCard({super.key});
  

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: DT.s3),
      padding: EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.bg,
        borderRadius: BorderRadius.circular(DT.s4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _socialIcon(icon: Icons.camera_alt, color: DT.socialPink,),
          _socialIcon(icon: Icons.play_circle_outline, color: DT.socialRed,),
          _socialIcon(icon: Icons.chat_bubble_outline, color: DT.socialBlue,),
        ],
      ),
    );
  }
}

class _socialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _socialIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: DT.gbWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: DT.shadowLight,
            blurRadius: 10,
            offset: const Offset(0,2)
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: DT.s5,)
    );
  }
}


